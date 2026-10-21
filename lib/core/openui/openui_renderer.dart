import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_provider.dart';
import 'openui_models.dart';

class OpenUiRenderer extends StatelessWidget {
  final OpenUiNode node;
  final Function(OpenUiActionFormNode)? onActionConfirmed;
  final Function(OpenUiActionFormNode)? onActionCancelled;

  const OpenUiRenderer({
    super.key,
    required this.node,
    this.onActionConfirmed,
    this.onActionCancelled,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (node is OpenUiMetricNode) {
      return _buildMetric(node as OpenUiMetricNode);
    } else if (node is OpenUiLineChartNode) {
      return _buildLineChart(node as OpenUiLineChartNode, provider);
    } else if (node is OpenUiDonutChartNode) {
      return _buildDonutChart(node as OpenUiDonutChartNode, provider);
    } else if (node is OpenUiEnvelopeGridNode) {
      return _buildEnvelopeGrid(node as OpenUiEnvelopeGridNode, provider);
    } else if (node is OpenUiInvestmentCardNode) {
      return _buildInvestmentCard(node as OpenUiInvestmentCardNode, provider);
    } else if (node is OpenUiActionFormNode) {
      return _buildActionForm(context, node as OpenUiActionFormNode, provider);
    }

    return const SizedBox.shrink();
  }

  // --- 1. Metric Component ---
  Widget _buildMetric(OpenUiMetricNode metric) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.emerald, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(metric.value, style: AppTypography.currencyMedium.copyWith(color: AppColors.emerald)),
                ],
              ),
            ],
          ),
          if (metric.badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.emeraldLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                metric.badge!,
                style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  // --- 2. Line Chart (Cash Flow) ---
  Widget _buildLineChart(OpenUiLineChartNode chartNode, AppProvider provider) {
    final inflows = provider.cumulativeWeeklyInflow;
    final outflows = provider.cumulativeWeeklyOutflow;

    final inflowSpots = inflows.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final outflowSpots = outflows.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    double maxY = 10000;
    for (final s in [...inflowSpots, ...outflowSpots]) {
      if (s.y > maxY) maxY = s.y;
    }
    maxY = (maxY * 1.15).ceilToDouble();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(18),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.cobaltLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.show_chart_rounded, size: 16, color: AppColors.cobalt),
                  ),
                  const SizedBox(width: 8),
                  Text(chartNode.title, style: AppTypography.heading3.copyWith(fontSize: 14)),
                ],
              ),
              Row(
                children: [
                  _chartLegend('Inflow', AppColors.emerald),
                  const SizedBox(width: 12),
                  _chartLegend('Outflow', AppColors.coral),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (inflowSpots.length - 1).toDouble().clamp(1.0, 31.0),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (inflowSpots.length / 4).clamp(1.0, 10.0),
                      getTitlesWidget: (val, _) => Text(
                        'Day ${val.toInt() + 1}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: inflowSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.emerald,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.emerald.withValues(alpha: 0.08),
                    ),
                  ),
                  LineChartBarData(
                    spots: outflowSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.coral,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.coral.withValues(alpha: 0.06),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Donut Chart (Spending Breakdown) ---
  Widget _buildDonutChart(OpenUiDonutChartNode donutNode, AppProvider provider) {
    final breakdown = provider.categorySpendingBreakdown;
    final totalSpent = provider.monthlyOutflow;

    final palette = [
      AppColors.coral,
      AppColors.cobalt,
      AppColors.amber,
      AppColors.violet,
      AppColors.emerald,
      Colors.pinkAccent,
      Colors.teal,
    ];

    final entries = breakdown.entries.toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(18),
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.coralLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart_outline_rounded, size: 16, color: AppColors.coral),
              ),
              const SizedBox(width: 8),
              Text(donutNode.title, style: AppTypography.heading3.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty || totalSpent == 0)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text('No spending recorded this month yet.', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 42,
                      sections: entries.asMap().entries.map((e) {
                        final color = palette[e.key % palette.length];
                        final val = e.value.value;
                        return PieChartSectionData(
                          color: color,
                          value: val,
                          radius: 18,
                          showTitle: false,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries.take(5).toList().asMap().entries.map((e) {
                      final color = palette[e.key % palette.length];
                      final catName = e.value.key;
                      final amount = e.value.value;
                      final pct = (amount / totalSpent * 100).toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(catName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                            Text('₹${amount.toStringAsFixed(0)} ($pct%)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- 4. Envelope Grid ---
  Widget _buildEnvelopeGrid(OpenUiEnvelopeGridNode gridNode, AppProvider provider) {
    final categories = provider.categories;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(18),
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
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.all_inbox_rounded, size: 16, color: AppColors.emerald),
              ),
              const SizedBox(width: 8),
              Text(gridNode.title, style: AppTypography.heading3.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty)
            Text('No budget envelopes configured.', style: AppTypography.caption.copyWith(color: AppColors.textMuted))
          else
            ...categories.take(6).map((cat) {
              final pct = cat.budgeted > 0 ? (cat.spent / cat.budgeted).clamp(0.0, 1.0) : 0.0;
              final isOver = cat.spent > cat.budgeted;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        Text(
                          '₹${cat.spent.toStringAsFixed(0)} / ₹${cat.budgeted.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isOver ? AppColors.coral : (pct >= 0.8 ? AppColors.amber : AppColors.emerald),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceSecondary,
                        valueColor: AlwaysStoppedAnimation(
                          isOver ? AppColors.coral : (pct >= 0.8 ? AppColors.amber : AppColors.emerald),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // --- 5. Investment Card (Off-Budget Tracking) ---
  Widget _buildInvestmentCard(OpenUiInvestmentCardNode invNode, AppProvider provider) {
    final invAccounts = provider.accounts.where((a) => a.type == 'investment').toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(18),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.violetLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.violet),
                  ),
                  const SizedBox(width: 8),
                  Text(invNode.title, style: AppTypography.heading3.copyWith(fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.violetLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Off-Budget', style: TextStyle(color: AppColors.violet, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.currency(provider.totalInvestments),
            style: AppTypography.currencyMedium.copyWith(color: AppColors.violet),
          ),
          const SizedBox(height: 4),
          Text(
            'Fluctuates with markets • Excluded from liquid spendable cash',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
          ),
          if (invAccounts.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            ...invAccounts.map((acc) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(acc.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      Text(Formatters.currency(acc.balance), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.violet)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // --- 6. Action Form (Human-in-the-Loop Confirmation Card) ---
  Widget _buildActionForm(BuildContext context, OpenUiActionFormNode action, AppProvider provider) {
    final isPending = action.status == OpenUiActionStatus.pending;
    final isConfirmed = action.status == OpenUiActionStatus.confirmed;
    final isCancelled = action.status == OpenUiActionStatus.cancelled;

    Color borderColor = AppColors.border;
    Color headerBg = AppColors.surfaceSecondary;
    if (isConfirmed) {
      borderColor = AppColors.emerald;
      headerBg = AppColors.emeraldLight;
    } else if (isCancelled) {
      borderColor = AppColors.border;
      headerBg = AppColors.surfaceSecondary;
    } else {
      borderColor = AppColors.cobalt.withValues(alpha: 0.5);
      headerBg = AppColors.cobaltLight.withValues(alpha: 0.5);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isConfirmed ? 1.5 : 1.0),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isConfirmed
                          ? Icons.check_circle_rounded
                          : (isCancelled ? Icons.cancel_outlined : Icons.flash_on_rounded),
                      size: 16,
                      color: isConfirmed
                          ? AppColors.emerald
                          : (isCancelled ? AppColors.textMuted : AppColors.cobalt),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      action.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: isConfirmed
                            ? AppColors.emerald
                            : (isCancelled ? AppColors.textMuted : AppColors.cobalt),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isConfirmed
                        ? AppColors.emerald
                        : (isCancelled ? AppColors.surfaceTertiary : AppColors.cobalt),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isConfirmed ? 'SAVED' : (isCancelled ? 'CANCELLED' : 'PREVIEW'),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.summary, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 10),

                // Key metadata pills
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (action.amount != null)
                      _metaPill(
                        Icons.currency_rupee,
                        Formatters.currency(action.amount!),
                        isConfirmed ? AppColors.emerald : AppColors.textPrimary,
                      ),
                    if (action.payee != null)
                      _metaPill(Icons.storefront_outlined, action.payee!, AppColors.textSecondary),
                    if (action.accountName != null)
                      _metaPill(Icons.account_balance_outlined, action.accountName!, AppColors.cobalt),
                    if (action.categoryName != null)
                      _metaPill(Icons.all_inbox_outlined, action.categoryName!, AppColors.emerald),
                  ],
                ),

                const SizedBox(height: 14),

                // Action Buttons
                if (isPending)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          if (onActionCancelled != null) {
                            onActionCancelled!(action);
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.coral,
                          side: const BorderSide(color: AppColors.coral),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.close, size: 14),
                        label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (onActionConfirmed != null) {
                            onActionConfirmed!(action);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text('Confirm & Apply', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  )
                else if (isConfirmed)
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 16, color: AppColors.emerald),
                      const SizedBox(width: 6),
                      Text(
                        'Successfully recorded in local SQLite database.',
                        style: AppTypography.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                else if (isCancelled)
                  Row(
                    children: [
                      const Icon(Icons.cancel_outlined, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Action was cancelled. No changes were made.',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
