/// Gantt chart data models.
///
/// Parsed from GET /gantt/?output_format=json&schedule_id={id}
/// These are plain Dart classes (no freezed/build_runner) for simplicity
/// and to avoid code-gen overhead for Phase 2.


// ---------------------------------------------------------------------------
// GanttTimeline
// ---------------------------------------------------------------------------

class GanttTimeline {
  final String start; // ISO datetime
  final String end;   // ISO datetime

  const GanttTimeline({required this.start, required this.end});

  factory GanttTimeline.fromJson(Map<String, dynamic> json) => GanttTimeline(
        start: json['start'] as String,
        end: json['end'] as String,
      );
}

// ---------------------------------------------------------------------------
// GanttJob
// ---------------------------------------------------------------------------

class GanttJob {
  final int? jobId;
  final String name;             // Stage: "mix", "cool", "pump", "hold", "fill"
  final String row;              // Work center: "m1-6000gal", "Line1-Piston"
  final String start;            // ISO datetime
  final String end;              // ISO datetime
  final int durationMinutes;
  final int productionRunId;
  final int productId;
  final double workCenterId;
  final bool isTankBusy;

  const GanttJob({
    this.jobId,
    required this.name,
    required this.row,
    required this.start,
    required this.end,
    required this.durationMinutes,
    required this.productionRunId,
    required this.productId,
    required this.workCenterId,
    required this.isTankBusy,
  });

  factory GanttJob.fromJson(Map<String, dynamic> json) => GanttJob(
        jobId: json['job_id'] as int?,
        name: json['name'] as String,
        row: json['row'] as String,
        start: json['start'] as String,
        end: json['end'] as String,
        durationMinutes: json['duration_minutes'] as int,
        productionRunId: json['production_run_id'] as int,
        productId: json['product_id'] as int,
        workCenterId: (json['work_center_id'] as num).toDouble(),
        isTankBusy: json['is_tank_busy'] as bool,
      );
}

// ---------------------------------------------------------------------------
// GanttShift — M2 gap fix (missing from original plan)
// ---------------------------------------------------------------------------

class GanttShift {
  final String start;         // ISO datetime
  final String end;           // ISO datetime
  final String shiftType;     // "First", "Second", "Third"
  final int shiftIntervalId;

  const GanttShift({
    required this.start,
    required this.end,
    required this.shiftType,
    required this.shiftIntervalId,
  });

  factory GanttShift.fromJson(Map<String, dynamic> json) => GanttShift(
        start: json['start'] as String,
        end: json['end'] as String,
        shiftType: json['shift_type'] as String? ?? 'First',
        shiftIntervalId: json['shift_interval_id'] as int? ?? 0,
      );

  /// Generate synthetic 8-hour shift bands across a timeline.
  /// Used when the API returns an empty shifts list.
  /// First shift: 06:00–14:00, Second: 14:00–22:00, Third: 22:00–06:00
  static List<GanttShift> generateForTimeline(DateTime start, DateTime end) {
    final shifts = <GanttShift>[];
    // Align to the start of the day at 06:00
    var cursor = DateTime(start.year, start.month, start.day, 6);
    if (cursor.isAfter(start)) {
      // Add a partial third shift from midnight to 06:00
      cursor = DateTime(start.year, start.month, start.day);
    } else {
      cursor = DateTime(start.year, start.month, start.day);
    }

    const shiftDefs = [
      (hour: 6, name: 'First'),
      (hour: 14, name: 'Second'),
      (hour: 22, name: 'Third'),
    ];

    var id = 1;
    var day = DateTime(start.year, start.month, start.day);
    while (day.isBefore(end.add(const Duration(days: 1)))) {
      for (final def in shiftDefs) {
        final shiftStart = DateTime(day.year, day.month, day.day, def.hour);
        final shiftEnd = def.name == 'Third'
            ? DateTime(day.year, day.month, day.day + 1, 6)
            : DateTime(
                day.year, day.month, day.day, def.hour + 8);

        // Only include shifts that overlap with the timeline
        if (shiftEnd.isBefore(start) || shiftStart.isAfter(end)) continue;

        shifts.add(GanttShift(
          start: shiftStart.toIso8601String(),
          end: shiftEnd.toIso8601String(),
          shiftType: def.name,
          shiftIntervalId: id++,
        ));
      }
      day = day.add(const Duration(days: 1));
    }
    return shifts;
  }
}

