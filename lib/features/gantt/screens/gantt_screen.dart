import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../models/gantt_models.dart';
import '../providers/gantt_provider.dart';
import '../widgets/gantt_painter.dart';
import '../widgets/gantt_hit_tester.dart';
import '../widgets/job_detail_sheet.dart';
import '../widgets/time_ruler_painter.dart';

class GanttScreen extends ConsumerStatefulWidget {
  const GanttScreen({super.key});

  @override
  ConsumerState<GanttScreen> createState() => _GanttScreenState();
}

class _GanttScreenState extends ConsumerState<GanttScreen> {
  final _transformController = TransformationController();
  int? _selectedJobIndex;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    // Sync time ruler and row headers by triggering rebuild
    setState(() {});
  }

  double get _scrollOffsetX {
    final matrix = _transformController.value;
    return -matrix.getTranslation().x;
  }

  double get _scrollOffsetY {
    final matrix = _transformController.value;
    return -matrix.getTranslation().y;
  }

  double get _currentScale {
    final matrix = _transformController.value;
    return matrix.getMaxScaleOnAxis();
  }

  void _handleTap(TapUpDetails details, GanttData data, GanttLayout layout) {
    final matrix = _transformController.value;
    final inverted = Matrix4.inverted(matrix);
    final contentPos =
        MatrixUtils.transformPoint(inverted, details.localPosition);

    final hitTester = GanttHitTester(
      data: data,
      layout: layout,
      pixelsPerMinute: GanttPainter.basePixelsPerMinute,
    );
    final jobIndex = hitTester.hitTest(contentPos);

    setState(() => _selectedJobIndex = jobIndex);

    if (jobIndex != null) {
      HapticFeedback.selectionClick();
      _showJobDetail(data.jobs[jobIndex]);
    }
  }

  void _showJobDetail(GanttJob job) {
    showModalBottomSheet(
      context: context,
      builder: (_) => JobDetailSheet(job: job),
    );
  }

  void _fitToScreen(GanttLayout layout) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final viewportWidth = renderBox.size.width - _rowHeaderWidth;
    final contentWidth = layout.totalMinutes * GanttPainter.basePixelsPerMinute;
    final scale = (viewportWidth / contentWidth).clamp(0.1, 15.0);
    _transformController.value = Matrix4.diagonal3Values(scale, scale, 1.0);
  }

  static const double _rowHeaderWidth = 110.0;
  static const double _rulerHeight = TimeRulerPainter.height;

  @override
  Widget build(BuildContext context) {
    final ganttAsync = ref.watch(ganttDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: ganttAsync.whenOrNull(
          data: (data) => Text(
            'Schedule #${data.scheduleId}',
            style: const TextStyle(fontSize: 16),
          ),
        ) ?? const Text('Gantt Chart', style: TextStyle(fontSize: 16)),
        actions: [
          if (ganttAsync.hasValue)
            IconButton(
              icon: const Icon(Icons.fit_screen, size: 20),
              tooltip: 'Fit to screen',
              onPressed: () {
                final data = ganttAsync.value!;
                _fitToScreen(GanttLayout(data));
              },
            ),
          if (ganttAsync.hasValue)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(ganttDataProvider),
            ),
        ],
      ),
      body: ganttAsync.when(
        loading: () => const _GanttLoadingState(),
        error: (error, _) => ErrorState(
          error: error,
          onRetry: () => ref.invalidate(ganttDataProvider),
        ),
        data: (data) {
          if (data.jobs.isEmpty) {
            return const _GanttEmptyState();
          }
          final layout = GanttLayout(data);
          return _buildGanttChart(data, layout);
        },
      ),
    );
  }

  Widget _buildGanttChart(GanttData data, GanttLayout layout) {
    final effectivePpm = GanttPainter.basePixelsPerMinute;
    final contentWidth = layout.totalMinutes * effectivePpm;
    final contentHeight = layout.rowCount * GanttPainter.rowPitch;

    return Column(
      children: [
        // Sticky time ruler
        SizedBox(
          height: _rulerHeight,
          child: Row(
            children: [
              // Top-left corner (empty, aligns with row headers)
              Container(
                width: _rowHeaderWidth,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              // Time ruler that scrolls horizontally in sync
              Expanded(
                child: ClipRect(
                  child: CustomPaint(
                    painter: TimeRulerPainter(
                      pixelsPerMinute: effectivePpm * _currentScale,
                      scheduleStart: layout.scheduleStart,
                      scrollOffsetX: _scrollOffsetX,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main content: row headers + Gantt canvas
        Expanded(
          child: Row(
            children: [
              // Sticky work center labels
              SizedBox(
                width: _rowHeaderWidth,
                child: _buildRowHeaders(layout),
              ),

              // Gantt canvas with InteractiveViewer
              Expanded(
                child: ClipRect(
                  child: GestureDetector(
                    onTapUp: (details) => _handleTap(details, data, layout),
                    child: InteractiveViewer(
                      transformationController: _transformController,
                      constrained: false,
                      minScale: 0.1,
                      maxScale: 15.0,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      child: CustomPaint(
                        size: Size(contentWidth, contentHeight),
                        painter: GanttPainter(
                          data: data,
                          layout: layout,
                          pixelsPerMinute: effectivePpm,
                          selectedJobIndex: _selectedJobIndex,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRowHeaders(GanttLayout layout) {
    return ClipRect(
      child: Transform.translate(
        offset: Offset(0, -_scrollOffsetY),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < layout.workCenterOrder.length; i++)
              SizedBox(
                height: GanttPainter.rowPitch * _currentScale,
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Text(
                    layout.workCenterOrder[i],
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading State — shimmer placeholder mimicking Gantt rows
// ---------------------------------------------------------------------------

class _GanttLoadingState extends StatelessWidget {
  const _GanttLoadingState();

  @override
  Widget build(BuildContext context) {
    return const LoadingShimmer();
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _GanttEmptyState extends StatelessWidget {
  const _GanttEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.view_timeline_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No schedule loaded',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a schedule from the Dashboard to view the Gantt chart',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
