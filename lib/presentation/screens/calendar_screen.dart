import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/schedule_model.dart';
import '../../providers/app_provider.dart';
import '../widgets/add_schedule_modal.dart';
import '../widgets/month_selector_bar.dart';
import '../widgets/transaction_tile.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    final selectedMonth = provider.selectedMonth;
    final selectedDay = provider.selectedCalendarDay;
    final dayTransactions = provider.getTransactionsForDay(selectedDay);
    final daySchedules = provider.getSchedulesForDay(selectedDay);

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
            // Header
            if (!isDesktop) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Financial Calendar', style: AppTypography.heading2.copyWith(fontSize: 20)),
                        const SizedBox(height: 2),
                        Text('Recurring bills & payday dates', style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => AddScheduleModal.show(context),
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
              const MonthSelectorBar(),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Financial Calendar & Schedules', style: AppTypography.heading1),
                      const SizedBox(height: 4),
                      Text(
                        'Recurring bills, payday forecasts and monthly ledger dates',
                        style: AppTypography.subtitle,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const MonthSelectorBar(),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => AddScheduleModal.show(context),
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
                        label: const Text('New Schedule', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // Main Dual-Pane Section on Desktop, Stacked on Mobile
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Calendar Grid
                  Expanded(
                    flex: 6,
                    child: _buildCalendarCard(context, provider, selectedMonth, selectedDay, isDesktop),
                  ),
                  const SizedBox(width: 24),
                  // Right: Selected Day Inspector & Upcoming Schedules
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSelectedDayCard(context, provider, selectedDay, dayTransactions, daySchedules),
                        const SizedBox(height: 20),
                        _buildUpcomingSchedulesCard(context, provider),
                      ],
                    ),
                  ),
                ],
              )
            else ...[
              _buildCalendarCard(context, provider, selectedMonth, selectedDay, isDesktop),
              const SizedBox(height: 16),
              _buildSelectedDayCard(context, provider, selectedDay, dayTransactions, daySchedules),
              const SizedBox(height: 16),
              _buildUpcomingSchedulesCard(context, provider),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard(
    BuildContext context,
    AppProvider provider,
    DateTime selectedMonth,
    DateTime selectedDay,
    bool isDesktop,
  ) {
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(selectedMonth.year, selectedMonth.month);
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    final leadingEmptyCells = startingWeekday - 1;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 14),
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
              Text(
                Formatters.monthYear(selectedMonth),
                style: AppTypography.heading2.copyWith(fontSize: isDesktop ? 18 : 16),
              ),
              Row(
                children: [
                  _indicatorLegend('Income', AppColors.emerald),
                  const SizedBox(width: 8),
                  _indicatorLegend('Expense', AppColors.coral),
                  const SizedBox(width: 8),
                  _indicatorLegend('Bills', AppColors.cobalt),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: isDesktop ? 12 : 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.border),
          const SizedBox(height: 8),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmptyCells + daysInMonth,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: isDesktop ? 8 : 4,
              mainAxisSpacing: isDesktop ? 8 : 4,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyCells) {
                return const SizedBox.shrink();
              }

              final dayNumber = index - leadingEmptyCells + 1;
              final currentDay = DateTime(selectedMonth.year, selectedMonth.month, dayNumber);
              final isSelected = selectedDay.year == currentDay.year &&
                  selectedDay.month == currentDay.month &&
                  selectedDay.day == currentDay.day;

              final today = DateTime.now();
              final isToday = today.year == currentDay.year &&
                  today.month == currentDay.month &&
                  today.day == currentDay.day;

              final dayTxs = provider.getTransactionsForDay(currentDay);
              final daySchs = provider.getSchedulesForDay(currentDay);
              final hasIncome = dayTxs.any((t) => t.isIncome) || daySchs.any((s) => s.isIncome);
              final hasExpense = dayTxs.any((t) => !t.isIncome) || daySchs.any((s) => !s.isIncome);
              final hasSchedule = daySchs.isNotEmpty;

              return InkWell(
                onTap: () => provider.selectCalendarDay(currentDay),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.emeraldLight
                        : (isToday ? AppColors.surfaceSecondary : AppColors.surface),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.emerald
                          : (isToday ? AppColors.cobalt : AppColors.borderSubtle),
                      width: isSelected || isToday ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: isDesktop ? 13 : 11.5,
                          fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? AppColors.emerald : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasIncome)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: const BoxDecoration(
                                color: AppColors.emerald,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (hasExpense)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: const BoxDecoration(
                                color: AppColors.coral,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (hasSchedule)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: const BoxDecoration(
                                color: AppColors.cobalt,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _indicatorLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildSelectedDayCard(
    BuildContext context,
    AppProvider provider,
    DateTime selectedDay,
    List<dynamic> dayTransactions,
    List<ScheduleModel> daySchedules,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Day Ledger Inspector', style: AppTypography.heading3.copyWith(fontSize: 15)),
                  Text(
                    Formatters.date(selectedDay),
                    style: AppTypography.caption.copyWith(color: AppColors.emerald, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${dayTransactions.length + daySchedules.length} Items',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (dayTransactions.isEmpty && daySchedules.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              width: double.infinity,
              child: Center(
                child: Text(
                  'No transactions or scheduled bills on this day',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ),
            )
          else ...[
            if (daySchedules.isNotEmpty) ...[
              Text('Scheduled on this day:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...daySchedules.map((sch) => _buildScheduleTile(context, provider, sch)),
              const SizedBox(height: 12),
            ],
            if (dayTransactions.isNotEmpty) ...[
              Text('Completed Transactions:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...dayTransactions.map((tx) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: TransactionTile(
                      transaction: tx,
                      account: provider.getAccountById(tx.accountId),
                      category: provider.getCategoryById(tx.categoryId),
                      onDelete: () => provider.deleteTransaction(tx),
                    ),
                  )),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildUpcomingSchedulesCard(BuildContext context, AppProvider provider) {
    final schedules = provider.schedules;

    return Container(
      padding: const EdgeInsets.all(16),
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
              Text('Recurring Bills & Schedules', style: AppTypography.heading3.copyWith(fontSize: 15)),
              Text(
                '${schedules.length} Active',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (schedules.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('No recurring schedules added yet',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: schedules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _buildScheduleTile(context, provider, schedules[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleTile(BuildContext context, AppProvider provider, ScheduleModel sch) {
    final isIncome = sch.isIncome;
    final account = provider.getAccountById(sch.accountId);
    final category = provider.getCategoryById(sch.categoryId);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isIncome ? AppColors.emeraldLight : AppColors.cobaltLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome ? Icons.trending_up_rounded : Icons.schedule_rounded,
              color: isIncome ? AppColors.emerald : AppColors.cobalt,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sch.name,
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Next: ${Formatters.shortDate(sch.nextDate)}',
                      style: AppTypography.caption.copyWith(fontSize: 10.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sch.frequency.toUpperCase(),
                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                    ),
                    if (account != null) ...[
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '• ${account.name}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.currency(sch.amount),
                style: AppTypography.currencySmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isIncome ? AppColors.emerald : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              ElevatedButton(
                onPressed: () => provider.postScheduleToLedger(sch),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: const Size(0, 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                child: const Text('Post', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
            onPressed: () => provider.deleteSchedule(sch.id),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}
