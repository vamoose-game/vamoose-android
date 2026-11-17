extension CalendarDay on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  DateTime addDays(int days) => DateTime(year, month, day + days);

  DateTime get startOfWeek => addDays(1 - weekday);

  int daysUntil(DateTime other) => DateTime.utc(
    other.year,
    other.month,
    other.day,
  ).difference(DateTime.utc(year, month, day)).inDays;

  String get dayKey =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}
