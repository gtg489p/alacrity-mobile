import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/chart_colors.dart';
import '../models/material_models.dart';

class MaterialChart extends StatelessWidget {
  final MaterialData data;

  const MaterialChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.materials.isEmpty) {
      return Center(
        child: Text(
          'No material data available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Find min/max minute across all series for axis range
    int minMinute = 0x7FFFFFFF;
    int maxMinute = 0;
    double maxBalance = 0;
    for (final mat in data.materials) {
      for (final s in mat.series) {
        if (s.minute < minMinute) minMinute = s.minute;
        if (s.minute > maxMinute) maxMinute = s.minute;
        if (s.balance > maxBalance) maxBalance = s.balance;
      }
    }
    if (minMinute == 0x7FFFFFFF) minMinute = 0;

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
      child: LineChart(
        LineChartData(
          lineBarsData: data.materials.asMap().entries.map((entry) {
            final idx = entry.key;
            final mat = entry.value;
            final color =
                ChartColors.palette[idx % ChartColors.palette.length];
            return LineChartBarData(
              spots: mat.series
                  .map((s) => FlSpot(s.minute.toDouble(), s.balance))
                  .toList(),
              isCurved: false,
              isStepLineChart: true,
              color: color,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.1),
              ),
              barWidth: 2,
            );
          }).toList(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) =>
                  theme.colorScheme.surfaceContainerHigh,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final matIndex = spot.barIndex;
                  final matName = matIndex < data.materials.length
                      ? data.materials[matIndex].materialName
                      : 'Unknown';
                  return LineTooltipItem(
                    '$matName\n${NumberFormat('#,##0').format(spot.y)} gal',
                    TextStyle(
                      color: spot.bar.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _computeTimeInterval(minMinute, maxMinute),
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'D${(value / 1440).floor()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${NumberFormat.compact().format(value)} gal',
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
            horizontalInterval: _autoGridInterval(maxBalance),
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  double _computeTimeInterval(int minMin, int maxMin) {
    final range = maxMin - minMin;
    if (range <= 1440) return 360; // 6h intervals
    if (range <= 7200) return 1440; // 1d intervals
    return 2880; // 2d intervals
  }

  double _autoGridInterval(double maxVal) {
    if (maxVal <= 100) return 20;
    if (maxVal <= 500) return 100;
    if (maxVal <= 2000) return 500;
    if (maxVal <= 10000) return 2000;
    return 5000;
  }
}

class MaterialLegend extends StatelessWidget {
  final MaterialData data;

  const MaterialLegend({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: data.materials.asMap().entries.map((entry) {
        final idx = entry.key;
        final mat = entry.value;
        final color = ChartColors.palette[idx % ChartColors.palette.length];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              mat.materialName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
