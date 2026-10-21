import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final categoriesWithSpend = provider.categories
        .where((c) => c.spent > 0)
        .toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));

    final totalSpent = provider.monthlyOutflow > 0
        ? provider.monthlyOutflow
        : categoriesWithSpend.fold(0.0, (sum, c) => sum + c.spent);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spending Insights', style: AppTypography.heading1),
                const SizedBox(height: 4),
                Text(
                  'Distribution and outflow analytics across categories',
                  style: AppTypography.subtitle,
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildDonutChartCard(categoriesWithSpend, totalSpent),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 6,
                    child: _buildCategoryBreakdownCard(categoriesWithSpend, totalSpent),
                  ),
                ],
              )
            else ...[
              _buildDonutChartCard(categoriesWithSpend, totalSpent),
              const SizedBox(height: 20),
              _buildCategoryBreakdownCard(categoriesWithSpend, totalSpent),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutChartCard(List<dynamic> categories, double totalSpent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Outflow Breakdown', style: AppTypography.heading2.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text('Proportional distribution by category',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 65,
                    sections: categories.isEmpty
                        ? [
                            PieChartSectionData(
                              color: AppColors.surfaceSecondary,
                              value: 1,
                              title: '',
                              radius: 24,
                            ),
                          ]
                        : categories.asMap().entries.map((entry) {
                            final i = entry.key;
                            final cat = entry.value;
                            final isTouched = i == _touchedIndex;
                            final radius = isTouched ? 34.0 : 26.0;
                            final color = Color(cat.colorValue);

                            return PieChartSectionData(
                              color: color,
                              value: cat.spent,
                              title: '',
                              radius: radius,
                            );
                          }).toList(),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final isSliceTouched = _touchedIndex >= 0 && _touchedIndex < categories.length;
                    final touchedCat = isSliceTouched ? categories[_touchedIndex] : null;
                    final pct = (isSliceTouched && totalSpent > 0)
                        ? (touchedCat!.spent / totalSpent * 100)
                        : 0.0;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (touchedCat != null) ...[
                          Text(
                            touchedCat.name,
                            style: AppTypography.caption.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(touchedCat.colorValue),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.currency(touchedCat.spent),
                            style: AppTypography.heading2.copyWith(fontSize: 18),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}% of total',
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ] else ...[
                          Text('Total Spent', style: AppTypography.caption.copyWith(fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.compactCurrency(totalSpent),
                            style: AppTypography.heading2.copyWith(fontSize: 20),
                          ),
                          Text(
                            'Touch slice for %',
                            style: AppTypography.caption.copyWith(fontSize: 9, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownCard(List<dynamic> categories, double totalSpent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ranked Outflow', style: AppTypography.heading2.copyWith(fontSize: 18)),
          const SizedBox(height: 4),
          Text('Highest spending category envelopes',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.pie_chart_outline_rounded, size: 36, color: AppColors.textMuted),
                    const SizedBox(height: 10),
                    Text('No expenses recorded this month', style: AppTypography.heading3.copyWith(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('Category breakdown will appear here once you record spending.', style: AppTypography.caption),
                  ],
                ),
              ),
            )
          else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final catColor = Color(cat.colorValue);
              final percentage = totalSpent > 0 ? (cat.spent / totalSpent * 100) : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: catColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(cat.name, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text(
                        '${Formatters.currency(cat.spent)} (${percentage.toStringAsFixed(1)}%)',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (percentage / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceSecondary,
                      valueColor: AlwaysStoppedAnimation<Color>(catColor),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
