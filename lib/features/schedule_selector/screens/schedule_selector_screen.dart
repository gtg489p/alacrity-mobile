import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_state.dart';

part 'schedule_selector_screen.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> paretoFrontList(Ref ref) async {
  final api = ref.watch(apiClientProvider);
  return api.fetchParetoFront(limit: 50);
}

void showScheduleSelector(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => _ScheduleSelectorContent(
        scrollController: scrollController,
      ),
    ),
  );
}

class _ScheduleSelectorContent extends ConsumerWidget {
  final ScrollController scrollController;

  const _ScheduleSelectorContent({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final schedulesAsync = ref.watch(paretoFrontListProvider);
    final activeId = ref.watch(activeScheduleNotifierProvider);

    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurfaceVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Select Schedule', style: theme.textTheme.titleLarge),
        ),
        const Divider(height: 1),
        Expanded(
          child: schedulesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorState(
              error: err,
              onRetry: () => ref.invalidate(paretoFrontListProvider),
            ),
            data: (schedules) => ListView.separated(
              controller: scrollController,
              itemCount: schedules.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = schedules[i];
                final id = s['schedule_id'] as int;
                final isActive = id == activeId;
                final metrics =
                    s['pareto_metrics'] as Map<String, dynamic>;

                return ListTile(
                  selected: isActive,
                  selectedTileColor:
                      theme.colorScheme.primary.withValues(alpha: 0.08),
                  shape: isActive
                      ? RoundedRectangleBorder(
                          side: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 1.5,
                          ),
                        )
                      : null,
                  title: Row(
                    children: [
                      Text('#$id'),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          s['objective'] as String? ?? '',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                      const Spacer(),
                      _SolveStatusBadge(
                        status: s['solve_status'] as String? ?? '',
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        _KpiChip(
                          label: 'Tard',
                          value: formatKpiValue(
                            (metrics['tardiness_days'] as num?)
                                    ?.toDouble() ??
                                0,
                            'days',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _KpiChip(
                          label: 'Labor',
                          value: formatKpiValue(
                            (metrics['labor_cost'] as num?)?.toDouble() ??
                                0,
                            'USD',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _KpiChip(
                          label: 'Make',
                          value: formatKpiValue(
                            (metrics['makespan_days'] as num?)
                                    ?.toDouble() ??
                                0,
                            'days',
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    ref
                        .read(activeScheduleNotifierProvider.notifier)
                        .setSchedule(id);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SolveStatusBadge extends StatelessWidget {
  final String status;

  const _SolveStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'OPTIMAL'
        ? const Color(0xFF22C55E)
        : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;

  const _KpiChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '$label: $value',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
