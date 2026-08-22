import 'package:intl/intl.dart';

/// تنسيق الأرقام كعملة (مثال: 1,250 دج)
final _currencyFormat = NumberFormat.decimalPattern();

String formatCurrency(double value) {
  return '${_currencyFormat.format(value)} دج';
}

final _dateFormat = DateFormat('yyyy/MM/dd - HH:mm');

String formatDate(DateTime date) {
  return _dateFormat.format(date);
}
