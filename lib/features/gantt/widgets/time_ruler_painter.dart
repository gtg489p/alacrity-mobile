import 'package:flutter/material.dart';

/// Paints the sticky time ruler at the top of the Gantt chart.
///
/// Adaptive tick intervals based on zoom level:
///  - >300 px/hour → 30 min ticks
///  - >150 px/hour → 1 hour ticks
///  - >50 px/hour  → 4 hour ticks
///  - >20 px/hour  → 8 hour ticks
///  - ≤20 px/hour  → 1 day ticks
class TimeRulerPainter extends CustomPainter {
  final double pixelsPerMinute;
  final DateTime scheduleStart;
  final double scrollOffsetX;

  static const double height = 40.0;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  TimeRulerPainter({
    required this.pixelsPerMinute,
    required this.scheduleStart,
    required this.scrollOffsetX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pxPerHour = pixelsPerMinute * 60;
    final textStyle = TextStyle(
      color: const Color(0xFFA1A1AA), // zinc-400
      fontSize: pxPerHour > 100 ? 11 : 10,
    );

    final minutesPerTick = _adaptiveTickInterval();
    final startMinute = (scrollOffsetX / pixelsPerMinute).floor();
    final endMinute = startMinute + (size.width / pixelsPerMinute).ceil();

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF09090B), // zinc-950
    );

    // Bottom border
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()
        ..color = const Color(0xFF3F3F46) // zinc-700
        ..strokeWidth = 0.5,
    );

    for (var m = startMinute - (startMinute % minutesPerTick);
        m <= endMinute;
        m += minutesPerTick) {
      if (m < 0) continue;
      final x = m * pixelsPerMinute - scrollOffsetX;
      if (x < -50 || x > size.width + 50) continue;

      // Tick mark
      canvas.drawLine(
        Offset(x, size.height - 8),
        Offset(x, size.height),
        Paint()
          ..color = const Color(0xFF3F3F46) // zinc-700
          ..strokeWidth = 1,
      );

      // Label
      final time = scheduleStart.add(Duration(minutes: m));
      final label = _formatTimeLabel(time, minutesPerTick);
      final tp = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - 24));
    }
  }

  int _adaptiveTickInterval() {
    final pxPerHour = pixelsPerMinute * 60;
    if (pxPerHour > 300) return 30;   // Every 30 min
    if (pxPerHour > 150) return 60;   // Every hour
    if (pxPerHour > 50) return 240;   // Every 4 hours
    if (pxPerHour > 20) return 480;   // Every 8 hours
    return 1440;                       // Every day
  }

  String _formatTimeLabel(DateTime time, int interval) {
    if (interval >= 1440) {
      // Day format: "Mon 3 Mar"
      final dayName = _dayNames[time.weekday - 1];
      final monthName = _monthNames[time.month - 1];
      return '$dayName ${time.day} $monthName';
    } else if (interval >= 480) {
      // Day + hour: "3/4 14:00"
      final hour = time.hour.toString().padLeft(2, '0');
      return '${time.month}/${time.day} $hour:00';
    } else {
      // Hour format: "14:00" or "14:30"
      final hour = time.hour.toString().padLeft(2, '0');
      final min = time.minute.toString().padLeft(2, '0');
      return '$hour:$min';
    }
  }

  @override
  bool shouldRepaint(TimeRulerPainter old) =>
      pixelsPerMinute != old.pixelsPerMinute ||
      scrollOffsetX != old.scrollOffsetX;
}