// ---------------------------------------------------------------------------
// GanttKpi
// ---------------------------------------------------------------------------

class GanttKpi {
  final double? makespanHours;
  final double? totalFlowTime;
  final double? totalTardiness;
  final double? throughputGallons;

  const GanttKpi({
    this.makespanHours,
    this.totalFlowTime,
    this.totalTardiness,
    this.throughputGallons,
  });

  factory GanttKpi.fromJson(Map<String, dynamic> json) => GanttKpi(
        makespanHours: (json['makespan_hours'] as num?)?.toDouble(),
        totalFlowTime: (json['total_flow_time'] as num?)?.toDouble(),
        totalTardiness: (json['total_tardiness'] as num?)?.toDouble(),
        throughputGallons: (json['throughput_gallons'] as num?)?.toDouble(),
      );
}

// ---------------------------------------------------------------------------
// GanttData — top-level response
// ---------------------------------------------------------------------------

class GanttData {
  final int scheduleId;
  final GanttTimeline timeline;
  final List<GanttJob> jobs;
  final List<GanttShift> shifts;
  final GanttKpi kpi;

  const GanttData({
    required this.scheduleId,
    required this.timeline,
    required this.jobs,
    required this.shifts,
    required this.kpi,
  });

  factory GanttData.fromJson(Map<String, dynamic> json) {
    final timeline = GanttTimeline.fromJson(json['timeline'] as Map<String, dynamic>);
    final jobs = (json['jobs'] as List)
        .map((j) => GanttJob.fromJson(j as Map<String, dynamic>))
        .toList();

    // Parse shifts from API; if empty, generate synthetic 8-hour shifts
    var shifts = (json['shifts'] as List?)
            ?.map((s) => GanttShift.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];
    if (shifts.isEmpty) {
      shifts = GanttShift.generateForTimeline(
        DateTime.parse(timeline.start),
        DateTime.parse(timeline.end),
      );
    }

    return GanttData(
      scheduleId: json['schedule_id'] as int,
      timeline: timeline,
      jobs: jobs,
      shifts: shifts,
      kpi: GanttKpi.fromJson(json['kpi'] as Map<String, dynamic>),
    );
  }
}

// ---------------------------------------------------------------------------
// GanttLayout — pre-computed layout data
// ---------------------------------------------------------------------------

class GanttLayout {
  final DateTime scheduleStart;
  final DateTime scheduleEnd;
  final int totalMinutes;
  final List<String> workCenterOrder;
  final Map<String, int> workCenterIndex; // row name → row index

  GanttLayout(GanttData data)
      : scheduleStart = DateTime.parse(data.timeline.start),
        scheduleEnd = DateTime.parse(data.timeline.end),
        totalMinutes = DateTime.parse(data.timeline.end)
            .difference(DateTime.parse(data.timeline.start))
            .inMinutes,
        workCenterOrder = _computeWorkCenterOrder(data.jobs),
        workCenterIndex = _computeWorkCenterIndex(data.jobs);

  static List<String> _computeWorkCenterOrder(List<GanttJob> jobs) {
    final seen = <String>{};
    return jobs.map((j) => j.row).where((r) => seen.add(r)).toList();
  }

  static Map<String, int> _computeWorkCenterIndex(List<GanttJob> jobs) {
    final order = _computeWorkCenterOrder(jobs);
    return {for (var i = 0; i < order.length; i++) order[i]: i};
  }

  int get rowCount => workCenterOrder.length;
}
