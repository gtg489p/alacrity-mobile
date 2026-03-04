class TruckKpi {
  final int numTrucks;
  final double fgHoldingCost;
  final double fgShippingCost;
  final double truckUtilizationPct;

  const TruckKpi({
    required this.numTrucks,
    required this.fgHoldingCost,
    required this.fgShippingCost,
    required this.truckUtilizationPct,
  });

  factory TruckKpi.fromJson(Map<String, dynamic> json) => TruckKpi(
        numTrucks: (json['num_trucks'] as num?)?.toInt() ?? 0,
        fgHoldingCost: (json['fg_holding_cost'] as num?)?.toDouble() ?? 0,
        fgShippingCost: (json['fg_shipping_cost'] as num?)?.toDouble() ?? 0,
        truckUtilizationPct:
            (json['truck_utilization_pct'] as num?)?.toDouble() ?? 0,
      );
}

class TruckSegment {
  final int? productId;
  final String productName;
  final double gallons;

  const TruckSegment({
    required this.productId,
    required this.productName,
    required this.gallons,
  });

  factory TruckSegment.fromJson(Map<String, dynamic> json) => TruckSegment(
        productId: (json['product_id'] as num?)?.toInt(),
        productName: json['product_name'] as String? ?? 'Unknown',
        gallons: (json['gallons'] as num?)?.toDouble() ?? 0,
      );
}

class TruckLoad {
  final String truckLabel;
  final List<TruckSegment> segments;
  final double loadGallons;
  final double unusedGallons;

  const TruckLoad({
    required this.truckLabel,
    required this.segments,
    required this.loadGallons,
    required this.unusedGallons,
  });

  factory TruckLoad.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? {};
    return TruckLoad(
      truckLabel: json['truck_label'] as String? ?? '',
      segments: (json['segments'] as List?)
              ?.map((e) => TruckSegment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      loadGallons: (totals['load_gallons'] as num?)?.toDouble() ?? 0,
      unusedGallons: (totals['unused_gallons'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TruckDay {
  final String date;
  final List<TruckLoad> trucks;

  const TruckDay({
    required this.date,
    required this.trucks,
  });

  factory TruckDay.fromJson(Map<String, dynamic> json) => TruckDay(
        date: json['date'] as String,
        trucks: (json['trucks'] as List?)
                ?.map((e) => TruckLoad.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class TruckCustomer {
  final int customerId;
  final String customerLabel;
  final List<TruckDay> days;

  const TruckCustomer({
    required this.customerId,
    required this.customerLabel,
    required this.days,
  });

  factory TruckCustomer.fromJson(Map<String, dynamic> json) => TruckCustomer(
        customerId: (json['customer_id'] as num).toInt(),
        customerLabel: json['customer_label'] as String? ?? '',
        days: (json['days'] as List?)
                ?.map((e) => TruckDay.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class TruckData {
  final int scheduleId;
  final int truckCapacity;
  final int departureHour;
  final TruckKpi kpi;
  final List<TruckCustomer> customers;

  const TruckData({
    required this.scheduleId,
    required this.truckCapacity,
    required this.departureHour,
    required this.kpi,
    required this.customers,
  });

  factory TruckData.fromJson(Map<String, dynamic> json) => TruckData(
        scheduleId: (json['schedule_id'] as num).toInt(),
        truckCapacity: (json['truck_capacity'] as num?)?.toInt() ?? 4000,
        departureHour: (json['departure_hour'] as num?)?.toInt() ?? 16,
        kpi: TruckKpi.fromJson(json['kpi'] as Map<String, dynamic>),
        customers: (json['customers'] as List)
            .map((e) => TruckCustomer.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Aggregated daily shipment data for chart rendering.
class DailyShipment {
  final String date;
  final Map<int, double> productGallons; // productId → gallons
  double get total => productGallons.values.fold(0.0, (a, b) => a + b);

  const DailyShipment({required this.date, required this.productGallons});
}
