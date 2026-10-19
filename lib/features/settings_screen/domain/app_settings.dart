/// Device-level preferences stored in the Settings screens (§5.2).
///
/// Kept in the [Collections.settings] collection, always under the key
/// [AppSettings.id].  A new [AppSettings] instance holds sensible defaults
/// so the app is fully usable before the user configures anything.
class AppSettings {
  AppSettings({
    this.themeMode = ThemeModeSetting.system,
    this.themeId = 'pastel_minimal',
    this.language = 'English',
    this.dateFormat = 'dd/MM/yyyy',
    this.timeFormat = TimeFormatSetting.automatic,
    this.weekStart = WeekStartSetting.monday,
    this.defaultEventDurationMinutes = 60,
    this.defaultReminderMinutes,
    this.defaultPriority,
    this.hideCompletedTasks = false,
    this.notificationsEnabled = false,
    this.notificationPermissionAsked = false,
    this.lockScreenEnabled = false,
    this.lockScreenHideDetails = false,
    this.quickNoteNotification = false,
    this.quickNoteAppend = true,
    this.useSystemCalendar = false,
    this.calendarPermissionAsked = false,
    this.calendarBannerDismissed = false,
    this.defaultCalendar = 'Personal',
    // Legacy / convenience flags
    this.darkMode = false,
    this.accentIndex,
    this.typography,
    this.seeded = false,
    this.onboarded = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    themeMode: ThemeModeSetting.values.firstWhere(
      (m) => m.name == json['themeMode'],
      orElse: () => ThemeModeSetting.system,
    ),
    themeId: json['themeId'] as String? ?? 'pastel_minimal',
    language: json['language'] as String? ?? 'English',
    dateFormat: json['dateFormat'] as String? ?? 'dd/MM/yyyy',
    timeFormat: TimeFormatSetting.values.firstWhere(
      (f) => f.name == json['timeFormat'],
      orElse: () => TimeFormatSetting.automatic,
    ),
    weekStart: WeekStartSetting.values.firstWhere(
      (w) => w.name == json['weekStart'],
      orElse: () => WeekStartSetting.monday,
    ),
    defaultEventDurationMinutes:
        json['defaultEventDurationMinutes'] as int? ?? 60,
    defaultReminderMinutes: json['defaultReminderMinutes'] as int?,
    defaultPriority: json['defaultPriority'] as String?,
    hideCompletedTasks: json['hideCompletedTasks'] as bool? ?? false,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
    notificationPermissionAsked:
        json['notificationPermissionAsked'] as bool? ?? false,
    lockScreenEnabled: json['lockScreenEnabled'] as bool? ?? false,
    lockScreenHideDetails: json['lockScreenHideDetails'] as bool? ?? false,
    quickNoteNotification: json['quickNoteNotification'] as bool? ?? false,
    quickNoteAppend: json['quickNoteAppend'] as bool? ?? true,
    useSystemCalendar: json['useSystemCalendar'] as bool? ?? false,
    calendarPermissionAsked: json['calendarPermissionAsked'] as bool? ?? false,
    calendarBannerDismissed: json['calendarBannerDismissed'] as bool? ?? false,
    defaultCalendar: json['defaultCalendar'] as String? ?? 'Personal',
    // Legacy
    darkMode: json['darkMode'] as bool? ?? false,
    accentIndex: json['accentIndex'] as int?,
    typography: json['typography'] as String?,
    seeded: json['seeded'] as bool? ?? false,
    // Installs from before onboarding existed skip it.
    onboarded: json['onboarded'] as bool? ?? json['seeded'] as bool? ?? false,
  );

  /// Key used to store the single settings document in [Collections.settings].
  static const id = 'app';

  // ── Appearance ────────────────────────────────────────────────────────────

  ThemeModeSetting themeMode;
  String themeId;

  /// Accent override; null keeps the selected theme's own primary colour.
  int? accentIndex;

  /// Typography override (VIP only); null keeps the theme's typography.
  String? typography;

  /// Shortcut: true when [themeMode] is [ThemeModeSetting.dark] OR
  /// [themeMode] is [ThemeModeSetting.system] and the OS is in dark mode.
  /// Written/read by [UserRepository] to avoid coupling to `MediaQuery`.
  bool darkMode;

  // ── Locale ────────────────────────────────────────────────────────────────

  String language;
  String dateFormat;
  TimeFormatSetting timeFormat;
  WeekStartSetting weekStart;

  // ── Calendar & Event defaults ─────────────────────────────────────────────

  /// Default length of a new event, in minutes.
  int defaultEventDurationMinutes;

  /// Default reminder lead time; null means no reminder by default.
  int? defaultReminderMinutes;

  /// Default priority for new tasks; null means [Task.priorityMedium].
  String? defaultPriority;
  bool hideCompletedTasks;

  // ── Notifications ─────────────────────────────────────────────────────────

  bool notificationsEnabled;
  bool notificationPermissionAsked;

  // ── Lock Screen ───────────────────────────────────────────────────────────

  bool lockScreenEnabled;

  /// When true the Lock Screen shows item counts instead of titles (AC-38).
  bool lockScreenHideDetails;

  /// Keeps an ongoing notification with Quick Note editing (FR-20).
  bool quickNoteNotification;

  /// FR-20.03: text typed in the notification is appended to the Quick Note
  /// (default) instead of replacing it.
  bool quickNoteAppend;

  // ── System Calendar ───────────────────────────────────────────────────────

  bool useSystemCalendar;
  bool calendarPermissionAsked;
  bool calendarBannerDismissed;
  String defaultCalendar;

  // ── Internal ──────────────────────────────────────────────────────────────

  /// True once the first-run sample data has been written.
  bool seeded;

  /// True once the first-run onboarding (FR-01) is finished.
  bool onboarded;

  Map<String, dynamic> toJson() => {
    'id': id,
    'themeMode': themeMode.name,
    'themeId': themeId,
    'language': language,
    'dateFormat': dateFormat,
    'timeFormat': timeFormat.name,
    'weekStart': weekStart.name,
    'defaultEventDurationMinutes': defaultEventDurationMinutes,
    'defaultReminderMinutes': defaultReminderMinutes,
    'defaultPriority': defaultPriority,
    'hideCompletedTasks': hideCompletedTasks,
    'notificationsEnabled': notificationsEnabled,
    'notificationPermissionAsked': notificationPermissionAsked,
    'lockScreenEnabled': lockScreenEnabled,
    'lockScreenHideDetails': lockScreenHideDetails,
    'quickNoteNotification': quickNoteNotification,
    'quickNoteAppend': quickNoteAppend,
    'useSystemCalendar': useSystemCalendar,
    'calendarPermissionAsked': calendarPermissionAsked,
    'calendarBannerDismissed': calendarBannerDismissed,
    'defaultCalendar': defaultCalendar,
    // Legacy
    'darkMode': darkMode,
    'accentIndex': accentIndex,
    'typography': typography,
    'seeded': seeded,
    'onboarded': onboarded,
  };
}

// ── Supporting enums ─────────────────────────────────────────────────────────

enum ThemeModeSetting { light, dark, system }

enum TimeFormatSetting { h12, h24, automatic }

enum WeekStartSetting { monday, sunday }
