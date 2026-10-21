import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/app_provider.dart';
import '../../providers/navigation_provider.dart';
import '../screens/accounts_screen.dart';
import '../screens/ai_advisor_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/envelopes_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/sync_screen.dart';
import '../screens/transactions_screen.dart';
import 'add_transaction_modal.dart';

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({super.key});

  static const List<Widget> _screens = [
    DashboardScreen(),     // 0
    EnvelopesScreen(),     // 1
    CalendarScreen(),      // 2
    AccountsScreen(),      // 3
    TransactionsScreen(),  // 4
    AnalyticsScreen(),     // 5
    AiAdvisorScreen(),     // 6
    SettingsScreen(),      // 7
    SyncScreen(),          // 8
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            _buildDesktopSidebar(context, nav),
            const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
            Expanded(
              child: _screens[nav.currentIndex],
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          titleSpacing: 12,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/app_icon.jpg',
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.emerald,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Actual Track',
                  style: AppTypography.heading3.copyWith(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Wi-Fi Sync',
              icon: Icon(
                nav.currentIndex == 8 ? Icons.sync_rounded : Icons.sync_rounded,
                color: nav.currentIndex == 8 ? AppColors.emerald : AppColors.textPrimary,
                size: 22,
              ),
              onPressed: () => nav.setIndex(8),
            ),
            IconButton(
              tooltip: 'Gemini AI Advisor',
              icon: Icon(
                nav.currentIndex == 6 ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                color: nav.currentIndex == 6 ? AppColors.emerald : AppColors.textPrimary,
                size: 22,
              ),
              onPressed: () => nav.setIndex(6),
            ),
            IconButton(
              tooltip: 'Settings',
              icon: Icon(
                nav.currentIndex == 7 ? Icons.settings : Icons.settings_outlined,
                color: nav.currentIndex == 7 ? AppColors.emerald : AppColors.textPrimary,
                size: 22,
              ),
              onPressed: () => nav.setIndex(7),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: _screens[nav.currentIndex],
        bottomNavigationBar: _buildMobileBottomBar(context, nav),
        floatingActionButton: FloatingActionButton(
          onPressed: () => AddTransactionModal.show(context),
          backgroundColor: AppColors.emerald,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    }
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final jsonStr = await context.read<AppProvider>().exportBackup();
      final docsDir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName = 'ActualTrack_Backup_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}.json';
      final file = File(p.join(docsDir.path, fileName));
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.emerald, size: 24),
                SizedBox(width: 10),
                Text('Backup Exported'),
              ],
            ),
            content: Text(
              'Your entire database has been safely backed up to:\n\n${file.path}\n\nYou can keep this file anywhere as a secure offline backup.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    }
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will remove all accounts, categories, and transactions so you can start completely fresh with zero data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<AppProvider>().clearAllData();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared. Starting fresh!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, NavigationProvider nav) {
    final isCollapsed = nav.isSidebarCollapsed;
    final width = isCollapsed ? 76.0 : 240.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emerald.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      'assets/app_icon.jpg',
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.emeraldLight,
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColors.emerald,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actual Track',
                          style: AppTypography.heading3.copyWith(fontSize: 16),
                        ),
                        Text(
                          'Zero-Based Ledger',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Nav Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sidebarItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  index: 0,
                  nav: nav,
                  isCollapsed: isCollapsed,
                ),
                _sidebarItem(
                  icon: Icons.all_inbox_outlined,
                  activeIcon: Icons.all_inbox_rounded,
                  label: 'Envelopes',
                  index: 1,
                  nav: nav,
                  isCollapsed: isCollapsed,
                ),
                _sidebarItem(
                  icon: Icons.calendar_month_outlined,
                  activeIcon: Icons.calendar_month_rounded,
                  label: 'Calendar',
                  index: 2,
                  nav: nav,
                  isCollapsed: isCollapsed,
                ),
                _sidebarItem(
                  icon: Icons.account_balance_outlined,
                  activeIcon: Icons.account_balance_rounded,
                  label: 'Accounts',
                  index: 3,
                  nav: nav,
                  isCollapsed: isCollapsed,
                ),
                _sidebarItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Transactions',
                  index: 4,
                  nav: nav,
                  isCollapsed: isCollapsed,
                ),
                _sidebarItem(
                  icon: Icons.pie_chart_outline_rounded,
                  activeIcon: Icons.pie_chart_rounded,
                  label: 'Analytics',
                  index: 5,
                  nav: nav,
                  isCollapsed: isCollapsed,
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 8),
                _sidebarItem(
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome,
                  label: 'AI Advisor',
                  index: 6,
                  nav: nav,
                  isCollapsed: isCollapsed,
                  badge: 'AI',
                ),
                _sidebarItem(
                  icon: Icons.sync_rounded,
                  activeIcon: Icons.sync_rounded,
                  label: 'Wi-Fi Sync',
                  index: 8,
                  nav: nav,
                  isCollapsed: isCollapsed,
                  badge: 'P2P',
                ),
                _sidebarItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  index: 7,
                  nav: nav,
                  isCollapsed: isCollapsed,
                ),
              ],
            ),
          ),

          // Backup Data (JSON)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: InkWell(
              onTap: () => _exportBackup(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.cloud_download_outlined, size: 18, color: AppColors.emerald),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Export Backup (JSON)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.w600, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Reset / Clear All Data Option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: InkWell(
              onTap: () => _confirmClearData(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.textMuted),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Start Fresh / Clear Data',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Collapse Sidebar Toggle
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: () => nav.toggleSidebar(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: isCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Icon(
                      isCollapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Collapse Sidebar',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required NavigationProvider nav,
    required bool isCollapsed,
    String? badge,
  }) {
    final isSelected = nav.currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => nav.setIndex(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.emeraldLight : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment:
                isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.emerald : (badge != null ? AppColors.cobalt : AppColors.textSecondary),
                size: 20,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.emerald : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.emerald : AppColors.cobaltLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.cobalt,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomBar(BuildContext context, NavigationProvider nav) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomAppBar(
          height: 62,
          color: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          notchMargin: 8,
          shape: const CircularNotchedRectangle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _bottomNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Home',
                  index: 0,
                  nav: nav,
                ),
              ),
              Expanded(
                child: _bottomNavItem(
                  icon: Icons.all_inbox_outlined,
                  activeIcon: Icons.all_inbox_rounded,
                  label: 'Envelopes',
                  index: 1,
                  nav: nav,
                ),
              ),
              const SizedBox(width: 52), // Balanced notch clearance for Center FAB
              Expanded(
                child: _bottomNavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: 'Accounts',
                  index: 3,
                  nav: nav,
                ),
              ),
              Expanded(
                child: _bottomNavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Ledger',
                  index: 4,
                  nav: nav,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required NavigationProvider nav,
  }) {
    final isSelected = nav.currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => nav.setIndex(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.emeraldLight : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.emerald : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontSize: 10,
                color: isSelected ? AppColors.emerald : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
