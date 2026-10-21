import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category_model.dart';

class EnvelopeCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onEditBudget;

  const EnvelopeCard({
    super.key,
    required this.category,
    this.onEditBudget,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = Color(category.colorValue);
    final isOver = category.isOverBudget;
    final progress = category.progressRatio;

    return InkWell(
      onTap: onEditBudget,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOver ? AppColors.coral.withValues(alpha: 0.5) : AppColors.border,
            width: 1,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  IconData(category.iconCode, fontFamily: 'MaterialIcons'),
                  color: catColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: AppTypography.heading3.copyWith(fontSize: 15),
                    ),
                    Text(
                      category.groupName,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onEditBudget,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isOver ? 'Over budget' : 'Remaining',
                            style: AppTypography.caption.copyWith(
                              color: isOver ? AppColors.coral : AppColors.emerald,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            Formatters.currency(category.remaining.abs()),
                            style: AppTypography.currencySmall.copyWith(
                              fontSize: 14,
                              color: isOver ? AppColors.coral : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_outlined, size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? AppColors.coral : catColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${Formatters.currency(category.spent)}',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                'Budget: ${Formatters.currency(category.budgeted)}',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
