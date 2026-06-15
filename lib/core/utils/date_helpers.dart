import 'package:intl/intl.dart';

/// Date formatting and grouping helpers used across the app.
class DateHelpers {
  static final DateFormat _monthDay = DateFormat('MMM d');
  static final DateFormat _monthDayYear = DateFormat('MMM d, yyyy');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _fullDateTime = DateFormat('MMM d, yyyy • h:mm a');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime dt) => _monthDay.format(dt);
  static String formatDateFull(DateTime dt) => _monthDayYear.format(dt);
  static String formatTime(DateTime dt) => _time.format(dt);
  static String formatDateTime(DateTime dt) => _fullDateTime.format(dt);
  static String formatIso(DateTime dt) => _isoDate.format(dt);

  /// "Today", "Yesterday", "This Week", "Earlier" bucket for grouping trips list.
  static String groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diffDays = today.difference(d).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';

    // This week (Mon-Sun)
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    if (d.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
      return 'This Week';
    }
    return 'Earlier';
  }

  /// Returns list of possible groups in display order.
  static const List<String> groupOrder = ['Today', 'Yesterday', 'This Week', 'Earlier'];

  static String formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  static String formatMonthYear(DateTime dt) => DateFormat('MMMM yyyy').format(dt);

  /// For PDF headers etc.
  static String formatRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return DateFormat('MMMM yyyy').format(start);
    }
    return '${_monthDayYear.format(start)} – ${_monthDayYear.format(end)}';
  }
}
