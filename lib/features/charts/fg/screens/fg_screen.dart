import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../providers/fg_provider.dart';
import '../widgets/fg_chart.dart';

class FgScreen extends ConsumerWidget {
  const FgScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(fgDataProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(fgDataProvider),
      child: dataAsync.when(
        loading: () => const LoadingShimmer(),
        error: (err, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: ErrorState(
              error: err,
              onRetry: () => ref.invalidate(fgDataProvider),
            ),
          ),
        ),
        data: (data) {
          if (data.products.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: EmptyState(
                  icon: Icons.inventory_outlined,
                  message: 'No finished goods data available',
                ),
              ),
            );
          }
          final theme = Theme.of(context);
          final fmtCurrency =
              NumberFormat.currency(symbol: r'$', decimalDigits: 0);
          final fmtNumber = NumberFormat('#,##0');
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
                    label: 'Holding Cost',
                    value: fmtCurrency.format(data.kpi.fgHoldingCost),
                    theme: theme,
                  ),
                  _KpiChip(
                    label: 'Gallon-Days',
                    value: fmtNumber.format(data.kpi.gallonDays),
                    theme: theme,
                  ),
                  _KpiChip(
                    label: 'Products',
                    value: '${data.products.length}',
                    theme: theme,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: FgChart(data: data),
              ),
              const SizedBox(height: 12),
              FgLegend(data: data),
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

  const _KpiChip({
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
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
            ),
          ),
        ],
      ),
    );
  }
}
