import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../models/disruption_models.dart';
import '../providers/alerts_provider.dart';
import '../widgets/disruption_card.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  String _activeFilter = 'All';

  static const _filters = ['All', 'Critical', 'Equipment', 'Material', 'Staff'];

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(disruptionListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disruptions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final filter in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _activeFilter == filter,
                      onSelected: (_) =>
                          setState(() => _activeFilter = filter),
                      selectedColor:
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                      checkmarkColor: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(disruptionListProvider),
        child: dataAsync.when(
          loading: () => const LoadingShimmer(),
          error: (err, _) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: ErrorState(
                error: err,
                onRetry: () => ref.invalidate(disruptionListProvider),
              ),
            ),
          ),
          data: (disruptions) {
            final filtered = _applyFilter(disruptions);
            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 48, color: AppTheme.emerald500),
                    const SizedBox(height: 12),
                    Text('No disruptions',
                        style: theme.textTheme.titleMedium),
                    Text(
                      _activeFilter == 'All'
                          ? 'All clear!'
                          : 'No $_activeFilter disruptions',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final d = filtered[i];
                return Dismissible(
                  key: ValueKey(d.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.emerald500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: AppTheme.emerald500),
                        SizedBox(width: 4),
                        Text('Acknowledge',
                            style: TextStyle(color: AppTheme.emerald500)),
                      ],
                    ),
                  ),
                  confirmDismiss: (_) async => true,
                  onDismissed: (_) {
                    // Acknowledge disruption (would call API)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Disruption #${d.id} acknowledged'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: DisruptionCard(
                      disruption: d,
                      onTap: () => context.push('/alerts/${d.id}'),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<Disruption> _applyFilter(List<Disruption> disruptions) {
    return switch (_activeFilter) {
      'Critical' => disruptions.where((d) => d.isCritical).toList(),
      'Equipment' => disruptions.where((d) => d.type == 'equipment').toList(),
      'Material' => disruptions.where((d) => d.type == 'material').toList(),
      'Staff' => disruptions.where((d) => d.type == 'staff').toList(),
      _ => disruptions,
    };
  }
}
