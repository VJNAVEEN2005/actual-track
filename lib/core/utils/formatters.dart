import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrency = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static final DateFormat _shortDateFormat = DateFormat('MMM d');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _shortTimeFormat = DateFormat('h:mm a');

  static String currency(double amount) {
    return _currencyFormat.format(amount);
  }

  static String compactCurrency(double amount) {
    return _compactCurrency.format(amount);
  }

  static String date(DateTime dateTime) {
    return _dateFormat.format(dateTime);
  }

  static String shortDate(DateTime dateTime) {
    return _shortDateFormat.format(dateTime);
  }

  static String monthYear(DateTime dateTime) {
    return _monthYearFormat.format(dateTime);
  }

  static String shortTime(DateTime dateTime) {
    return _shortTimeFormat.format(dateTime);
  }
}
