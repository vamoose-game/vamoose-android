abstract final class Formatting {
  static const List<String> _weekdaysShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const List<String> _weekdaysLong = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String weekdayShort(DateTime day) => _weekdaysShort[day.weekday - 1];

  static String longDate(DateTime day) =>
      '${_weekdaysLong[day.weekday - 1]}, ${_months[day.month - 1]} ${day.day}';

  static String clock(Duration duration) =>
      '${duration.inMinutes}:${_two(duration.inSeconds % 60)}';

  static String countdown(Duration duration) =>
      '${_two(duration.inHours)}:${_two(duration.inMinutes % 60)}:${_two(duration.inSeconds % 60)}';

  static String plural(int count, String noun) =>
      '$count $noun${count == 1 ? '' : 's'}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
