import 'package:flutter/material.dart';

class ChartColors {
  static const Map<int, Color> productColors = {
    30: Color(0xFF3B82F6),
    31: Color(0xFF10B981),
    32: Color(0xFFF59E0B),
    33: Color(0xFF8B5CF6),
    34: Color(0xFFEF4444),
  };

  static const List<Color> palette = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFFF97316),
    Color(0xFFEC4899),
  ];

  static const Map<String, Color> objectiveColors = {
    'tardiness_days': Color(0xFFEF4444),
    'labor_cost': Color(0xFF3B82F6),
    'makespan_days': Color(0xFF10B981),
    'flowtime_days': Color(0xFF8B5CF6),
    'fg_holding_cost': Color(0xFFF59E0B),
    'material_holding_cost': Color(0xFF06B6D4),
    'restock_cost': Color(0xFFF97316),
    'fg_shipping_cost': Color(0xFFEC4899),
    'chebyshev_radius': Color(0xFF71717A),
    'sat': Color(0xFF71717A),
  };

  static Color forProduct(int productId) =>
      productColors[productId] ?? const Color(0xFF71717A);
}
