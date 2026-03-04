class FgKpi {
  final double fgHoldingCost;
  final double gallonDays;

  const FgKpi({
    required this.fgHoldingCost,
    required this.gallonDays,
  });

  factory FgKpi.fromJson(Map<String, dynamic> json) => FgKpi(
        fgHoldingCost: (json['fg_holding_cost'] as num?)?.toDouble() ?? 0,
        gallonDays: (json['gallon_days'] as num?)?.toDouble() ?? 0,
      );
}

class FgSeriesPoint {
  final String timestamp;
  final int day;
  final double production;
  final double shipping;
  final double netChange;
  final double onHand;

  const FgSeriesPoint({
    required this.timestamp,
    required this.day,
    required this.production,
    required this.shipping,
    required this.netChange,
    required this.onHand,
  });

  factory FgSeriesPoint.fromJson(Map<String, dynamic> json) => FgSeriesPoint(
        timestamp: json['timestamp'] as String,
        day: (json['day'] as num).toInt(),
        production: (json['production'] as num?)?.toDouble() ?? 0,
        shipping: (json['shipping'] as num?)?.toDouble() ?? 0,
        netChange: (json['net_change'] as num?)?.toDouble() ?? 0,
        onHand: (json['on_hand'] as num?)?.toDouble() ?? 0,
      );
}

class FgProduct {
  final int productId;
  final String productName;
  final List<FgSeriesPoint> series;

  const FgProduct({
    required this.productId,
    required this.productName,
    required this.series,
  });

  factory FgProduct.fromJson(Map<String, dynamic> json) => FgProduct(
        productId: (json['product_id'] as num).toInt(),
        productName: json['product_name'] as String,
        series: (json['series'] as List)
            .map((e) => FgSeriesPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FgData {
  final int scheduleId;
  final FgKpi kpi;
  final List<FgProduct> products;

  const FgData({
    required this.scheduleId,
    required this.kpi,
    required this.products,
  });

  factory FgData.fromJson(Map<String, dynamic> json) => FgData(
        scheduleId: (json['schedule_id'] as num).toInt(),
        kpi: FgKpi.fromJson(json['kpi'] as Map<String, dynamic>),
        products: (json['products'] as List)
            .map((e) => FgProduct.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
