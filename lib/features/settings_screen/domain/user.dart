import 'package:flutter_application/core/data/repository.dart';

class User {
  User({
    required this.id,
    required this.name,
    this.isVip = false,
    this.selectedThemeId = 'pastel_minimal',
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    isVip: json['isVip'] as bool? ?? false,
    selectedThemeId: json['selectedThemeId'] as String? ?? 'pastel_minimal',
    createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
  );

  final String id;
  String name;
  bool isVip;
  String selectedThemeId;
  final DateTime createdAt;

  String get firstName => name.split(' ').first;

  String get initials => name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isVip': isVip,
    'selectedThemeId': selectedThemeId,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Device-level preferences from the Settings screens.
class AppSettings {
  AppSettings({
    this.darkMode = false,
    this.accentIndex,
    this.typography,
    this.notificationsEnabled = false,
    this.notificationPermissionAsked = false,
    this.defaultReminderMinutes = 15,
    this.lockScreenNotification = false,
    this.useSystemCalendar = false,
    this.calendarPermissionAsked = false,
    this.calendarBannerDismissed = false,
    this.defaultCalendar = 'Personal',
    this.language = 'English',
    this.timeFormat = 'Automatic',
    this.seeded = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    darkMode: json['darkMode'] as bool? ?? false,
    accentIndex: json['accentIndex'] as int?,
    typography: json['typography'] as String?,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
    notificationPermissionAsked:
        json['notificationPermissionAsked'] as bool? ?? false,
    defaultReminderMinutes: json['defaultReminderMinutes'] as int? ?? 15,
    lockScreenNotification: json['lockScreenNotification'] as bool? ?? false,
    useSystemCalendar: json['useSystemCalendar'] as bool? ?? false,
    calendarPermissionAsked: json['calendarPermissionAsked'] as bool? ?? false,
    calendarBannerDismissed: json['calendarBannerDismissed'] as bool? ?? false,
    defaultCalendar: json['defaultCalendar'] as String? ?? 'Personal',
    language: json['language'] as String? ?? 'English',
    timeFormat: json['timeFormat'] as String? ?? 'Automatic',
    seeded: json['seeded'] as bool? ?? false,
  );

  static const id = 'app';

  bool darkMode;

  /// Accent override; null keeps the selected theme's own primary color.
  int? accentIndex;

  /// Typography override (VIP); null keeps the selected theme's typography.
  String? typography;

  bool notificationsEnabled;
  bool notificationPermissionAsked;
  int defaultReminderMinutes;

  /// Keeps today's schedule and next to-do in a lock screen notification.
  bool lockScreenNotification;

  bool useSystemCalendar;
  bool calendarPermissionAsked;
  bool calendarBannerDismissed;
  String defaultCalendar;
  String language;
  String timeFormat;

  /// True once the first-run sample data has been written.
  bool seeded;

  Map<String, dynamic> toJson() => {
    'id': id,
    'darkMode': darkMode,
    'accentIndex': accentIndex,
    'typography': typography,
    'notificationsEnabled': notificationsEnabled,
    'notificationPermissionAsked': notificationPermissionAsked,
    'defaultReminderMinutes': defaultReminderMinutes,
    'lockScreenNotification': lockScreenNotification,
    'useSystemCalendar': useSystemCalendar,
    'calendarPermissionAsked': calendarPermissionAsked,
    'calendarBannerDismissed': calendarBannerDismissed,
    'defaultCalendar': defaultCalendar,
    'language': language,
    'timeFormat': timeFormat,
    'seeded': seeded,
  };
}
