import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../providers/material_provider.dart';
import '../widgets/material_chart.dart';

class MaterialScreen extends ConsumerWidget {
  const MaterialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(materialDataProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(materialDataProvider),
      child: dataAsync.when(
        loading: () => const LoadingShimmer(),
        error: (err, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: ErrorState(
              error: err,
              onRetry: () => ref.invalidate(materialDataProvider),
            ),
          ),
        ),
        data: (data) {
          if (data.materials.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  message: 'No material inventory data available',
                ),
              ),
            );
          }
          final theme = Theme.of(context);
          final fmt = NumberFormat('#,##0');
          final fmtCurrency =
              NumberFormat.currency(symbol: r'$', decimalDigits: 0);
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              // KPI header
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _KpiChip(
                    label: 'Restock Cost',
                    value: fmtCurrency.format(data.kpi.restockCost),
                    theme: theme,
                  ),
                  _KpiChip(
                    label: 'Restocks',
                    value: fmt.format(data.kpi.numRestocks),
                    theme: theme,
                  ),
                  _KpiChip(
                    label: 'Stockouts',
                    value: fmt.format(data.kpi.numStockouts),
                    theme: theme,
                    isWarning: data.kpi.numStockouts > 0,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Chart
              SizedBox(
                height: 300,
                child: MaterialChart(data: data),
              ),
              const SizedBox(height: 12),
              // Legend
              MaterialLegend(data: data),
            ],
          );
        },
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  final bool isWarning;

  const _KpiChip({
    required this.label,
    required this.value,
    required this.theme,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: isWarning
            ? Border.all(color: const Color(0xFFEF4444), width: 1)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isWarning ? const Color(0xFFEF4444) : null,
            ),
          ),
        ],
      ),
    );
  }
}
