/// WIP (Work In Progress) curve models.
///
/// Derived from Gantt data — counts concurrent jobs over time.

class WipPoint {
  final DateTime time;
  final int concurrentJobs;
  final List<String> activeJobNames;

  const WipPoint({
    required this.time,
    required this.concurrentJobs,
    required this.activeJobNames,
  });
}

class WipData {
  final List<WipPoint> points;
  final int peakWip;
  final DateTime peakTime;
  final int scheduleId;

  const WipData({
    required this.points,
    required this.peakWip,
    required this.peakTime,
    required this.scheduleId,
  });
}
