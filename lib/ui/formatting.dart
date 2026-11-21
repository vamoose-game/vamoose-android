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

  /// A wait as [clock], rounded up to whole seconds so it shows 0:00 only
  /// once the wait is over, like the level clock.
  static String clockLeft(Duration left) => clock(
    Duration(
      seconds: left.isNegative
          ? 0
          : (left.inMicroseconds + Duration.microsecondsPerSecond - 1) ~/
                Duration.microsecondsPerSecond,
    ),
  );

  /// Seconds with tenths, like 7.4 s, for times under a minute.
  static String tenths(Duration duration) => duration.inSeconds < 60
      ? '${(duration.inMilliseconds / 1000).toStringAsFixed(1)} s'
      : clock(duration);

  static String countdown(Duration duration) =>
      '${_two(duration.inHours)}:${_two(duration.inMinutes % 60)}:${_two(duration.inSeconds % 60)}';

  static String grouped(int value) => value.abs() < 1000
      ? '$value'
      : '${value < 0 ? '-' : ''}${grouped(value.abs() ~/ 1000)},${(value.abs() % 1000).toString().padLeft(3, '0')}';

  static String plural(int count, String noun) =>
      '$count $noun${count == 1 ? '' : 's'}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
