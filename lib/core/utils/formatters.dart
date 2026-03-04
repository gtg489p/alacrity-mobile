import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
final _numberFormat = NumberFormat('#,##0');

String formatKpiValue(double value, String unit) {
  switch (unit) {
    case 'USD':
      return _currencyFormat.format(value);
    case 'days':
      return '${value.toStringAsFixed(1)}d';
    case 'gallons':
      return '${_numberFormat.format(value)} gal';
    case 'minutes':
      return '${_numberFormat.format(value)} min';
    default:
      return _numberFormat.format(value);
  }
}

String formatMinutesToDays(double minutes) {
  final days = minutes / 1440;
  return '${days.toStringAsFixed(1)}d';
}
