class ShiftEntry {
  final int shiftIntervalId;
  final String typeName;
  final bool active;
  final String intervalStart;
  final String intervalEnd;
  final double durationHours;
  final double actualBodies;
  final double requiredBodies;
  final double actualHours;
  final double requiredHours;
  final double laborCostTotal;
  final double utilization;

  const ShiftEntry({
    required this.shiftIntervalId,
    required this.typeName,
    required this.active,
    required this.intervalStart,
    required this.intervalEnd,
    required this.durationHours,
    required this.actualBodies,
    required this.requiredBodies,
    required this.actualHours,
    required this.requiredHours,
    required this.laborCostTotal,
    required this.utilization,
  });

  factory ShiftEntry.fromJson(Map<String, dynamic> json) => ShiftEntry(
        shiftIntervalId: (json['shift_interval_id'] as num).toInt(),
        typeName: json['type_name'] as String? ?? '',
        active: json['active'] as bool? ?? true,
        intervalStart: json['interval_start'] as String,
        intervalEnd: json['interval_end'] as String,
        durationHours: (json['duration_hours'] as num?)?.toDouble() ?? 0,
        actualBodies: (json['actual_bodies'] as num?)?.toDouble() ?? 0,
        requiredBodies: (json['required_bodies'] as num?)?.toDouble() ?? 0,
        actualHours: (json['actual_hours'] as num?)?.toDouble() ?? 0,
        requiredHours: (json['required_hours'] as num?)?.toDouble() ?? 0,
        laborCostTotal: (json['labor_cost_total'] as num?)?.toDouble() ?? 0,
        utilization:
            (json['utilization_actual_over_requirement'] as num?)?.toDouble() ??
                0,
      );

  bool get hasShortage => actualBodies < requiredBodies && requiredBodies > 0;
}

class StaffData {
  final int scheduleId;
  final int count;
  final double totalLaborCost;
  final double laborCostPerGallon;
  final double throughputGallons;
  final List<ShiftEntry> shifts;

  const StaffData({
    required this.scheduleId,
    required this.count,
    required this.totalLaborCost,
    required this.laborCostPerGallon,
    required this.throughputGallons,
    required this.shifts,
  });

  factory StaffData.fromJson(Map<String, dynamic> json) => StaffData(
        scheduleId: (json['schedule_id'] as num).toInt(),
        count: (json['count'] as num?)?.toInt() ?? 0,
        totalLaborCost: (json['total_labor_cost'] as num?)?.toDouble() ?? 0,
        laborCostPerGallon:
            (json['labor_cost_per_gallon'] as num?)?.toDouble() ?? 0,
        throughputGallons:
            (json['throughput_gallons'] as num?)?.toDouble() ?? 0,
        shifts: (json['shifts'] as List)
            .map((e) => ShiftEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  List<ShiftEntry> get activeShifts =>
      shifts.where((s) => s.actualBodies > 0 || s.requiredBodies > 0).toList();
}
