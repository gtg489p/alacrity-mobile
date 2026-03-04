import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/kpi_rag_card.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../schedule_selector/screens/schedule_selector_screen.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alacrity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Switch Schedule',
            onPressed: () => showScheduleSelector(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardDataProvider);
          await ref.read(dashboardDataProvider.future);
        },
        child: dashboardAsync.when(
          loading: () => const LoadingShimmer(),
          error: (err, _) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: ErrorState(
                error: err,
                onRetry: () => ref.invalidate(dashboardDataProvider),
              ),
            ),
          ),
          data: (data) => _DashboardContent(data: data),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showScheduleSelector(context, ref),
        child: const Icon(Icons.playlist_play),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final dynamic data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Schedule info header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Schedule #${data.scheduleId}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data.objective,
                  style: theme.textTheme.labelSmall,
                ),
              ),
              const Spacer(),
              Text(
                data.solveStatus,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: data.solveStatus == 'OPTIMAL'
                      ? const Color(0xFF22C55E)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // KPI RAG cards — horizontal scroll
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: data.kpis.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => KpiRagCard(data: data.kpis[i]),
          ),
        ),

        // Last updated
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Last updated: ${_formatTime(data.fetchedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        // Chart preview cards (2x2 grid)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: const [
              _ChartPreviewCard(
                title: 'Gantt',
                icon: Icons.view_timeline,
                subtitle: 'Coming in Phase 2',
              ),
              _ChartPreviewCard(
                title: 'Material',
                icon: Icons.inventory_2,
                subtitle: 'Coming in Phase 3',
              ),
              _ChartPreviewCard(
                title: 'Staff',
                icon: Icons.people,
                subtitle: 'Coming in Phase 3',
              ),
              _ChartPreviewCard(
                title: 'Finished Goods',
                icon: Icons.local_shipping,
                subtitle: 'Coming in Phase 3',
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ChartPreviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String subtitle;

  const _ChartPreviewCard({
    required this.title,
    required this.icon,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const Spacer(),
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
