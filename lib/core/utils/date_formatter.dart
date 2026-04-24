import 'package:intl/intl.dart';

class DateFormatter {
  static String short(DateTime date) => DateFormat('MMM d').format(date);
  static String full(DateTime date) => DateFormat('MMM d, y').format(date);
}
