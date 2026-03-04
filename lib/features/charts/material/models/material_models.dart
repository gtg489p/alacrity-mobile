class MaterialKpi {
  final double materialHoldingCost;
  final double restockCost;
  final int numRestocks;
  final int numStockouts;

  const MaterialKpi({
    required this.materialHoldingCost,
    required this.restockCost,
    required this.numRestocks,
    required this.numStockouts,
  });

  factory MaterialKpi.fromJson(Map<String, dynamic> json) => MaterialKpi(
        materialHoldingCost:
            (json['material_holding_cost'] as num?)?.toDouble() ?? 0,
        restockCost: (json['restock_cost'] as num?)?.toDouble() ?? 0,
        numRestocks: (json['num_restocks'] as num?)?.toInt() ?? 0,
        numStockouts: (json['num_stockouts'] as num?)?.toInt() ?? 0,
      );
}

class MaterialSeriesPoint {
  final String timestamp;
  final int minute;
  final double delta;
  final double balance;
  final String type;

  const MaterialSeriesPoint({
    required this.timestamp,
    required this.minute,
    required this.delta,
    required this.balance,
    required this.type,
  });

  factory MaterialSeriesPoint.fromJson(Map<String, dynamic> json) =>
      MaterialSeriesPoint(
        timestamp: json['timestamp'] as String,
        minute: (json['minute'] as num).toInt(),
        delta: (json['delta'] as num).toDouble(),
        balance: (json['balance'] as num).toDouble(),
        type: json['type'] as String,
      );
}

class MaterialEntry {
  final int materialId;
  final String materialName;
  final List<MaterialSeriesPoint> series;

  const MaterialEntry({
    required this.materialId,
    required this.materialName,
    required this.series,
  });

  factory MaterialEntry.fromJson(Map<String, dynamic> json) => MaterialEntry(
        materialId: (json['material_id'] as num).toInt(),
        materialName: json['material_name'] as String,
        series: (json['series'] as List)
            .map((e) =>
                MaterialSeriesPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class MaterialData {
  final int scheduleId;
  final MaterialKpi kpi;
  final List<MaterialEntry> materials;

  const MaterialData({
    required this.scheduleId,
    required this.kpi,
    required this.materials,
  });

  factory MaterialData.fromJson(Map<String, dynamic> json) => MaterialData(
        scheduleId: (json['schedule_id'] as num).toInt(),
        kpi: MaterialKpi.fromJson(json['kpi'] as Map<String, dynamic>),
        materials: (json['materials'] as List)
            .map((e) => MaterialEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
