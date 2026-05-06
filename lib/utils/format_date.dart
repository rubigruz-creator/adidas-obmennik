import 'package:intl/intl.dart';

String formatRelativeDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'только что';
    if (diff.inMinutes < 60) {
      final min = diff.inMinutes;
      return '$min ${_minutePlural(min)} назад';
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '$hours ${_hourPlural(hours)} назад';
    }
    if (diff.inDays == 1) return 'вчера';
    if (diff.inDays < 7) {
      return '${diff.inDays} ${_dayPlural(diff.inDays)} назад';
    }
    return DateFormat('d MMM', 'ru').format(date);
  } catch (e) {
    return dateString;
  }
}

String _minutePlural(int n) {
  if (n % 10 == 1 && n % 100 != 11) return 'минуту';
  if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) return 'минуты';
  return 'минут';
}

String _hourPlural(int n) {
  if (n % 10 == 1 && n % 100 != 11) return 'час';
  if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) return 'часа';
  return 'часов';
}

String _dayPlural(int n) {
  if (n % 10 == 1 && n % 100 != 11) return 'день';
  if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) return 'дня';
  return 'дней';
}