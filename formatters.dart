import 'package:intl/intl.dart';

/// تنسيق الأرقام كعملة (مثال: 1,250 دج) — عدّل رمز العملة حسب بلدك
final _currencyFormat = NumberFormat.decimalPattern('ar');

String formatCurrency(double value) {
  return '${_currencyFormat.format(value)} دج';
}

final _dateFormat = DateFormat('yyyy/MM/dd - HH:mm', 'ar');

String formatDate(DateTime date) {
  return _dateFormat.format(date);
}
