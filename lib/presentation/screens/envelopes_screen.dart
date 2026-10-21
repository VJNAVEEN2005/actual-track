import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category_model.dart';
import '../../providers/app_provider.dart';
import '../widgets/add_category_modal.dart';
import '../widgets/edit_budget_dialog.dart';
import '../widgets/envelope_card.dart';

class EnvelopesScreen extends StatelessWidget {
  const EnvelopesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    // Group categories by groupName
    final grouped = <String, List<CategoryModel>>{};
    for (final cat in provider.categories) {
      grouped.putIfAbsent(cat.groupName, () => []).add(cat);
    }

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
                        Text('Budget Envelopes', style: AppTypography.heading2.copyWith(fontSize: 20)),
                        const SizedBox(height: 2),
                        Text('Zero-based allocation', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => AddCategoryModal.show(context),
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
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Free to Assign:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    Text(
                      Formatters.currency(provider.availableToBudget),
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.emerald,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zero-Based Envelopes', style: AppTypography.heading1),
                      const SizedBox(height: 4),
                      Text(
                        'Give every rupee a job before the month begins',
                        style: AppTypography.subtitle,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Text('Free to Assign: ', style: AppTypography.caption),
                            Text(
                              Formatters.currency(provider.availableToBudget),
                              style: AppTypography.heading3.copyWith(
                                color: AppColors.emerald,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => AddCategoryModal.show(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Category', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            if (grouped.isEmpty)
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
                        color: AppColors.emeraldLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.all_inbox_rounded, size: 40, color: AppColors.emerald),
                    ),
                    const SizedBox(height: 16),
                    Text('No Budget Envelopes Yet', style: AppTypography.heading2),
                    const SizedBox(height: 8),
                    Text(
                      'Zero-based budgeting allocates every Rupee to a category.\nCreate your first envelope to start budgeting.',
                      style: AppTypography.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => AddCategoryModal.show(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add First Envelope', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              )
            else
              // Groups
              ...grouped.entries.map((entry) {
                final groupName = entry.key;
                final list = entry.value;
                final totalGroupBudget = list.fold(0.0, (sum, c) => sum + c.budgeted);
                final totalGroupSpent = list.fold(0.0, (sum, c) => sum + c.spent);

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: EdgeInsets.all(isDesktop ? 20 : 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              groupName,
                              style: AppTypography.heading2.copyWith(fontSize: isDesktop ? 18 : 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${Formatters.currency(totalGroupSpent)} of ${Formatters.currency(totalGroupBudget)}',
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, fontSize: isDesktop ? 12 : 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final cat = list[index];
                          return EnvelopeCard(
                            category: cat,
                            onEditBudget: () => EditBudgetDialog.show(context, cat),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
