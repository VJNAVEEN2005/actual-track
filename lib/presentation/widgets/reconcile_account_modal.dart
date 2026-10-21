import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/account_model.dart';
import '../../providers/app_provider.dart';

class ReconcileAccountModal {
  static void show(BuildContext context, AccountModel account) {
    final balanceController = TextEditingController(
      text: account.balance.toStringAsFixed(2),
    );
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final currentVal = double.tryParse(balanceController.text.trim()) ?? account.balance;
          final diff = currentVal - account.balance;
          final isGain = diff >= 0;

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 440,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(account.colorValue).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              IconData(account.iconCode, fontFamily: 'MaterialIcons'),
                              color: Color(account.colorValue),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(account.name, style: AppTypography.heading3),
                              Text(
                                '${account.type.toUpperCase()} ACCOUNT',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Current recorded vs new value
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recorded Balance',
                              style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.currency(account.balance),
                              style: AppTypography.heading3.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        if (diff.abs() > 0.01)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isGain ? AppColors.emeraldLight : AppColors.coralLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isGain ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                  color: isGain ? AppColors.emerald : AppColors.coral,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${isGain ? "+" : ""}${Formatters.currency(diff)}',
                                  style: TextStyle(
                                    color: isGain ? AppColors.emerald : AppColors.coral,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text(
                    'Current Market Value (e.g. from Zerodha, Groww, or Bank):',
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      hintText: 'Enter updated value',
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
                    controller: notesController,
                    decoration: InputDecoration(
                      labelText: 'Adjustment Note (Optional)',
                      hintText: 'e.g. October Stock Market Surge, SIP dividend',
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
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          final newVal = double.tryParse(balanceController.text.trim()) ?? account.balance;
                          final notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();
                          context.read<AppProvider>().updateAccountBalance(account.id, newVal, notes: notes);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Save & Reconcile', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
