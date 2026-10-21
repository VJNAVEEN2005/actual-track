import 'dart:convert';

class DiscoveredDevice {
  final String id;
  final String name;
  final String platform; // 'windows', 'android', 'ios', 'macos', 'linux'
  final String ip;
  final int port;
  final DateTime lastSeen;

  DiscoveredDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.ip,
    required this.port,
    required this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'platform': platform,
      'ip': ip,
      'port': port,
      'lastSeen': lastSeen.toIso8601String(),
    };
  }

  factory DiscoveredDevice.fromMap(Map<String, dynamic> map) {
    return DiscoveredDevice(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Device',
      platform: map['platform'] as String? ?? 'unknown',
      ip: map['ip'] as String? ?? '',
      port: map['port'] as int? ?? 41531,
      lastSeen: map['lastSeen'] != null 
          ? DateTime.tryParse(map['lastSeen']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }
}

class SyncTombstone {
  final String id;
  final String entityType; // 'account', 'category', 'transaction', 'schedule'
  final DateTime deletedAt;

  SyncTombstone({
    required this.id,
    required this.entityType,
    required this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityType': entityType,
      'deletedAt': deletedAt.toIso8601String(),
    };
  }

  factory SyncTombstone.fromMap(Map<String, dynamic> map) {
    return SyncTombstone(
      id: map['id'] as String,
      entityType: map['entityType'] as String,
      deletedAt: DateTime.parse(map['deletedAt'] as String),
    );
  }
}

class SyncHistoryEntry {
  final String id;
  final DateTime timestamp;
  final String peerDeviceName;
  final String peerDeviceId;
  final String direction; // 'incoming', 'outgoing', 'bidirectional'
  final int accountsSynced;
  final int categoriesSynced;
  final int transactionsSynced;
  final int schedulesSynced;
  final int deletedItemsSynced;
  final String status; // 'success', 'failed'
  final String summary;

  SyncHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.peerDeviceName,
    required this.peerDeviceId,
    required this.direction,
    required this.accountsSynced,
    required this.categoriesSynced,
    required this.transactionsSynced,
    required this.schedulesSynced,
    required this.deletedItemsSynced,
    required this.status,
    required this.summary,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'peerDeviceName': peerDeviceName,
      'peerDeviceId': peerDeviceId,
      'direction': direction,
      'accountsSynced': accountsSynced,
      'categoriesSynced': categoriesSynced,
      'transactionsSynced': transactionsSynced,
      'schedulesSynced': schedulesSynced,
      'deletedItemsSynced': deletedItemsSynced,
      'status': status,
      'summary': summary,
    };
  }

  factory SyncHistoryEntry.fromMap(Map<String, dynamic> map) {
    return SyncHistoryEntry(
      id: map['id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      peerDeviceName: map['peerDeviceName'] as String,
      peerDeviceId: map['peerDeviceId'] as String,
      direction: map['direction'] as String,
      accountsSynced: map['accountsSynced'] as int? ?? 0,
      categoriesSynced: map['categoriesSynced'] as int? ?? 0,
      transactionsSynced: map['transactionsSynced'] as int? ?? 0,
      schedulesSynced: map['schedulesSynced'] as int? ?? 0,
      deletedItemsSynced: map['deletedItemsSynced'] as int? ?? 0,
      status: map['status'] as String,
      summary: map['summary'] as String,
    );
  }
}

class SyncPayload {
  final String deviceId;
  final String deviceName;
  final String platform;
  final DateTime timestamp;
  final List<Map<String, dynamic>> accounts;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> schedules;
  final List<Map<String, dynamic>> tombstones;

  SyncPayload({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.timestamp,
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.schedules,
    required this.tombstones,
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
      'timestamp': timestamp.toIso8601String(),
      'accounts': accounts,
      'categories': categories,
      'transactions': transactions,
      'schedules': schedules,
      'tombstones': tombstones,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory SyncPayload.fromMap(Map<String, dynamic> map) {
    return SyncPayload(
      deviceId: map['deviceId'] as String? ?? '',
      deviceName: map['deviceName'] as String? ?? 'Device',
      platform: map['platform'] as String? ?? 'unknown',
      timestamp: map['timestamp'] != null 
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      accounts: List<Map<String, dynamic>>.from(map['accounts'] ?? []),
      categories: List<Map<String, dynamic>>.from(map['categories'] ?? []),
      transactions: List<Map<String, dynamic>>.from(map['transactions'] ?? []),
      schedules: List<Map<String, dynamic>>.from(map['schedules'] ?? []),
      tombstones: List<Map<String, dynamic>>.from(map['tombstones'] ?? []),
    );
  }

  factory SyncPayload.fromJson(String source) =>
      SyncPayload.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class SyncResult {
  final int accountsMerged;
  final int categoriesMerged;
  final int transactionsMerged;
  final int schedulesMerged;
  final int deletedItemsRemoved;
  final bool success;
  final String message;

  SyncResult({
    this.accountsMerged = 0,
    this.categoriesMerged = 0,
    this.transactionsMerged = 0,
    this.schedulesMerged = 0,
    this.deletedItemsRemoved = 0,
    required this.success,
    required this.message,
  });

  int get totalChanges =>
      accountsMerged +
      categoriesMerged +
      transactionsMerged +
      schedulesMerged +
      deletedItemsRemoved;
}
