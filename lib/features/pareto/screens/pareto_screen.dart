import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/chart_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../models/pareto_models.dart';
import '../providers/pareto_provider.dart';

class ParetoScreen extends ConsumerStatefulWidget {
  const ParetoScreen({super.key});

  @override
  ConsumerState<ParetoScreen> createState() => _ParetoScreenState();
}

class _ParetoScreenState extends ConsumerState<ParetoScreen> {
  String _xAxis = 'labor_cost';
  String _yAxis = 'flowtime_days';

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(paretoFrontProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pareto Explorer')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(paretoFrontProvider),
        child: dataAsync.when(
          loading: () => const LoadingShimmer(),
          error: (err, _) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: ErrorState(
                error: err,
                onRetry: () => ref.invalidate(paretoFrontProvider),
              ),
            ),
          ),
          data: (solutions) {
            if (solutions.isEmpty) {
              return const Center(child: Text('No Pareto solutions available'));
            }
            final activeId = ref.watch(activeScheduleNotifierProvider);
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Axis selectors
                _buildAxisSelectors(theme),
                const SizedBox(height: 16),
                // Scatter chart
                SizedBox(
                  height: 320,
                  child: _buildScatterChart(solutions, activeId, theme),
                ),
                const SizedBox(height: 12),
                // Legend
                _buildLegend(solutions, theme),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAxisSelectors(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _AxisDropdown(
            label: 'X',
            value: _xAxis,
            onChanged: (v) => setState(() => _xAxis = v),
            theme: theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AxisDropdown(
            label: 'Y',
            value: _yAxis,
            onChanged: (v) => setState(() => _yAxis = v),
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildScatterChart(
    List<ParetoSolution> solutions,
    int? activeId,
    ThemeData theme,
  ) {
    final spots = <ScatterSpot>[];
    for (var i = 0; i < solutions.length; i++) {
      final s = solutions[i];
      final x = s.paretoMetrics.getByKey(_xAxis);
      final y = s.paretoMetrics.getByKey(_yAxis);
      final isActive = s.scheduleId == activeId;
      spots.add(ScatterSpot(
        x,
        y,
        dotPainter: FlDotCirclePainter(
          radius: isActive ? 8 : 5,
          color: isActive
              ? Colors.white
              : ChartColors.objectiveColors[s.objective] ?? AppTheme.zinc500,
          strokeColor: isActive ? AppTheme.blue500 : Colors.transparent,
          strokeWidth: isActive ? 3 : 0,
        ),
      ));
    }

    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots,
        scatterTouchData: ScatterTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.touchedSpot != null) {
              final idx = response!.touchedSpot!.spotIndex;
              _showSolutionDetail(solutions[idx]);
            }
          },
          handleBuiltInTouches: false,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              kpiShortLabels[_yAxis] ?? _yAxis,
              style: theme.textTheme.labelSmall,
            ),
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  _formatAxisValue(value, _yAxis),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Text(
              kpiShortLabels[_xAxis] ?? _xAxis,
              style: theme.textTheme.labelSmall,
            ),
            axisNameSize: 20,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  _formatAxisValue(value, _xAxis),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 0.5),
          getDrawingVerticalLine: (_) =>
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 0.5),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: theme.colorScheme.outline, width: 0.5),
        ),
      ),
    );
  }

  String _formatAxisValue(double value, String key) {
    final unit = kpiUnits[key] ?? '';
    if (unit == 'USD') {
      if (value >= 1e6) return '${(value / 1e6).toStringAsFixed(1)}M';
      if (value >= 1e3) return '${(value / 1e3).toStringAsFixed(0)}K';
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  Widget _buildLegend(List<ParetoSolution> solutions, ThemeData theme) {
    final objectives = solutions.map((s) => s.objective).toSet();
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final obj in objectives)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: ChartColors.objectiveColors[obj] ?? AppTheme.zinc500,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                kpiShortLabels[obj] ?? obj,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        // Active schedule marker
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.blue500, width: 2),
              ),
            ),
            const SizedBox(width: 4),
            Text('Active', style: theme.textTheme.labelSmall),
          ],
        ),
      ],
    );
  }

  void _showSolutionDetail(ParetoSolution solution) {
    final theme = Theme.of(context);
    final activeId = ref.read(activeScheduleNotifierProvider);
    final isActive = solution.scheduleId == activeId;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Row(
              children: [
                Text(
                  'Schedule #${solution.scheduleId}',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ChartColors.objectiveColors[solution.objective]
                            ?.withValues(alpha: 0.15) ??
                        AppTheme.zinc700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    kpiShortLabels[solution.objective] ?? solution.objective,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          ChartColors.objectiveColors[solution.objective] ??
                              theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${solution.solveStatus} — ${solution.solveTime.toStringAsFixed(1)}s',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (isActive) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.emerald500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Currently Active',
                  style: TextStyle(
                    color: AppTheme.emerald500,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            // All 8 KPIs
            for (final key in kpiKeys) ...[
              _kpiRow(
                theme,
                kpiLabels[key] ?? key,
                formatKpiValue(
                  solution.paretoMetrics.getByKey(key),
                  kpiUnits[key] ?? '',
                ),
              ),
              const Divider(height: 1),
            ],
            const SizedBox(height: 20),
            // Set Active button
            if (!isActive)
              FilledButton.icon(
                onPressed: () {
                  ref
                      .read(activeScheduleNotifierProvider.notifier)
                      .setSchedule(solution.scheduleId);
                  Navigator.of(ctx).pop();
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Set Active Schedule'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _kpiRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Axis dropdown selector
// ---------------------------------------------------------------------------

class _AxisDropdown extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final ThemeData theme;

  const _AxisDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: '$label Axis',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: [
            for (final key in kpiKeys)
              DropdownMenuItem(
                value: key,
                child: Text(
                  kpiShortLabels[key] ?? key,
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
