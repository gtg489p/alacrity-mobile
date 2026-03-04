import 'package:flutter/material.dart';

class RagColors {
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFEAB308);
  static const red = Color(0xFFEF4444);

  /// Position a KPI value within the Pareto front range.
  /// Bottom 33% = green (best), middle = amber, top 33% = red (worst).
  /// All 8 KPIs are "lower is better".
  static Color fromPercentile(double percentile) {
    if (percentile <= 0.33) return green;
    if (percentile <= 0.66) return amber;
    return red;
  }

  /// Compute percentile for a single KPI value across the Pareto front.
  static double computePercentile(double value, double min, double max) {
    if (max == min) return 0.0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }
}
