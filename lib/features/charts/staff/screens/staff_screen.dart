import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_shimmer.dart';
import '../providers/staff_provider.dart';
import '../widgets/staff_chart.dart';

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(staffDataProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(staffDataProvider),
      child: dataAsync.when(
        loading: () => const LoadingShimmer(),
        error: (err, _) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: ErrorState(
              error: err,
              onRetry: () => ref.invalidate(staffDataProvider),
            ),
          ),
        ),
        data: (data) {
          if (data.activeShifts.isEmpty) {
            return const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 400,
                child: EmptyState(
                  icon: Icons.people_outlined,
                  message: 'No staff/labor data available',
                ),
              ),
            );
          }
          final theme = Theme.of(context);
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
                    label: 'Labor Cost',
                    value: fmtCurrency.format(data.totalLaborCost),
                    theme: theme,
                  ),
                  _KpiChip(
                    label: 'Cost/Gallon',
                    value: fmtCurrency.format(data.laborCostPerGallon),
                    theme: theme,
                  ),
                  _KpiChip(
                    label: 'Shifts',
                    value: '${data.activeShifts.length}',
                    theme: theme,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: StaffChart(data: data),
              ),
              const SizedBox(height: 12),
              const StaffLegend(),
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
