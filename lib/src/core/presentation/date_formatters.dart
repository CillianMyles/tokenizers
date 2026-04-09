const _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const _weekdayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Formats a date as `Sunday, April 5`.
String formatLongDate(DateTime date) {
  return '${_weekdayNames[date.weekday - 1]}, '
      '${_monthNames[date.month - 1]} ${date.day}';
}

/// Formats a time as `08:30`.
String formatTime(DateTime dateTime) {
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Formats a date as `Apr 5, 2026`.
String formatShortDate(DateTime date) {
  return '${_monthNames[date.month - 1].substring(0, 3)} ${date.day}, '
      '${date.year}';
}

/// Formats a date and time for compact history display.
String formatDayAndTime(DateTime dateTime) {
  return '${formatLongDate(dateTime)} • ${formatTime(dateTime)}';
}
