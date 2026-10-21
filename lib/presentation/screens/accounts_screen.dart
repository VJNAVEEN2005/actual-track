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
            width: 400,
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
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final bal = double.tryParse(balanceController.text.trim()) ?? 0.0;
                        if (name.isNotEmpty) {
                          context.read<AppProvider>().addAccount(
                                name: name,
                                type: selectedType,
                                balance: bal,
                                colorValue: Colors.blueAccent.toARGB32(),
                                iconCode: Icons.account_balance_wallet_outlined.codePoint,
                              );
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 24),

            // Liquidity & Net Worth Banner Cards
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Liquid Spendable Cash
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.emerald),
                                const SizedBox(width: 6),
                                Text('Liquid Spendable Cash', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              Formatters.currency(provider.liquidNetWorth),
                              style: AppTypography.currencyMedium.copyWith(color: AppColors.emerald),
                            ),
                            const SizedBox(height: 2),
                            Text('Checking, Savings & Wallets', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 48, color: AppColors.border),
                      const SizedBox(width: 16),
                      // Off-Budget Investments
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.purple),
                                const SizedBox(width: 6),
                                Text('Investments (Off-Budget)', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              Formatters.currency(provider.totalInvestments),
                              style: AppTypography.currencyMedium.copyWith(color: AppColors.purple),
                            ),
                            const SizedBox(height: 2),
                            Text('Stocks, Groww, Zerodha, Crypto', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      if (MediaQuery.of(context).size.width >= 700) ...[
                        Container(width: 1, height: 48, color: AppColors.border),
                        const SizedBox(width: 16),
                        // Total Combined
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.pie_chart_outline_rounded, size: 16, color: AppColors.cobalt),
                                  const SizedBox(width: 6),
                                  Text('Combined Net Worth', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                Formatters.currency(provider.totalNetWorth),
                                style: AppTypography.currencyMedium.copyWith(color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text('${provider.accounts.length} active accounts', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cobaltLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cobalt.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.cobalt),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tap any account to reconcile balances or update fluctuating investment values (Zerodha, Groww, Crypto).',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.cobalt,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Accounts Grid
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
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: provider.accounts.map((acc) {
                  return AccountCard(account: acc);
                }).toList(),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
