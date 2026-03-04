import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/staff_models.dart';

class StaffChart extends StatelessWidget {
  final StaffData data;

  const StaffChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeShifts = data.activeShifts;

    if (activeShifts.isEmpty) {
      return Center(
        child: Text(
          'No active shifts',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    double maxY = 0;
    for (final s in activeShifts) {
      if (s.requiredBodies > maxY) maxY = s.requiredBodies;
      if (s.actualBodies > maxY) maxY = s.actualBodies;
    }
    maxY = (maxY * 1.2).ceilToDouble();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: (activeShifts.length * 60.0).clamp(300, double.infinity),
        child: Padding(
          padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          child: BarChart(
            BarChartData(
              maxY: maxY,
              barGroups: activeShifts.asMap().entries.map((entry) {
                final i = entry.key;
                final shift = entry.value;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: shift.requiredBodies,
                      color: AppTheme.zinc400.withValues(alpha: 0.6),
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                    ),
                    BarChartRodData(
                      toY: shift.actualBodies,
                      color: shift.hasShortage
                          ? AppTheme.red500
                          : AppTheme.orange500,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                    ),
                  ],
                );
              }).toList(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      theme.colorScheme.surfaceContainerHigh,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final shift = activeShifts[group.x.toInt()];
                    final label =
                        rodIndex == 0 ? 'Required' : 'Actual';
                    final value = rodIndex == 0
                        ? shift.requiredBodies
                        : shift.actualBodies;
                    return BarTooltipItem(
                      '$label: ${value.toInt()}\n${_formatShiftDate(shift.intervalStart)}',
                      TextStyle(
                        color: rod.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= activeShifts.length) {
                        return const SizedBox.shrink();
                      }
                      final shift = activeShifts[idx];
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatShiftDate(shift.intervalStart),
                              style: TextStyle(
                                fontSize: 9,
                                color:
                                    theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              shift.typeName,
                              style: TextStyle(
                                fontSize: 8,
                                color:
                                    theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.min || value == meta.max) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ),
    );
  }

  String _formatShiftDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('M/d').format(dt);
    } catch (_) {
      return isoDate.substring(0, 10);
    }
  }
}

class StaffLegend extends StatelessWidget {
  const StaffLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(
          color: AppTheme.zinc400.withValues(alpha: 0.6),
          label: 'Required',
          theme: theme,
        ),
        const SizedBox(width: 24),
        _LegendItem(
          color: AppTheme.orange500,
          label: 'Actual',
          theme: theme,
        ),
        const SizedBox(width: 24),
        _LegendItem(
          color: AppTheme.red500,
          label: 'Shortage',
          theme: theme,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final ThemeData theme;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
