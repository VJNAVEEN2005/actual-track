import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/sync/sync_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/expense_repository.dart';
import '../../providers/app_provider.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final ExpenseRepository _repository = ExpenseRepository();
  List<SyncHistoryEntry> _history = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await _repository.getSyncHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncEngine = context.watch<SyncEngine>();
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16,
          vertical: isDesktop ? 20 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, syncEngine, isDesktop),
            const SizedBox(height: 18),

            // Incoming Pairing Request Card (Shown when another device wants to pair with this one)
            if (syncEngine.currentPendingPin != null) ...[
              _buildIncomingPairingCard(context, syncEngine),
              const SizedBox(height: 20),
            ],

            // Current Device Status Card
            _buildThisDeviceCard(context, syncEngine, isDesktop),
            const SizedBox(height: 20),

            // Discovered Devices Section
            _buildDiscoveredDevicesSection(context, syncEngine),
            const SizedBox(height: 24),

            // Sync History Section
            _buildHistorySection(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SyncEngine syncEngine, bool isDesktop) {
    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wi-Fi Sync', style: AppTypography.heading2.copyWith(fontSize: 20)),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: syncEngine.isServerRunning
                          ? AppColors.emeraldLight
                          : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: syncEngine.isServerRunning
                            ? AppColors.emerald.withValues(alpha: 0.3)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: syncEngine.isServerRunning
                                ? AppColors.emerald
                                : AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          syncEngine.isServerRunning ? 'Listening' : 'Offline',
                          style: TextStyle(
                            color: syncEngine.isServerRunning
                                ? AppColors.emerald
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Scan',
                    onPressed: () {
                      syncEngine.broadcastPresence();
                    },
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.emerald),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Sync laptop & phone peer-to-peer on LAN',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Local Wi-Fi Sync', style: AppTypography.heading1),
            const SizedBox(height: 4),
            Text(
              'Secure peer-to-peer sync between laptop & phone on your local network',
              style: AppTypography.subtitle,
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: syncEngine.isServerRunning
                    ? AppColors.emeraldLight
                    : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: syncEngine.isServerRunning
                      ? AppColors.emerald.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: syncEngine.isServerRunning
                          ? AppColors.emerald
                          : AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    syncEngine.isServerRunning ? 'Listening on Wi-Fi' : 'Offline',
                    style: AppTypography.caption.copyWith(
                      color: syncEngine.isServerRunning
                          ? AppColors.emerald
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Refresh / Scan',
              onPressed: () {
                syncEngine.broadcastPresence();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Broadcasting discovery ping across Wi-Fi...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: const Icon(Icons.refresh_rounded, color: AppColors.emerald),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIncomingPairingCard(BuildContext context, SyncEngine syncEngine) {
    final pin = syncEngine.currentPendingPin ?? '';
    final formattedPin = pin.length == 6
        ? '${pin.substring(0, 3)}  ${pin.substring(3)}'
        : pin;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.amberLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.vpn_key_rounded, color: AppColors.amber, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Incoming Pairing Request', style: AppTypography.heading2.copyWith(fontSize: 17)),
                    const SizedBox(height: 2),
                    Text(
                      '"${syncEngine.pendingClientDeviceName ?? 'A mobile device'}" wants to sync with this device.',
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                onPressed: () => syncEngine.dismissIncomingPairing(),
                icon: const Icon(Icons.close, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                Text(
                  'Enter this 6-digit key on your other device:',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.emerald, width: 2),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Text(
                    formattedPin,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: AppColors.emerald,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Valid for 3 minutes • Sync starts automatically once entered',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThisDeviceCard(BuildContext context, SyncEngine syncEngine, bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 20 : 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 12 : 10),
            decoration: BoxDecoration(
              color: AppColors.emeraldLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              syncEngine.platform == 'android' || syncEngine.platform == 'ios'
                  ? Icons.phone_android_rounded
                  : Icons.laptop_mac_rounded,
              color: AppColors.emerald,
              size: isDesktop ? 26 : 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        syncEngine.deviceName,
                        style: AppTypography.heading3.copyWith(fontSize: isDesktop ? 16 : 14.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => _showEditDeviceNameDialog(context, syncEngine),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(Icons.edit_outlined, size: 15, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isDesktop
                      ? 'IP: ${syncEngine.localIp ?? 'Determining...'} • Port: ${SyncEngine.httpPort} • ${syncEngine.platform.toUpperCase()}'
                      : '${syncEngine.localIp ?? 'Determining...'} • Port: ${SyncEngine.httpPort}',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isDesktop)
            ElevatedButton.icon(
              onPressed: () => _showManualConnectDialog(context, syncEngine),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceSecondary,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.link_rounded, size: 16),
              label: const Text('Connect by IP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            )
          else
            IconButton(
              tooltip: 'Connect by IP',
              onPressed: () => _showManualConnectDialog(context, syncEngine),
              icon: const Icon(Icons.link_rounded, color: AppColors.emerald, size: 22),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiscoveredDevicesSection(BuildContext context, SyncEngine syncEngine) {
    final devices = syncEngine.discoveredDevices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Discovered Devices',
                      style: AppTypography.heading3.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${devices.length}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                syncEngine.broadcastPresence();
              },
              icon: const Icon(Icons.radar_rounded, size: 16, color: AppColors.emerald),
              label: Text(
                'Scan Again',
                style: AppTypography.caption.copyWith(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (devices.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.wifi_tethering_rounded, size: 40, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text('Looking for Devices on Same Wi-Fi', style: AppTypography.heading3.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  'Make sure your laptop and phone are connected to the same Wi-Fi network and have Actual Track open.',
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _showManualConnectDialog(context, syncEngine),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.emerald,
                    side: const BorderSide(color: AppColors.emerald),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Device by IP Manually'),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final device = devices[index];
              return _buildDeviceTile(context, syncEngine, device);
            },
          ),
      ],
    );
  }

  Widget _buildDeviceTile(BuildContext context, SyncEngine syncEngine, DiscoveredDevice device) {
    final isMobile = device.platform == 'android' || device.platform == 'ios';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMobile ? AppColors.cobaltLight : AppColors.violetLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isMobile ? Icons.phone_android_rounded : Icons.laptop_mac_rounded,
              color: isMobile ? AppColors.cobalt : AppColors.violet,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: AppTypography.heading3.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  '${device.ip}:${device.port} • ${device.platform.toUpperCase()}',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: syncEngine.isSyncing ? null : () => _startPairingFlow(context, syncEngine, device),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: const Text('Sync Now', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sync History', style: AppTypography.heading3),
            if (_history.isNotEmpty)
              TextButton(
                onPressed: _confirmClearHistory,
                child: Text(
                  'Clear History',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.coral,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingHistory)
          const Center(child: CircularProgressIndicator())
        else if (_history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.history_rounded, size: 36, color: AppColors.textMuted),
                const SizedBox(height: 8),
                Text('No sync history yet', style: AppTypography.heading3.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text('Completed sync sessions between your devices will be recorded here.', style: AppTypography.caption, textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _history[index];
              final isSuccess = item.status == 'success';
              final timeStr = DateFormat('MMM d, y • h:mm a').format(item.timestamp);

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSuccess ? AppColors.emeraldLight : AppColors.coralLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                        color: isSuccess ? AppColors.emerald : AppColors.coral,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.peerDeviceName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              Text(timeStr, style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(item.summary, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- ACTIONS ---
  Future<void> _startPairingFlow(
    BuildContext context,
    SyncEngine syncEngine,
    DiscoveredDevice target,
  ) async {
    // 1. Send pairing request to target
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Requesting pairing with ${target.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );

    final requested = await syncEngine.requestPairing(target);
    if (!requested) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not connect to ${target.name}. Please check Wi-Fi.')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    // 2. Open PIN entry dialog on this device
    _showPinEntryDialog(context, syncEngine, target);
  }

  void _showPinEntryDialog(
    BuildContext context,
    SyncEngine syncEngine,
    DiscoveredDevice target,
  ) {
    final pinController = TextEditingController();
    bool isVerifying = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.security_rounded, color: AppColors.emerald, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Enter Pairing Key', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Shown on ${target.name}', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Look at ${target.name} for the 6-digit key and enter it below:',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6,
                    color: AppColors.emerald,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '123456',
                    hintStyle: TextStyle(
                      fontFamily: 'monospace',
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.emerald, width: 2),
                    ),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: AppColors.coral, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
                if (isVerifying) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(syncEngine.syncStatusMessage, style: AppTypography.caption),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isVerifying
                    ? null
                    : () async {
                        final pin = pinController.text.trim();
                        if (pin.length != 6) {
                          setDialogState(() {
                            errorMessage = 'Please enter all 6 digits.';
                          });
                          return;
                        }

                        setDialogState(() {
                          isVerifying = true;
                          errorMessage = null;
                        });

                        final appProvider = context.read<AppProvider>();
                        final messenger = ScaffoldMessenger.of(context);

                        final sessionToken = await syncEngine.verifyPinAndGetToken(target, pin);
                        if (sessionToken == null) {
                          setDialogState(() {
                            isVerifying = false;
                            errorMessage = 'Invalid key. Please check the screen and try again.';
                          });
                          return;
                        }

                        // Execute two-way sync
                        final result = await syncEngine.executeSync(
                          target: target,
                          sessionToken: sessionToken,
                        );

                        await appProvider.refreshData();
                        await _loadHistory();

                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }

                        messenger.showSnackBar(
                          SnackBar(
                            backgroundColor: result.success ? AppColors.emerald : AppColors.coral,
                            content: Row(
                              children: [
                                Icon(
                                  result.success ? Icons.check_circle : Icons.error,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    result.success
                                        ? 'Sync Complete: ${result.totalChanges} changes reconciled with ${target.name}!'
                                        : result.message,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Verify & Sync'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showManualConnectDialog(BuildContext context, SyncEngine syncEngine) {
    final ipController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Connect by IP Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the local Wi-Fi IP address shown on your other device:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ipController,
              keyboardType: TextInputType.text,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. 192.168.1.15',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ip = ipController.text.trim();
              if (ip.isEmpty) return;

              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Probing $ip:${SyncEngine.httpPort}...')),
              );

              final device = await syncEngine.probeDevice(ip);
              if (device != null && context.mounted) {
                _startPairingFlow(context, syncEngine, device);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Device not reachable at that IP address.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showEditDeviceNameDialog(BuildContext context, SyncEngine syncEngine) {
    final nameController = TextEditingController(text: syncEngine.deviceName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Change Device Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. My Laptop',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await syncEngine.setDeviceName(name);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Sync History?'),
        content: const Text('This will remove all sync log entries from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _repository.clearSyncHistory();
              await _loadHistory();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
