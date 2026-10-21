import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? badgeText;
  final Color? badgeColor;
  final Color accentColor;
  final IconData icon;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.badgeText,
    this.badgeColor,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 900;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: isCompact
                      ? AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          fontSize: 11,
                        )
                      : AppTypography.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: EdgeInsets.all(isCompact ? 6 : 8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: isCompact ? 15 : 18),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 6 : 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: isCompact
                  ? AppTypography.currencyMedium.copyWith(fontSize: 17)
                  : AppTypography.currencyMedium,
            ),
          ),
          SizedBox(height: isCompact ? 4 : 8),
          if (badgeText != null)
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 6 : 8,
                      vertical: isCompact ? 2 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? accentColor).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: badgeColor ?? accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: isCompact ? 9.5 : 11,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(height: isCompact ? 12 : 20),
        ],
      ),
    );
  }
}
