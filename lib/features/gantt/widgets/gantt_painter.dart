import 'package:flutter/material.dart';

import '../models/gantt_models.dart';
import '../../../core/theme/chart_colors.dart';

/// CustomPainter that renders the entire Gantt chart content.
///
/// Paint order:
///  1. Row backgrounds (alternating zinc-900/zinc-850)
///  2. Shift band overlays (semi-transparent tint per shift period) — M2 gap fix
///  3. Time grid lines
///  4. Job blocks (colored rectangles with rounded corners)
///  5. Job labels (text inside blocks, ellipsis overflow)
///  6. Now line (red vertical line)
class GanttPainter extends CustomPainter {
  final GanttData data;
  final GanttLayout layout;
  final double pixelsPerMinute;
  final int? selectedJobIndex;
  final int? hoveredProductionRunId;

  // Layout constants
  static const double basePixelsPerMinute = 2.0;
  static const double rowHeight = 52.0;
  static const double rowGap = 4.0;
  static const double rowPitch = rowHeight + rowGap;
  static const double jobPadding = 3.0;
  static const double cornerRadius = 4.0;

  // Shift overlay colors
  static const _shiftColors = {
    'First': Color(0x0AFFFFFF),  // subtle white tint
    'Second': Color(0x00000000), // transparent (base)
    'Third': Color(0x080A84FF),  // subtle blue tint
  };

