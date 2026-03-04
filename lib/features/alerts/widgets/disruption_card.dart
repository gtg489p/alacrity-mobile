import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/disruption_models.dart';

/// A disruption card with severity color coding and animated pulsing
/// border for critical alerts.
class DisruptionCard extends StatefulWidget {
  final Disruption disruption;
  final VoidCallback? onTap;

  const DisruptionCard({
    super.key,
    required this.disruption,
    this.onTap,
  });

  @override
  State<DisruptionCard> createState() => _DisruptionCardState();
}

class _DisruptionCardState extends State<DisruptionCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    if (widget.disruption.isCritical && widget.disruption.isOpen) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
      _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = widget.disruption;
    final severityColor = _severityColor(d.severity);
    final timeAgo = _formatTimeAgo(d.createdAt);

    Widget card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          children: [
            // Severity banner
            Container(
              height: 4,
              color: severityColor,
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _typeIcon(d.type),
                      color: severityColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                d.title,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.summary,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.work_outline,
                              label: '${d.affectedJobsCount} jobs',
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.circle,
                              iconSize: 8,
                              label: d.status.toUpperCase(),
                              color: d.isOpen ? severityColor : AppTheme.emerald500,
                              theme: theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Animated pulsing border for critical open alerts
    if (_pulseAnimation != null) {
      card = AnimatedBuilder(
        listenable: _pulseAnimation!,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.red500.withValues(alpha: _pulseAnimation!.value),
                width: 2,
              ),
            ),
            child: child,
          );
        },
        child: card,
      );
    }

    return card;
  }

  static Color _severityColor(String severity) => switch (severity) {
        'critical' => AppTheme.red500,
        'warning' => AppTheme.amber500,
        _ => AppTheme.blue500,
      };

  static IconData _typeIcon(String type) => switch (type) {
        'equipment' => Icons.precision_manufacturing,
        'material' => Icons.inventory_2_outlined,
        'staff' => Icons.people_outline,
        _ => Icons.warning_amber_outlined,
      };

  static String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final String label;
  final Color? color;
  final ThemeData theme;

  const _InfoChip({
    required this.icon,
    this.iconSize = 12,
    required this.label,
    this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color ?? theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color ?? theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper around AnimatedBuilder for compatibility
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);

  Animation<double> get animation => listenable as Animation<double>;
}
