import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_provider.dart';
import '../widgets/account_card.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  void _showAddAccountDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'checking';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.hoverShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Account', style: AppTypography.heading2),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Account Name',
                    hintText: 'e.g. Chase Sapphire, Apple Card',
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'checking', child: Text('Checking')),
                    DropdownMenuItem(value: 'savings', child: Text('Savings')),
                    DropdownMenuItem(value: 'investment', child: Text('Investment / Vault')),
                    DropdownMenuItem(value: 'credit', child: Text('Credit Card')),
                    DropdownMenuItem(value: 'cash', child: Text('Cash Wallet')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedType = val);
                  },
                  decoration: InputDecoration(
                    labelText: 'Account Type',
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Initial Balance',
                    prefixText: '₹ ',
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final bal = double.tryParse(balanceController.text.trim()) ?? 0.0;
                        if (name.isNotEmpty) {
                          await context.read<AppProvider>().addAccount(
                                name: name,
                                type: selectedType,
                                balance: bal,
                                colorValue: 0xFF059669,
                                iconCode: 0xe040,
                              );
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Create Account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
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
            if (!isDesktop) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Linked Accounts', style: AppTypography.heading2.copyWith(fontSize: 20)),
                        const SizedBox(height: 2),
                        Text('Manage on & off-budget funds', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddAccountDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Linked Accounts', style: AppTypography.heading1),
                      const SizedBox(height: 4),
                      Text(
                        'Manage on-budget and off-budget accounts',
                        style: AppTypography.subtitle,
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddAccountDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Account'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),

            // Liquidity & Net Worth Banner Cards
            Container(
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softShadow,
              ),
              child: isDesktop
                  ? Row(
                      children: [
                        // Liquid Spendable Cash
                        Expanded(
                          child: _liquidityColumn(
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: AppColors.emerald,
                            title: 'Liquid Spendable Cash',
                            value: Formatters.currency(provider.liquidNetWorth),
                            valueColor: AppColors.emerald,
                            subtitle: 'Checking, Savings & Wallets',
                          ),
                        ),
                        Container(width: 1, height: 48, color: AppColors.border),
                        const SizedBox(width: 16),
                        // Off-Budget Investments
                        Expanded(
                          child: _liquidityColumn(
                            icon: Icons.trending_up_rounded,
                            iconColor: AppColors.purple,
                            title: 'Investments (Off-Budget)',
                            value: Formatters.currency(provider.totalInvestments),
                            valueColor: AppColors.purple,
                            subtitle: 'Stocks, Groww, Zerodha, Crypto',
                          ),
                        ),
                        Container(width: 1, height: 48, color: AppColors.border),
                        const SizedBox(width: 16),
                        // Total Combined
                        Expanded(
                          child: _liquidityColumn(
                            icon: Icons.pie_chart_outline_rounded,
                            iconColor: AppColors.cobalt,
                            title: 'Combined Net Worth',
                            value: Formatters.currency(provider.totalNetWorth),
                            valueColor: AppColors.textPrimary,
                            subtitle: '${provider.accounts.length} active accounts',
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _liquidityRow(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: AppColors.emerald,
                          title: 'Liquid Spendable Cash',
                          value: Formatters.currency(provider.liquidNetWorth),
                          valueColor: AppColors.emerald,
                          subtitle: 'Checking, Savings & Wallets',
                        ),
                        const Divider(height: 20, color: AppColors.border),
                        _liquidityRow(
                          icon: Icons.trending_up_rounded,
                          iconColor: AppColors.purple,
                          title: 'Investments (Off-Budget)',
                          value: Formatters.currency(provider.totalInvestments),
                          valueColor: AppColors.purple,
                          subtitle: 'Stocks, Mutual Funds, Crypto',
                        ),
                        const Divider(height: 20, color: AppColors.border),
                        _liquidityRow(
                          icon: Icons.pie_chart_outline_rounded,
                          iconColor: AppColors.cobalt,
                          title: 'Total Combined Net Worth',
                          value: Formatters.currency(provider.totalNetWorth),
                          valueColor: AppColors.textPrimary,
                          subtitle: '${provider.accounts.length} active accounts',
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cobaltLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.cobalt),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap any account to reconcile balances or update fluctuating values.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.cobalt,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Accounts Grid / List
            if (provider.accounts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.cobaltLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_rounded, size: 40, color: AppColors.cobalt),
                    ),
                    const SizedBox(height: 16),
                    Text('No Accounts Added', style: AppTypography.heading2),
                    const SizedBox(height: 8),
                    Text(
                      'Link your checking account, savings, credit cards, or cash wallets to track net liquidity.',
                      style: AppTypography.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddAccountDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add First Account', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.accounts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return AccountCard(account: provider.accounts[index]);
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _liquidityColumn({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color valueColor,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.currencyMedium.copyWith(color: valueColor),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _liquidityRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color valueColor,
    required String subtitle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: iconColor),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: AppTypography.currencyMedium.copyWith(color: valueColor, fontSize: 16),
        ),
      ],
    );
  }
}
