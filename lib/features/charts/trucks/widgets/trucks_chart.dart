import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/chart_colors.dart';
import '../models/truck_models.dart';

class TrucksChart extends StatelessWidget {
  final TruckData data;

  const TrucksChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daily = _aggregateDailyShipments(data);

    if (daily.isEmpty) {
      return Center(
        child: Text(
          'No shipment data',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    double maxTotal = 0;
    for (final d in daily) {
      if (d.total > maxTotal) maxTotal = d.total;
    }
    maxTotal = (maxTotal * 1.15).ceilToDouble();

    // Collect all product IDs for consistent coloring
    final allProductIds = <int>{};
    for (final d in daily) {
      allProductIds.addAll(d.productGallons.keys);
    }
    final sortedProductIds = allProductIds.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: (daily.length * 50.0).clamp(300, double.infinity),
        child: Padding(
          padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          child: BarChart(
            BarChartData(
              maxY: maxTotal,
              barGroups: daily.asMap().entries.map((entry) {
                final dayIndex = entry.key;
                final dayData = entry.value;
                return BarChartGroupData(
                  x: dayIndex,
                  barRods: [
                    BarChartRodData(
                      toY: dayData.total,
                      rodStackItems:
                          _buildStackItems(dayData, sortedProductIds),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                      color: Colors.transparent,
                    ),
                  ],
                );
              }).toList(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      theme.colorScheme.surfaceContainerHigh,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final dayData = daily[group.x.toInt()];
                    final lines = <String>[dayData.date];
                    for (final pid in sortedProductIds) {
                      final gal = dayData.productGallons[pid] ?? 0;
                      if (gal > 0) {
                        lines.add(
                            'P$pid: ${NumberFormat('#,##0').format(gal)} gal');
                      }
                    }
                    lines.add(
                        'Total: ${NumberFormat('#,##0').format(dayData.total)} gal');
                    return BarTooltipItem(
                      lines.join('\n'),
                      TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= daily.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        NumberFormat.compact().format(daily[idx].total),
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= daily.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _formatDate(daily[idx].date),
                          style: TextStyle(
                            fontSize: 9,
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
                    reservedSize: 50,
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

  List<BarChartRodStackItem> _buildStackItems(
    DailyShipment day,
    List<int> sortedProductIds,
  ) {
    final items = <BarChartRodStackItem>[];
    double fromY = 0;
    for (final pid in sortedProductIds) {
      final gal = day.productGallons[pid] ?? 0;
      if (gal > 0) {
        items.add(BarChartRodStackItem(
          fromY,
          fromY + gal,
          ChartColors.forProduct(pid),
        ));
        fromY += gal;
      }
    }
    return items;
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('M/d').format(dt);
    } catch (_) {
      return date;
    }
  }
}

List<DailyShipment> _aggregateDailyShipments(TruckData data) {
  // Flatten: date → productId → total gallons
  final Map<String, Map<int, double>> dailyMap = {};

  for (final customer in data.customers) {
    for (final day in customer.days) {
      dailyMap.putIfAbsent(day.date, () => {});
      for (final truck in day.trucks) {
        for (final seg in truck.segments) {
          if (seg.productId != null && seg.gallons > 0) {
            dailyMap[day.date]!.update(
              seg.productId!,
              (v) => v + seg.gallons,
              ifAbsent: () => seg.gallons,
            );
          }
        }
      }
    }
  }

  final sorted = dailyMap.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  return sorted
      .map((e) => DailyShipment(date: e.key, productGallons: e.value))
      .toList();
}

class TrucksLegend extends StatelessWidget {
  final TruckData data;

  const TrucksLegend({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Collect unique product IDs
    final productIds = <int>{};
    for (final c in data.customers) {
      for (final d in c.days) {
        for (final t in d.trucks) {
          for (final s in t.segments) {
            if (s.productId != null) productIds.add(s.productId!);
          }
        }
      }
    }
    final sorted = productIds.toList()..sort();

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: sorted.map((pid) {
        final color = ChartColors.forProduct(pid);
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
              'P$pid',
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
