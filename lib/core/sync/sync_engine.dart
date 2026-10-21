import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/db_helper.dart';
import '../../data/repositories/expense_repository.dart';
import 'sync_models.dart';

class SyncEngine extends ChangeNotifier {
  static final SyncEngine instance = SyncEngine._init();
  final ExpenseRepository _repository = ExpenseRepository();
  final DbHelper _dbHelper = DbHelper.instance;

  SyncEngine._init();

  static const int httpPort = 41531;
  static const int udpPort = 41530;

  HttpServer? _server;
  RawDatagramSocket? _udpSocket;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;

  String _deviceId = '';
  String _deviceName = '';
  String _platform = '';
  String? _localIp;

  bool _isServerRunning = false;
  bool _isScanning = false;
  bool _isSyncing = false;
  String _syncStatusMessage = '';

  final Map<String, DiscoveredDevice> _discoveredDevices = {};

  // Pending pairing requests when acting as server
  String? _currentPendingPin;
  String? _pendingClientDeviceId;
  String? _pendingClientDeviceName;
  Timer? _pinExpirationTimer;
  String? _authorizedSessionToken;

  // Callback to notify UI when a remote device wants to pair
  void Function(String clientName, String pin)? onIncomingPairingRequest;

  // Getters
  String get deviceId => _deviceId;
  String get deviceName => _deviceName;
  String get platform => _platform;
  String? get localIp => _localIp;
  bool get isServerRunning => _isServerRunning;
  bool get isScanning => _isScanning;
  bool get isSyncing => _isSyncing;
  String get syncStatusMessage => _syncStatusMessage;
  List<DiscoveredDevice> get discoveredDevices =>
      _discoveredDevices.values.toList()
        ..sort((a, b) => b.lastSeen.compareTo(a.lastSeen));

  String? get currentPendingPin => _currentPendingPin;
  String? get pendingClientDeviceName => _pendingClientDeviceName;

  Future<void> init() async {
    _platform = Platform.operatingSystem;
    _deviceId = await _dbHelper.getSetting('sync_device_id') ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = const Uuid().v4();
      await _dbHelper.setSetting('sync_device_id', _deviceId);
    }

    _deviceName = await _dbHelper.getSetting('sync_device_name') ?? '';
    if (_deviceName.isEmpty) {
      if (Platform.isWindows) {
        _deviceName = '${Platform.localHostname} (Laptop)';
      } else if (Platform.isAndroid) {
        _deviceName = 'Android Phone';
      } else if (Platform.isIOS) {
        _deviceName = 'iPhone';
      } else if (Platform.isMacOS) {
        _deviceName = '${Platform.localHostname} (Mac)';
      } else {
        _deviceName = '${Platform.localHostname} ($platform)';
      }
      await _dbHelper.setSetting('sync_device_name', _deviceName);
    }