  GanttPainter({
    required this.data,
    required this.layout,
    required this.pixelsPerMinute,
    this.selectedJobIndex,
    this.hoveredProductionRunId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final visibleRect = canvas.getLocalClipBounds();

    // 1. Row backgrounds
    _drawRowBackgrounds(canvas, visibleRect);

    // 2. Shift band overlays (M2 gap fix)
    _drawShiftBands(canvas, visibleRect);

    // 3. Time grid
    _drawTimeGrid(canvas, visibleRect);

    // 4 & 5. Job blocks + labels
    _drawJobs(canvas, visibleRect);

    // 6. Now line
    _drawNowLine(canvas, size);
  }

  // ---- 1. Row Backgrounds ----

  void _drawRowBackgrounds(Canvas canvas, Rect visible) {
    for (var i = 0; i < layout.workCenterOrder.length; i++) {
      final top = i * rowPitch;
      if (top + rowPitch < visible.top || top > visible.bottom) continue;

      if (i.isOdd) {
        canvas.drawRect(
          Rect.fromLTWH(visible.left, top, visible.width, rowPitch),
          Paint()..color = const Color(0x08FFFFFF),
        );
      }
    }
  }

  // ---- 2. Shift Band Overlays (M2 gap fix) ----

  void _drawShiftBands(Canvas canvas, Rect visible) {
    if (data.shifts.isEmpty) return;

    for (final shift in data.shifts) {
      final shiftStart = DateTime.parse(shift.start);
      final shiftEnd = DateTime.parse(shift.end);
      final left =
          shiftStart.difference(layout.scheduleStart).inMinutes * pixelsPerMinute;
      final right =
          shiftEnd.difference(layout.scheduleStart).inMinutes * pixelsPerMinute;

      // Viewport culling
      if (right < visible.left || left > visible.right) continue;

      final color = _shiftColors[shift.shiftType] ?? const Color(0x00000000);
      if (color.a == 0) continue;

      canvas.drawRect(
        Rect.fromLTRB(left, visible.top, right, visible.bottom),
        Paint()..color = color,
      );
    }
  }

  // ---- 3. Time Grid ----

  void _drawTimeGrid(Canvas canvas, Rect visible) {
    final paint = Paint()
      ..color = const Color(0x15FFFFFF)
      ..strokeWidth = 0.5;

    final minutesPerGridLine = _adaptiveGridInterval();
    final startMinute = (visible.left / pixelsPerMinute).floor();
    final endMinute = (visible.right / pixelsPerMinute).ceil();

    for (var m = startMinute - (startMinute % minutesPerGridLine);
        m <= endMinute;
        m += minutesPerGridLine) {
      if (m < 0) continue;
      final x = m * pixelsPerMinute;
      canvas.drawLine(
        Offset(x, visible.top),
        Offset(x, visible.bottom),
        paint,
      );
    }
  }

  int _adaptiveGridInterval() {
    final pxPerHour = pixelsPerMinute * 60;
    if (pxPerHour > 200) return 60;    // Every hour
    if (pxPerHour > 50) return 240;    // Every 4 hours
    if (pxPerHour > 20) return 480;    // Every 8 hours (shift)
    return 1440;                        // Every day
  }

  // ---- 4 & 5. Job Blocks + Labels ----

  void _drawJobs(Canvas canvas, Rect visible) {
    for (var i = 0; i < data.jobs.length; i++) {
      final job = data.jobs[i];
      final rect = jobRect(job);

      // Viewport culling: skip off-screen jobs
      if (!rect.overlaps(visible)) continue;

      final color = ChartColors.forProduct(job.productId);
      final isSelected = i == selectedJobIndex;
      final isSameRun = job.productionRunId == hoveredProductionRunId;

      // Job block fill
      final rrect =
          RRect.fromRectAndRadius(rect, const Radius.circular(cornerRadius));
      final fillPaint = Paint()
        ..color = color.withValues(alpha: isSameRun ? 1.0 : 0.8);
      canvas.drawRRect(rrect, fillPaint);

      // Border
      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.0;
      canvas.drawRRect(rrect, borderPaint);

      // Label: stage name inside block (only if wide enough)
      if (rect.width > 40) {
        final tp = TextPainter(
          text: TextSpan(
            text: job.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          maxLines: 1,
          ellipsis: '\u2026',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: rect.width - 6);
        tp.paint(canvas, Offset(rect.left + 3, rect.top + 3));
      }

      // Duration text (below stage name, if block is tall + wide enough)
      if (rect.width > 60 && rect.height > 30) {
        final durationTp = TextPainter(
          text: TextSpan(
            text: '${job.durationMinutes}m',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9,
            ),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: rect.width - 6);
        durationTp.paint(canvas, Offset(rect.left + 3, rect.top + 16));
      }
    }
  }

  // ---- 6. Now Line ----

  void _drawNowLine(Canvas canvas, Size size) {
    final now = DateTime.now();
    if (now.isBefore(layout.scheduleStart) ||
        now.isAfter(layout.scheduleEnd)) {
      return;
    }

    final minutesFromStart =
        now.difference(layout.scheduleStart).inMinutes.toDouble();
    final x = minutesFromStart * pixelsPerMinute;
    final paint = Paint()
      ..color = const Color(0xFFEF4444) // red-500
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);

    // Small triangle indicator at top
    final path = Path()
      ..moveTo(x - 5, 0)
      ..lineTo(x + 5, 0)
      ..lineTo(x, 8)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFEF4444));
  }

  // ---- Coordinate helpers ----

  Rect jobRect(GanttJob job) {
    final jobStart = DateTime.parse(job.start);
    final minutesFromStart =
        jobStart.difference(layout.scheduleStart).inMinutes;
    final rowIdx = layout.workCenterIndex[job.row] ?? 0;

    final left = minutesFromStart * pixelsPerMinute;
    final top = rowIdx * rowPitch + jobPadding;
    final width =
        (job.durationMinutes * pixelsPerMinute).clamp(2.0, double.infinity);
    final height = rowHeight - 2 * jobPadding;

    return Rect.fromLTWH(left, top, width, height);
  }

  @override
  bool shouldRepaint(GanttPainter old) =>
      data != old.data ||
      pixelsPerMinute != old.pixelsPerMinute ||
      selectedJobIndex != old.selectedJobIndex ||
      hoveredProductionRunId != old.hoveredProductionRunId;
}
