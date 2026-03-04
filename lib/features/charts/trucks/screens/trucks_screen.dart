import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../providers/truck_provider.dart';
import '../widgets/trucks_chart.dart';

class TrucksScreen extends ConsumerWidget {
  const TrucksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(truckDataProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(truckDataProvider),
      child: dataAsync.when(
        loading: () => const ChartSkeleton(),
        error: (err, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: ErrorState(
              error: err,
              onRetry: () => ref.invalidate(truckDataProvider),
            ),
          ),
        ),
        data: (result) {
          final data = result.data;
          if (data.customers.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: EmptyState(
                  icon: Icons.local_shipping_outlined,
                  message: 'No shipping data available',
                ),
              ),
            );
          }
          final theme = Theme.of(context);
          final fmtCurrency =
              NumberFormat.currency(symbol: r'$', decimalDigits: 0);
          return Column(
            children: [
              if (result.isStale)
                OfflineBanner(
                  cacheKey: result.cacheKey ?? CacheKeys.trucks(null),
                  onRetry: () => ref.invalidate(truckDataProvider),
                ),
              Expanded(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _KpiChip(
                          label: 'Trucks',
                          value: '${data.kpi.numTrucks}',
                          theme: theme,
                        ),
                        _KpiChip(
                          label: 'Shipping Cost',
                          value: fmtCurrency.format(data.kpi.fgShippingCost),
                          theme: theme,
                        ),
                        _KpiChip(
                          label: 'Utilization',
                          value:
                              '${data.kpi.truckUtilizationPct.toStringAsFixed(1)}%',
                          theme: theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: TrucksChart(data: data),
                    ),
                    const SizedBox(height: 12),
                    TrucksLegend(data: data),
                  ],
                ),
              ),
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
