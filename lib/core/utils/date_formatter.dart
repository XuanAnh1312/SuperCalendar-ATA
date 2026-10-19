import 'package:flutter_application/core/utils/strings.dart';

const _weekdayLettersEn = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _weekdayShortEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _weekdayShortVi = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
const _weekdayNamesEn = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _weekdayNamesVi = [
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];
const _monthNamesEn = [
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

// Display names follow the UI language (AC-41).
List<String> get weekdayLetters =>
    AppStrings.vi ? _weekdayShortVi : _weekdayLettersEn;
List<String> get weekdayShort =>
    AppStrings.vi ? _weekdayShortVi : _weekdayShortEn;
List<String> get weekdayNames =>
    AppStrings.vi ? _weekdayNamesVi : _weekdayNamesEn;
List<String> get monthNames =>
    AppStrings.vi ? [for (var m = 1; m <= 12; m++) 'Tháng $m'] : _monthNamesEn;

String monthShort(int month) =>
    AppStrings.vi ? 'thg $month' : _monthNamesEn[month - 1].substring(0, 3);

/// `Monday, October 5`
String longDate(DateTime d) => AppStrings.vi
    ? '${weekdayNames[d.weekday - 1]}, ${d.day} tháng ${d.month}'
    : '${weekdayNames[d.weekday - 1]}, ${monthNames[d.month - 1]} ${d.day}';

/// `Mon, Oct 5`
String shortDate(DateTime d) => AppStrings.vi
    ? '${weekdayShort[d.weekday - 1]}, ${d.day}/${d.month}'
    : '${weekdayShort[d.weekday - 1]}, ${monthShort(d.month)} ${d.day}';

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
  return '$h:$m ${hour < 12 ? tr('AM') : tr('PM')}';
}

/// `Today`, `Tomorrow`, a weekday within the coming week, else `Oct 20`.
String relativeDay(DateTime day, DateTime today) {
  final diff = dateOnly(day).difference(dateOnly(today)).inDays;
  if (diff == 0) return tr('Today');
  if (diff == 1) return tr('Tomorrow');
  if (diff == -1) return tr('Yesterday');
  if (diff > 1 && diff < 7) return weekdayShort[day.weekday - 1];
  return AppStrings.vi
      ? '${day.day}/${day.month}'
      : '${monthShort(day.month)} ${day.day}';
}

/// `15 min`, `1 hour`, `2 hours`.
String formatDuration(int minutes) {
  if (minutes < 60) return trf('{n} min', {'n': minutes});
  final hours = minutes / 60;
  final text = hours == hours.roundToDouble()
      ? hours.round().toString()
      : hours.toStringAsFixed(1);
  return hours == 1
      ? trf('{n} hour', {'n': text})
      : trf('{n} hours', {'n': text});
}

/// `None`, `15 min before`, `1 hour before`.
String formatReminder(int? minutes) => minutes == null
    ? tr('None')
    : trf('{time} before', {'time': formatDuration(minutes)});
