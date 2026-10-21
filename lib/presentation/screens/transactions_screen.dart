import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/app_provider.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final transactions = provider.filteredTransactions;

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
                        Text('Ledger', style: AppTypography.heading2.copyWith(fontSize: 20)),
                        const SizedBox(height: 2),
                        Text('Filter & reconcile movements', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => AddTransactionModal.show(context),
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
                      Text('Transactions Ledger', style: AppTypography.heading1),
                      const SizedBox(height: 4),
                      Text(
                        'Search, filter and reconcile your financial movements',
                        style: AppTypography.subtitle,
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => AddTransactionModal.show(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Entry'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Search Bar & Filters
            Container(
              padding: EdgeInsets.all(isDesktop ? 16 : 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (val) => provider.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search by payee, note, or amount...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      filled: true,
                      fillColor: AppColors.surfaceSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          selected: provider.selectedCategoryFilter == null,
                          label: const Text('All Categories'),
                          onSelected: (selected) {
                            if (selected) provider.setCategoryFilter(null);
                          },
                          backgroundColor: AppColors.surfaceSecondary,
                          selectedColor: AppColors.emeraldLight,
                          labelStyle: TextStyle(
                            color: provider.selectedCategoryFilter == null
                                ? AppColors.emerald
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...provider.categories.map((cat) {
                          final isSelected = provider.selectedCategoryFilter == cat.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text(cat.name),
                              onSelected: (selected) {
                                provider.setCategoryFilter(selected ? cat.id : null);
                              },
                              backgroundColor: AppColors.surfaceSecondary,
                              selectedColor: AppColors.emeraldLight,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.emerald
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Transactions List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${transactions.length} Transactions Found',
                  style: AppTypography.heading3.copyWith(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (transactions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 44, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('No transactions match', style: AppTypography.heading3.copyWith(fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Try adjusting your search or category filter', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return TransactionTile(
                    transaction: tx,
                    account: provider.getAccountById(tx.accountId),
                    category: provider.getCategoryById(tx.categoryId),
                    onDelete: () => provider.deleteTransaction(tx),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
