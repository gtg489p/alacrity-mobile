import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../models/wip_models.dart';
import '../providers/wip_provider.dart';

class WipCurveScreen extends ConsumerWidget {
  const WipCurveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(wipDataProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('WIP Curve')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(wipDataProvider),
        child: dataAsync.when(
          loading: () => const LoadingShimmer(),
          error: (err, _) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: ErrorState(
                error: err,
                onRetry: () => ref.invalidate(wipDataProvider),
              ),
            ),
          ),
          data: (data) {
            if (data.points.isEmpty) {
              return const Center(
                  child: Text('No WIP data — no jobs in schedule'));
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Peak WIP header
                _PeakWipCard(data: data, theme: theme),
                const SizedBox(height: 16),
                // WIP chart
                SizedBox(
                  height: 300,
                  child: _WipChart(data: data, theme: theme),
                ),
                const SizedBox(height: 12),
                // Legend
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 3,
                      color: AppTheme.blue500,
                    ),
                    const SizedBox(width: 6),
                    Text('Concurrent Jobs',
                        style: theme.textTheme.labelSmall),
                    const SizedBox(width: 16),
                    Container(
                      width: 16,
                      height: 1,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppTheme.red500,
                            width: 1,
                            strokeAlign: BorderSide.strokeAlignCenter,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Peak WIP', style: theme.textTheme.labelSmall),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PeakWipCard extends StatelessWidget {
  final WipData data;
  final ThemeData theme;

  const _PeakWipCard({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('MMM d, HH:mm');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.trending_up, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Peak WIP', style: theme.textTheme.labelMedium),
                Text(
                  '${data.peakWip} concurrent jobs',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'at ${timeFmt.format(data.peakTime)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WipChart extends StatelessWidget {
  final WipData data;
  final ThemeData theme;

  const _WipChart({required this.data, required this.theme});

  @override
  Widget build(BuildContext context) {
    final points = data.points;
    if (points.isEmpty) return const SizedBox.shrink();

    final baseTime = points.first.time;
    // Build step-interpolated spots: for each point, add a horizontal segment
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final minutesFromStart =
          points[i].time.difference(baseTime).inMinutes.toDouble();
      // Step: draw at previous level first (if not first point)
      if (i > 0 && spots.isNotEmpty) {
        spots.add(FlSpot(minutesFromStart, spots.last.y));
      }
      spots.add(FlSpot(minutesFromStart, points[i].concurrentJobs.toDouble()));
    }

    final maxMinutes = spots.last.x;
    final maxWip = data.peakWip.toDouble();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: AppTheme.blue500,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.blue500.withValues(alpha: 0.1),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: maxWip,
              color: AppTheme.red500,
              strokeWidth: 1,
              dashArray: [6, 4],
              label: HorizontalLineLabel(
                show: true,
                labelResolver: (_) => 'Peak: ${data.peakWip}',
                style: const TextStyle(
                  color: AppTheme.red500,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget:
                Text('Jobs', style: theme.textTheme.labelSmall),
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: maxWip > 10 ? (maxWip / 5).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toInt().toString(),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget:
                Text('Time', style: theme.textTheme.labelSmall),
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: maxMinutes > 1440 ? 1440 : 480, // daily or 8hr
              getTitlesWidget: (value, meta) {
                final t = baseTime.add(Duration(minutes: value.toInt()));
                final label = maxMinutes > 2880
                    ? DateFormat('M/d').format(t)
                    : DateFormat('HH:mm').format(t);
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: theme.colorScheme.outline, width: 0.5),
            bottom: BorderSide(color: theme.colorScheme.outline, width: 0.5),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.colorScheme.surfaceContainerHigh,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final t =
                    baseTime.add(Duration(minutes: spot.x.toInt()));
                final timeFmt = DateFormat('MMM d HH:mm');
                return LineTooltipItem(
                  '${timeFmt.format(t)}\n${spot.y.toInt()} jobs',
                  TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        minY: 0,
      ),
    );
  }
}
