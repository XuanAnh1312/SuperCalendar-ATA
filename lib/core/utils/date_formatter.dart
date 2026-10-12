const weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const monthNames = [
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

String monthShort(int month) => monthNames[month - 1].substring(0, 3);

/// `Monday, October 5`
String longDate(DateTime d) =>
    '${weekdayNames[d.weekday - 1]}, ${monthNames[d.month - 1]} ${d.day}';

/// `Mon, Oct 5`
String shortDate(DateTime d) =>
    '${weekdayShort[d.weekday - 1]}, ${monthShort(d.month)} ${d.day}';

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// [d] with the time of day stripped.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Minutes since midnight as `14:00`.
String formatMinutes(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

/// Minutes since midnight as `4:00 PM`.
String formatClock(int minutes) {
  final hour = minutes ~/ 60;
  final m = (minutes % 60).toString().padLeft(2, '0');
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h:$m ${hour < 12 ? 'AM' : 'PM'}';
}

/// `Today`, `Tomorrow`, a weekday within the coming week, else `Oct 20`.
String relativeDay(DateTime day, DateTime today) {
  final diff = dateOnly(day).difference(dateOnly(today)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  if (diff > 1 && diff < 7) return weekdayShort[day.weekday - 1];
  return '${monthShort(day.month)} ${day.day}';
}

/// `15 min`, `1 hour`, `2 hours`.
String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes / 60;
  final text = hours == hours.roundToDouble()
      ? hours.round().toString()
      : hours.toStringAsFixed(1);
  return '$text ${hours == 1 ? 'hour' : 'hours'}';
}

/// `None`, `15 min before`, `1 hour before`.
String formatReminder(int? minutes) =>
    minutes == null ? 'None' : '${formatDuration(minutes)} before';
