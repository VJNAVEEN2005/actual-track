import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_provider.dart';
import '../../providers/navigation_provider.dart';
import '../widgets/account_card.dart';
import '../widgets/add_category_modal.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/edit_budget_dialog.dart';
import '../widgets/envelope_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/transaction_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
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
            // Top Header Bar
            _buildHeader(context),
            SizedBox(height: isDesktop ? 24 : 16),

            // Top Metric Cards Row (4 cards)
            _buildMetricCards(context, provider),
            SizedBox(height: isDesktop ? 28 : 20),

            // Accounts Carousel Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Accounts & Liquidity', style: AppTypography.heading3),
                Text(
                  '${provider.accounts.length} active',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.accounts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_outlined, color: AppColors.emerald, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No accounts added yet', style: AppTypography.heading3.copyWith(fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            'Add your bank accounts, savings, or cash wallets to track balances.',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.read<NavigationProvider>().setIndex(3),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Account', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 135,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.accounts.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    return AccountCard(account: provider.accounts[index]);
                  },
                ),
              ),
            const SizedBox(height: 28),

            // Main Content Area: Dual-Column on Desktop, Single Column on Mobile
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Envelopes (Zero-based budgeting)
                  Expanded(
                    flex: 5,
                    child: _buildEnvelopesSection(context, provider),
                  ),
                  const SizedBox(width: 24),
                  // Right: Cash Flow Chart + Recent Transactions
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCashFlowChartCard(context, provider),
                        const SizedBox(height: 24),
                        _buildRecentTransactionsSection(context, provider),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              _buildCashFlowChartCard(context, provider),
              const SizedBox(height: 24),
              _buildEnvelopesSection(context, provider),
              const SizedBox(height: 24),
              _buildRecentTransactionsSection(context, provider),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (!isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Financial Overview', style: AppTypography.heading2.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text(
                  'Zero-based budget & ledger',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => context.read<NavigationProvider>().setIndex(8),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.emeraldLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sync_rounded, color: AppColors.emerald, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Wi-Fi Sync',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.emerald,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Overview', style: AppTypography.heading1),
            const SizedBox(height: 4),
            Text(
              'Zero-based envelope budgeting & local-first ledger',
              style: AppTypography.subtitle,
            ),
          ],
        ),
        Row(
          children: [
            InkWell(
              onTap: () => context.read<NavigationProvider>().setIndex(8),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.emeraldLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sync_rounded, color: AppColors.emerald, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Wi-Fi Sync • SQLite',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => AddTransactionModal.show(context),
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
              label: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCards(BuildContext context, AppProvider provider) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;
    final isTablet = width >= 600 && width < 900;

    final cards = [
      MetricCard(
        title: 'Spendable Liquidity',
        value: Formatters.currency(provider.liquidNetWorth),
        badgeText: provider.totalInvestments > 0
            ? 'Inv: ${Formatters.currency(provider.totalInvestments)}'
            : 'Liquid cash',
        badgeColor: AppColors.emerald,
        accentColor: AppColors.emerald,
        icon: Icons.account_balance_wallet_outlined,
      ),
      MetricCard(
        title: 'Monthly Inflow',
        value: Formatters.currency(provider.monthlyInflow),
        badgeText: 'Active income',
        badgeColor: AppColors.cobalt,
        accentColor: AppColors.cobalt,
        icon: Icons.arrow_downward_rounded,
      ),
      MetricCard(
        title: 'Monthly Outflow',
        value: Formatters.currency(provider.monthlyOutflow),
        badgeText: 'Total spend',
        badgeColor: AppColors.coral,
        accentColor: AppColors.coral,
        icon: Icons.arrow_upward_rounded,
      ),
      MetricCard(
        title: 'Free to Budget',
        value: Formatters.currency(provider.availableToBudget),
        badgeText: 'Zero-based target',
        badgeColor: AppColors.violet,
        accentColor: AppColors.violet,
        icon: Icons.pie_chart_outline_rounded,
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                ))
            .toList(),
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: isTablet ? 1.8 : 1.35,
        children: cards,
      );
    }
  }

  Widget _buildCashFlowChartCard(BuildContext context, AppProvider provider) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final inflows = provider.cumulativeWeeklyInflow;
    final outflows = provider.cumulativeWeeklyOutflow;

    final inflowSpots = inflows.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final outflowSpots = outflows.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    double maxVal = 1000.0;
    for (final v in [...inflows, ...outflows]) {
      if (v > maxVal) maxVal = v;
    }

    final netFlow = provider.monthlyInflow - provider.monthlyOutflow;
    final isSurplus = netFlow >= 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDesktop) ...[
            Text('Cumulative Cash Flow', style: AppTypography.heading3.copyWith(fontSize: 16)),
            const SizedBox(height: 2),
            Text('Income vs. Expenses trajectory',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSurplus ? AppColors.emeraldLight : AppColors.coralLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (isSurplus ? AppColors.emerald : AppColors.coral).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${isSurplus ? "+" : ""}${Formatters.currency(netFlow)} Net',
                    style: TextStyle(
                      color: isSurplus ? AppColors.emerald : AppColors.coral,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                _chartLegend('Inflow', AppColors.emerald),
                const SizedBox(width: 10),
                _chartLegend('Outflow', AppColors.coral),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cumulative Cash Flow', style: AppTypography.heading3),
                    const SizedBox(height: 2),
                    Text('Income vs. Expenses trajectory across weeks',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSurplus ? AppColors.emeraldLight : AppColors.coralLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (isSurplus ? AppColors.emerald : AppColors.coral).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${isSurplus ? "+" : ""}${Formatters.currency(netFlow)} Net',
                        style: TextStyle(
                          color: isSurplus ? AppColors.emerald : AppColors.coral,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    _chartLegend('Inflow', AppColors.emerald),
                    const SizedBox(width: 12),
                    _chartLegend('Outflow', AppColors.coral),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxVal * 1.15,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                                        tooltipBorder: const BorderSide(color: AppColors.border),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isInflow = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${isInflow ? "Inflow: " : "Outflow: "}${Formatters.currency(spot.y)}',
                          TextStyle(
                            color: isInflow ? AppColors.emerald : AppColors.coral,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: AppColors.textMuted.withValues(alpha: 0.3),
                          strokeWidth: 1.5,
                          dashArray: [4, 4],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 6,
                            color: barData.color ?? AppColors.emerald,
                            strokeWidth: 2.5,
                            strokeColor: Colors.white,
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderSubtle,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            Formatters.compactCurrency(value),
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final days = isDesktop
                            ? const ['W1 (1-7)', 'W2 (8-14)', 'W3 (15-21)', 'W4 (22-28)', 'W5 (29+)']
                            : const ['W1', 'W2', 'W3', 'W4', 'W5'];
                        final idx = value.toInt();
                        if (idx >= 0 && idx < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              days[idx],
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Inflow Line
                  LineChartBarData(
                    spots: inflowSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.emerald,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.emerald,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.emerald.withValues(alpha: 0.22),
                          AppColors.emerald.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Outflow Line
                  LineChartBarData(
                    spots: outflowSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.coral,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.coral,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.coral.withValues(alpha: 0.18),
                          AppColors.coral.withValues(alpha: 0.0),
                        ],
                      ),
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

  Widget _chartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEnvelopesSection(BuildContext context, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Budget Envelopes', style: AppTypography.heading3),
                Text(
                  '${provider.categories.length} categories active',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => AddCategoryModal.show(context),
              icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.emerald),
              label: Text(
                'New Envelope',
                style: AppTypography.caption.copyWith(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (provider.categories.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.all_inbox_outlined, size: 32, color: AppColors.textMuted),
                const SizedBox(height: 10),
                Text('No Budget Envelopes Yet', style: AppTypography.heading3.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text('Create category envelopes to begin allocating your monthly budget.', style: AppTypography.caption, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () => AddCategoryModal.show(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create Envelope', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final cat = provider.categories[index];
              return EnvelopeCard(
                category: cat,
                onEditBudget: () => EditBudgetDialog.show(context, cat),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context, AppProvider provider) {
    final recent = provider.transactions.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: AppTypography.heading3),
            Text(
              'Showing ${recent.length} recent',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.textMuted),
                const SizedBox(height: 10),
                Text('No Transactions Yet', style: AppTypography.heading3.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text('Your recent income, expenses, and transfers will appear here.', style: AppTypography.caption, textAlign: TextAlign.center),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tx = recent[index];
              return TransactionTile(
                transaction: tx,
                account: provider.getAccountById(tx.accountId),
                category: provider.getCategoryById(tx.categoryId),
                onDelete: () => provider.deleteTransaction(tx),
              );
            },
          ),
      ],
    );
  }
}