    await _resolveLocalIp();
    await startServer();
    await startDiscovery();
  }

  Future<void> setDeviceName(String newName) async {
    _deviceName = newName.trim();
    await _dbHelper.setSetting('sync_device_name', _deviceName);
    notifyListeners();
  }

  Future<void> _resolveLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && !addr.address.startsWith('169.254')) {
            _localIp = addr.address;
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error finding local IP: $e');
    }
  }

  // --- LOCAL HTTP SERVER ---
  Future<void> startServer() async {
    if (_isServerRunning) return;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, httpPort);
      _isServerRunning = true;
      _server!.listen(_handleHttpRequest);
      notifyListeners();
      debugPrint('Sync HTTP server listening on port $httpPort');
    } catch (e) {
      debugPrint('Error starting Sync HTTP server: $e');
    }
  }

  void _handleHttpRequest(HttpRequest request) async {
    final response = request.response;
    response.headers.contentType = ContentType.json;
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.ok;
      await response.close();
      return;
    }

    final path = request.uri.path;

    try {
      if (request.method == 'GET' && path == '/ping') {
        response.write(jsonEncode({
          'status': 'ok',
          'deviceId': _deviceId,
          'deviceName': _deviceName,
          'platform': _platform,
          'version': '1.0.0',
        }));
      } else if (request.method == 'POST' && path == '/pair/request') {
        final bodyStr = await utf8.decodeStream(request);
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;

        final clientDeviceId = body['clientDeviceId'] as String? ?? '';
        final clientDeviceName = body['clientDeviceName'] as String? ?? 'Device';

        // Generate 6-digit pairing code
        final rng = Random();
        final pin = (100000 + rng.nextInt(900000)).toString();

        _currentPendingPin = pin;
        _pendingClientDeviceId = clientDeviceId;
        _pendingClientDeviceName = clientDeviceName;

        _pinExpirationTimer?.cancel();
        _pinExpirationTimer = Timer(const Duration(minutes: 3), () {
          _currentPendingPin = null;
          _pendingClientDeviceId = null;
          _pendingClientDeviceName = null;
          notifyListeners();
        });

        notifyListeners();

        if (onIncomingPairingRequest != null) {
          onIncomingPairingRequest!(clientDeviceName, pin);
        }

        response.statusCode = HttpStatus.ok;
        response.write(jsonEncode({
          'status': 'pin_generated',
          'message': 'Enter the 6-digit key displayed on the host device.',
        }));
      } else if (request.method == 'POST' && path == '/pair/verify') {
        final bodyStr = await utf8.decodeStream(request);
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;

        final enteredPin = body['pin']?.toString().replaceAll(' ', '') ?? '';
        final clientDeviceId = body['clientDeviceId'] as String? ?? '';

        if (_currentPendingPin != null &&
            enteredPin == _currentPendingPin &&
            clientDeviceId == _pendingClientDeviceId) {
          _authorizedSessionToken = const Uuid().v4();
          _currentPendingPin = null;
          _pinExpirationTimer?.cancel();
          notifyListeners();

          response.statusCode = HttpStatus.ok;
          response.write(jsonEncode({
            'status': 'authorized',
            'sessionToken': _authorizedSessionToken,
          }));
        } else {
          response.statusCode = HttpStatus.unauthorized;
          response.write(jsonEncode({
            'status': 'error',
            'message': 'Invalid or expired verification key.',
          }));
        }
      } else if (request.method == 'POST' && path == '/sync/exchange') {
        final token = request.headers.value('X-Sync-Token');
        if (token == null || token != _authorizedSessionToken) {
          response.statusCode = HttpStatus.unauthorized;
          response.write(jsonEncode({'error': 'Unauthorized session'}));
          await response.close();
          return;
        }

        final bodyStr = await utf8.decodeStream(request);
        final clientPayload = SyncPayload.fromJson(bodyStr);

        // Merge incoming payload
        await _repository.applySyncPayload(
          clientPayload,
          peerDeviceName: clientPayload.deviceName,
          peerDeviceId: clientPayload.deviceId,
          direction: 'bidirectional',
        );

        // Export local payload to return to client
        final serverPayload = await _repository.exportSyncPayload(
          deviceId: _deviceId,
          deviceName: _deviceName,
          platform: _platform,
        );

        response.statusCode = HttpStatus.ok;
        response.write(serverPayload.toJson());

        // Invalidate single-use token after sync completion
        _authorizedSessionToken = null;
        notifyListeners();
      } else {
        response.statusCode = HttpStatus.notFound;
        response.write(jsonEncode({'error': 'Not found'}));
      }
    } catch (e) {
      debugPrint('Sync HTTP server error: $e');
      response.statusCode = HttpStatus.internalServerError;
      response.write(jsonEncode({'error': e.toString()}));
    } finally {
      await response.close();
    }
  }

  void dismissIncomingPairing() {
    _currentPendingPin = null;
    _pendingClientDeviceId = null;
    _pendingClientDeviceName = null;
    _pinExpirationTimer?.cancel();
    notifyListeners();
  }

  // --- UDP DISCOVERY ---
  Future<void> startDiscovery() async {
    try {
      _udpSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        udpPort,
        reuseAddress: true,
        reusePort: false,
      );
      _udpSocket!.broadcastEnabled = true;
      _udpSocket!.listen(_handleUdpEvent);

      // Periodically broadcast discovery announcement
      _broadcastTimer?.cancel();
      _broadcastTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        broadcastPresence();
      });

      // Cleanup stale devices (> 15 seconds)
      _cleanupTimer?.cancel();
      _cleanupTimer = Timer.periodic(const Duration(seconds: 6), (_) {
        final now = DateTime.now();
        final toRemove = <String>[];
        for (final entry in _discoveredDevices.entries) {
          if (now.difference(entry.value.lastSeen).inSeconds > 15) {
            toRemove.add(entry.key);
          }
        }
        if (toRemove.isNotEmpty) {
          for (final key in toRemove) {
            _discoveredDevices.remove(key);
          }
          notifyListeners();
        }
      });

      _isScanning = true;
      broadcastPresence();
      notifyListeners();
    } catch (e) {
      debugPrint('UDP discovery socket error: $e');
    }
  }

  void broadcastPresence() {
    if (_udpSocket == null || _deviceId.isEmpty) return;
    try {
      final msg = jsonEncode({
        'type': 'at_ping',
        'id': _deviceId,
        'name': _deviceName,
        'platform': _platform,
        'port': httpPort,
      });
      final bytes = utf8.encode(msg);
      _udpSocket!.send(bytes, InternetAddress('255.255.255.255'), udpPort);
    } catch (_) {}
  }

  void _handleUdpEvent(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _udpSocket?.receive();
      if (datagram != null) {
        try {
          final text = utf8.decode(datagram.data);
          final map = jsonDecode(text) as Map<String, dynamic>;
          final id = map['id'] as String?;
          final name = map['name'] as String?;
          final plat = map['platform'] as String?;
          final port = map['port'] as int? ?? httpPort;

          if (id != null && id != _deviceId && name != null) {
            _discoveredDevices[id] = DiscoveredDevice(
              id: id,
              name: name,
              platform: plat ?? 'unknown',
              ip: datagram.address.address,
              port: port,
              lastSeen: DateTime.now(),
            );
            notifyListeners();
          }
        } catch (_) {}
      }
    }
  }

  // --- MANUAL CONNECT BY IP ---
  Future<DiscoveredDevice?> probeDevice(String ip, [int port = httpPort]) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 3);
    try {
      final req = await client.getUrl(Uri.parse('http://$ip:$port/ping'));
      final res = await req.close();
      if (res.statusCode == HttpStatus.ok) {
        final bodyStr = await utf8.decodeStream(res);
        final map = jsonDecode(bodyStr) as Map<String, dynamic>;
        final device = DiscoveredDevice(
          id: map['deviceId'] as String? ?? ip,
          name: map['deviceName'] as String? ?? 'Device ($ip)',
          platform: map['platform'] as String? ?? 'unknown',
          ip: ip,
          port: port,
          lastSeen: DateTime.now(),
        );
        _discoveredDevices[device.id] = device;
        notifyListeners();
        return device;
      }
    } catch (e) {
      debugPrint('Probe device error: $e');
    } finally {
      client.close();
    }
    return null;
  }

  // --- CLIENT PAIRING & SYNC FLOW ---
  Future<bool> requestPairing(DiscoveredDevice target) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.parse('http://${target.ip}:${target.port}/pair/request');
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'clientDeviceId': _deviceId,
        'clientDeviceName': _deviceName,
        'platform': _platform,
      }));
      final res = await req.close();
      return res.statusCode == HttpStatus.ok;
    } catch (e) {
      debugPrint('Pair request error: $e');
      return false;
    } finally {
      client.close();
    }
  }

  Future<String?> verifyPinAndGetToken(DiscoveredDevice target, String pin) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.parse('http://${target.ip}:${target.port}/pair/verify');
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'pin': pin.trim().replaceAll(' ', ''),
        'clientDeviceId': _deviceId,
      }));
      final res = await req.close();
      if (res.statusCode == HttpStatus.ok) {
        final bodyStr = await utf8.decodeStream(res);
        final map = jsonDecode(bodyStr) as Map<String, dynamic>;
        return map['sessionToken'] as String?;
      }
    } catch (e) {
      debugPrint('Verify PIN error: $e');
    } finally {
      client.close();
    }
    return null;
  }

  Future<SyncResult> executeSync({
    required DiscoveredDevice target,
    required String sessionToken,
  }) async {
    _isSyncing = true;
    _syncStatusMessage = 'Exporting local records...';
    notifyListeners();

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      // 1. Export local payload
      final localPayload = await _repository.exportSyncPayload(
        deviceId: _deviceId,
        deviceName: _deviceName,
        platform: _platform,
      );

      _syncStatusMessage = 'Sending data to ${target.name}...';
      notifyListeners();

      // 2. Send to peer & get peer's payload in response
      final uri = Uri.parse('http://${target.ip}:${target.port}/sync/exchange');
      final req = await client.postUrl(uri);
      req.headers.contentType = ContentType.json;
      req.headers.add('X-Sync-Token', sessionToken);
      req.write(localPayload.toJson());

      final res = await req.close();
      if (res.statusCode != HttpStatus.ok) {
        throw Exception('Server rejected sync: HTTP ${res.statusCode}');
      }

      _syncStatusMessage = 'Merging changes from ${target.name}...';
      notifyListeners();

      final resBodyStr = await utf8.decodeStream(res);
      final peerPayload = SyncPayload.fromJson(resBodyStr);

      // 3. Apply peer's payload
      final result = await _repository.applySyncPayload(
        peerPayload,
        peerDeviceName: target.name,
        peerDeviceId: target.id,
        direction: 'bidirectional',
      );

      _syncStatusMessage = 'Sync completed successfully!';
      _isSyncing = false;
      notifyListeners();
      return result;
    } catch (e) {
      _syncStatusMessage = 'Sync failed: $e';
      _isSyncing = false;
      notifyListeners();

      await _repository.insertSyncHistory(SyncHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        peerDeviceName: target.name,
        peerDeviceId: target.id,
        direction: 'bidirectional',
        accountsSynced: 0,
        categoriesSynced: 0,
        transactionsSynced: 0,
        schedulesSynced: 0,
        deletedItemsSynced: 0,
        status: 'failed',
        summary: 'Error: $e',
      ));

      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
      );
    } finally {
      client.close();
    }
  }

  void stop() {
    _broadcastTimer?.cancel();
    _cleanupTimer?.cancel();
    _pinExpirationTimer?.cancel();
    _udpSocket?.close();
    _server?.close();
    _isServerRunning = false;
    _isScanning = false;
  }
}
