import 'package:flutter/material.dart';
import 'package:mobile_app/core/time_utils.dart';
import 'package:mobile_app/models/monthly_summary.dart';
import 'package:mobile_app/services/canteen_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.repository,
    required this.monthlySummary,
    required this.monthLabel,
    required this.selectedMonth,
    required this.dailyTotals,
    required this.canGoNext,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final CanteenRepository? repository;
  final MonthlySummary? monthlySummary;
  final String monthLabel;
  final String selectedMonth;
  final Map<String, double> dailyTotals;
  final bool canGoNext;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final repo = repository;
    final balance = repo?.balance;
    final balanceUpdatedAt = repo?.balanceUpdatedAt;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = monthlySummary;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Balance Card
            Card(
              elevation: 2,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '当前余额',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      balance == null
                          ? '¥ --'
                          : '¥ ${balance.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      balanceUpdatedAt == null || balanceUpdatedAt.isEmpty
                          ? '点击刷新按钮同步余额'
                          : '更新于 ${formatDateTime(balanceUpdatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Monthly Summary Card
            Card(
              elevation: 2,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '消费汇总',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          onPressed: onPrevMonth,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        Text(
                          monthLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          onPressed: canGoNext ? onNextMonth : null,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                    if (summary != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _StatItem(label: '总消费', value: '¥${summary.totalSpent.toStringAsFixed(2)}', hint: '当月总消费', icon: Icons.payments_outlined, colorScheme: colorScheme)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatItem(label: '总笔数', value: '${summary.transactionCount}', hint: '消费记录数', icon: Icons.receipt_long_outlined, colorScheme: colorScheme)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _StatItem(label: '活跃日均', value: '¥${summary.avgPerActiveDay.toStringAsFixed(2)}', hint: '总额 / 活跃天数', icon: Icons.trending_up_outlined, colorScheme: colorScheme)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatItem(label: '活跃天数', value: '${summary.activeDays}', hint: '当日有消费', icon: Icons.event_available_outlined, colorScheme: colorScheme)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _StatItem(label: '单笔均消费', value: '¥${summary.avgPerTransaction.toStringAsFixed(2)}', hint: '总额 / 笔数', icon: Icons.analytics_outlined, colorScheme: colorScheme)),
                          const SizedBox(width: 12),
                          Expanded(child: _StatItem(label: '单日峰值', value: '¥${summary.maxDailySpent.toStringAsFixed(2)}', hint: '单日最高消费', icon: Icons.arrow_upward_outlined, colorScheme: colorScheme)),
                        ],
                      ),
                    ],
                    if (summary == null) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '暂无数据，请刷新',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Spending Calendar Card
            Card(
              elevation: 2,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _SpendingCalendar(
                  selectedMonth: selectedMonth,
                  dailyTotals: dailyTotals,
                ),
              ),
            ),
          ],
          ),
        ),
      );
    }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    this.hint,
    required this.icon,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final String? hint;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _SpendingCalendar extends StatelessWidget {
  const _SpendingCalendar({
    required this.selectedMonth,
    required this.dailyTotals,
  });

  final String selectedMonth;
  final Map<String, double> dailyTotals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Parse year/month from "YYYY-MM"
    final parts = selectedMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    // Find max daily spending for color scaling
    final maxSpend = dailyTotals.values.isEmpty
        ? 1.0
        : dailyTotals.values.reduce((a, b) => a > b ? a : b);

    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.grid_view_outlined, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('消费日历', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        // Weekday headers
        Row(
          children: weekdays.map((d) => Expanded(
            child: Center(
              child: Text(d, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 4),
        // Calendar grid rows
        ..._buildCalendarRows(
          daysInMonth: daysInMonth,
          startWeekday: startWeekday,
          year: year,
          month: month,
          maxSpend: maxSpend,
          theme: theme,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  List<Widget> _buildCalendarRows({
    required int daysInMonth,
    required int startWeekday,
    required int year,
    required int month,
    required double maxSpend,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final rows = <Widget>[];
    var dayCounter = 1;
    final totalCells = startWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    for (var row = 0; row < rowCount; row++) {
      final cells = <Widget>[];
      for (var col = 0; col < 7; col++) {
        final cellIndex = row * 7 + col;
        if (cellIndex < startWeekday || dayCounter > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 48)));
        } else {
          final day = dayCounter;
          final dayStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          final spent = dailyTotals[dayStr] ?? 0.0;
          final intensity = maxSpend > 0 ? (spent / maxSpend).clamp(0.0, 1.0) : 0.0;

          final bgColor = spent > 0
              ? Color.lerp(
                  colorScheme.primaryContainer,
                  colorScheme.primary,
                  intensity * 0.7,
                )!
              : colorScheme.surfaceContainerHighest;
          final textColor = spent > 0
              ? Color.lerp(
                  colorScheme.onPrimaryContainer,
                  colorScheme.onPrimary,
                  intensity * 0.7,
                )!
              : colorScheme.onSurfaceVariant;

          cells.add(Expanded(
            child: Container(
              height: 48,
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (spent > 0)
                    Text(
                      spent.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 9,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),
          ));
          dayCounter++;
        }
      }
      rows.add(Row(children: cells));
    }
    return rows;
  }
}

