import 'dart:ui';

import '../models/gantt_models.dart';
import 'gantt_painter.dart';

/// Converts screen-space tap positions to job indices.
///
/// Uses linear scan through jobs — O(n) where n ≤ ~200. Fast enough
/// for tap handling (not called during scroll/zoom).
class GanttHitTester {
  final GanttData data;
  final GanttLayout layout;
  final double pixelsPerMinute;

  GanttHitTester({
    required this.data,
    required this.layout,
    required this.pixelsPerMinute,
  });

  /// Returns the index of the job at [contentPosition], or null.
  /// Scans in reverse so topmost (last-painted) jobs win on overlap.
  int? hitTest(Offset contentPosition) {
    for (var i = data.jobs.length - 1; i >= 0; i--) {
      final job = data.jobs[i];
      final rect = _jobRect(job);
      if (rect.contains(contentPosition)) return i;
    }
    return null;
  }

  Rect _jobRect(GanttJob job) {
    final jobStart = DateTime.parse(job.start);
    final minutesFromStart =
        jobStart.difference(layout.scheduleStart).inMinutes;
    final rowIdx = layout.workCenterIndex[job.row] ?? 0;

    return Rect.fromLTWH(
      minutesFromStart * pixelsPerMinute,
      rowIdx * GanttPainter.rowPitch + GanttPainter.jobPadding,
      (job.durationMinutes * pixelsPerMinute).clamp(2.0, double.infinity),
      GanttPainter.rowHeight - 2 * GanttPainter.jobPadding,
    );
  }
}
