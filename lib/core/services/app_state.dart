import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/core/services/seed_data.dart';
import 'package:flutter_application/core/services/system_calendar_service.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/features/calendar/data/event_repository.dart';
import 'package:flutter_application/features/calendar/data/goal_repository.dart';
import 'package:flutter_application/features/calendar/data/habit_repository.dart';
import 'package:flutter_application/features/calendar/domain/goal.dart';
import 'package:flutter_application/features/dashboard/data/layout_repository.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';
import 'package:flutter_application/features/note/data/note_repository.dart';
import 'package:flutter_application/features/note/domain/note.dart';
import 'package:flutter_application/features/settings_screen/data/user_repository.dart';
import 'package:flutter_application/features/settings_screen/domain/user.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_application/features/todo/data/task_repository.dart';
import 'package:flutter_application/features/vip/data/template_repository.dart';
import 'package:flutter_application/features/vip/domain/template.dart';

/// Wires the feature repositories to the one local database and holds the
/// app-level state that spans features: navigation, the active theme, VIP
/// status, notifications and the system calendar connection.
class AppState extends ChangeNotifier {
  AppState({
    required this.store,
    NotificationService? notifications,
    SystemCalendarService? systemCalendar,
    DateTime Function()? clock,
  }) : notifications = notifications ?? NoopNotificationService(),
       systemCalendar = systemCalendar ?? FakeSystemCalendarService(),
       clock = clock ?? DateTime.now {
    tasks = TaskRepository(store, clock: this.clock);
    eventExceptions = EventExceptionRepository(store);
    events = EventRepository(store, exceptions: eventExceptions);
    habits = HabitRepository(store);
    habitOccurrences = HabitOccurrenceRepository(store);
    goals = GoalRepository(store, clock: this.clock);
    notes = NoteRepository(store, clock: this.clock);
    account = UserRepository(store, clock: this.clock);
    templates = TemplateRepository(store, clock: this.clock);
    layouts = LayoutRepository(store);
    // Wire companions so deleteScope / updateRepeatRule enforce BR-10 / BR-17.
    habits.attachOccurrences(habitOccurrences);
    selectedDay = today;
    for (final repository in _repositories) {
      repository.addListener(_onDataChanged);
    }
  }

  /// Price of the (mock) VIP subscription, in VND.
  static const vipPrice = 49000;

  final DocumentStore store;
  final NotificationService notifications;
  final SystemCalendarService systemCalendar;
  final DateTime Function() clock;

  late final TaskRepository tasks;
  late final EventRepository events;
  late final EventExceptionRepository eventExceptions;
  late final HabitRepository habits;
  late final HabitOccurrenceRepository habitOccurrences;
  late final GoalRepository goals;
  late final NoteRepository notes;
  late final UserRepository account;
  late final TemplateRepository templates;
  late final LayoutRepository layouts;

  List<ChangeNotifier> get _repositories => [
    tasks,
    events,
    eventExceptions,
    habits,
    habitOccurrences,
    goals,
    notes,
    account,
    templates,
    layouts,
  ];

  bool loaded = false;

  DateTime get now => clock();
  DateTime get today => dateOnly(clock());

  User get user => account.user;
  AppSettings get settings => account.settings;
  bool get isVip => user.isVip;

  /// BR-06: every [VipFeature] is open to VIP users only.
  bool canAccess(VipFeature feature) => isVip;

  /// First day of the week for the Calendar widgets.
  WeekStartSetting get weekStart => settings.weekStart;

  /// [DateTime.monday] or [DateTime.sunday], from [weekStart].
  int get firstWeekday =>
      weekStart == WeekStartSetting.sunday ? DateTime.sunday : DateTime.monday;

  /// First day of the week that contains [day].
  DateTime weekStartOf(DateTime day) =>
      DateTime(day.year, day.month, day.day - (day.weekday - firstWeekday) % 7);

  void setWeekStart(WeekStartSetting value) =>
      account.updateSettings((s) => s.weekStart = value);

  // ---- Loading ------------------------------------------------------------

  /// Reads everything from the device, writing the sample data on first run.
  Future<void> load() async {
    await _loadRepositories();
    if (!settings.seeded) {
      seedSampleData(this);
      account.updateSettings((s) => s.seeded = true);
      await flush();
    }
    selectedDay = today;
    AppStrings.vi = settings.language == AppStrings.vietnamese;
    applyTheme();
    loaded = true;
    notifyListeners();
    if (settings.useSystemCalendar) unawaited(refreshSystemCalendar());
    _queueSync();
  }

  /// Picks up changes written by a notification action while the UI was
  /// alive in another isolate.
  Future<void> reloadFromDisk() async {
    if (!loaded) return;
    await tasks.load();
    await notes.load();
  }

  Future<void> _loadRepositories() async {
    await account.load();
    await templates.load();
    await layouts.load();
    await tasks.load();
    await events.load();
    await eventExceptions.load();
    await habits.load();
    await habitOccurrences.load();
    await goals.load();
    await notes.load();
  }

  /// Completes when every queued write has reached the database.
  Future<void> flush() async {
    await Future.wait([
      tasks.flush(),
      events.flush(),
      eventExceptions.flush(),
      habits.flush(),
      habitOccurrences.flush(),
      goals.flush(),
      notes.flush(),
      account.flush(),
      templates.flush(),
      layouts.flush(),
    ]);
  }

  void _onDataChanged() {
    notifyListeners();
    _queueSync();
  }

  @override
  void dispose() {
    for (final repository in _repositories) {
      repository.removeListener(_onDataChanged);
    }
    super.dispose();
  }

  // ---- Onboarding (FR-01) -------------------------------------------------

  /// Saves the name typed on first run (AC-04) and marks onboarding done.
  void finishOnboarding(String name) {
    account.rename(name);
    account.updateSettings((s) => s.onboarded = true);
  }

  // ---- Navigation ---------------------------------------------------------

  int tab = 0;
  bool weekView = false;
  late DateTime selectedDay;

  void setTab(int value) {
    if (tab == value) return;
    tab = value;
    notifyListeners();
  }

  void setWeekView(bool value) {
    weekView = value;
    notifyListeners();
  }

  void selectDay(DateTime day) {
    selectedDay = dateOnly(day);
    notifyListeners();
  }

  // ---- Theme --------------------------------------------------------------

  /// Bumped whenever the applied theme changes; the app root listens to it
  /// and repaints everything.
  final ValueNotifier<int> themeRevision = ValueNotifier(0);

  AppThemeData get selectedTheme => templates.theme(user.selectedThemeId);

  /// [AppSettings.themeMode] in the form [MaterialApp.themeMode] expects.
  ThemeMode get themeMode => switch (settings.themeMode) {
    ThemeModeSetting.light => ThemeMode.light,
    ThemeModeSetting.dark => ThemeMode.dark,
    ThemeModeSetting.system => ThemeMode.system,
  };

  /// True when the dark palette is applied (resolved from [themeMode]).
  bool get darkMode => settings.darkMode;

  bool get _resolvedDark => switch (settings.themeMode) {
    ThemeModeSetting.light => false,
    ThemeModeSetting.dark => true,
    ThemeModeSetting.system =>
      PlatformDispatcher.instance.platformBrightness == Brightness.dark,
  };

  /// Pushes the user's theme choices into [AppTheme]. Call again when the OS
  /// brightness changes so [ThemeModeSetting.system] follows it.
  void applyTheme() {
    final dark = _resolvedDark;
    if (settings.darkMode != dark) {
      account.updateSettings((s) => s.darkMode = dark);
    }
    final accent = settings.accentIndex;
    AppTheme.apply(
      selectedTheme,
      dark: dark,
      accent: accent == null ? null : AppColors.accent(accent),
      // Custom typography is a VIP feature; a lapsed VIP falls back.
      typography: canAccess(VipFeature.customTypography)
          ? settings.typography
          : null,
    );
    themeRevision.value++;
  }

  /// Switches the UI language at once (AC-41); every screen is rebuilt.
  void setLanguage(String language) {
    account.updateSettings((s) => s.language = language);
    AppStrings.vi = language == AppStrings.vietnamese;
    themeRevision.value++;
  }

  void setThemeMode(ThemeModeSetting mode) {
    account.updateSettings((s) => s.themeMode = mode);
    applyTheme();
  }

  void selectTheme(String themeId) {
    account.selectTheme(themeId);
    // A theme brings its own primary color, so drop the accent override.
    account.updateSettings((s) => s.accentIndex = null);
    applyTheme();
  }

  /// The Light/Dark switch: picks an explicit mode, leaving "system".
  void setDarkMode(bool value) =>
      setThemeMode(value ? ThemeModeSetting.dark : ThemeModeSetting.light);

  void setAccent(int? index) {
    account.updateSettings((s) => s.accentIndex = index);
    applyTheme();
  }

  /// VIP only. Returns false (and changes nothing) for a Free user.
  bool setTypography(String? typography) {
    if (!canAccess(VipFeature.customTypography)) return false;
    account.updateSettings((s) => s.typography = typography);
    applyTheme();
    return true;
  }

  // ---- VIP & mock payment -------------------------------------------------

  /// Finishes the test payment for the VIP subscription. No real money moves;
  /// only a [PaymentResult.success] grants VIP.
  void completeVipPayment(PaymentResult result) {
    templates.recordPurchase(
      userId: user.id,
      productType: ProductType.vip,
      productId: Purchase.vipProductId,
      price: vipPrice,
      result: result,
    );
    if (result == PaymentResult.success) {
      account.setVip(true);
      applyTheme();
    }
  }

  /// Back to Free, so the gating can be tested again. VIP-only looks fall
  /// back to the free defaults (AC-34).
  void cancelVip() {
    account.setVip(false);
    final themeId = user.selectedThemeId;
    final allowed =
        builtInThemes.any((t) => t.id == themeId) ||
        templates.templates.any(
          (t) => t.themeData.id == themeId && ownsTemplate(t),
        );
    if (!allowed) account.selectTheme(builtInThemes.first.id);
    for (final id in [ScreenLayout.home, ScreenLayout.lock]) {
      final layout = layouts.of(id);
      if (layout.preset == ScreenLayout.presetCustom) {
        layouts.applyPreset(id, ScreenLayout.presetDefault);
      }
      if (layout.backgroundPath != null) layouts.setBackground(id, null);
    }
    applyTheme();
  }

  // ---- Templates ----------------------------------------------------------

  /// A user's own templates need VIP (Template Studio); others need to be
  /// free or bought.
  bool ownsTemplate(Template template) => template.creatorId == user.id
      ? canAccess(VipFeature.themeBuilder)
      : templates.owns(user.id, template);

  /// Finishes the test payment for [template]; success unlocks it.
  void completeTemplatePayment(Template template, PaymentResult result) {
    templates.recordPurchase(
      userId: user.id,
      productType: ProductType.template,
      productId: template.id,
      price: template.price,
      result: result,
    );
  }

  /// Applies an owned template. Returns false if it is not unlocked.
  bool applyTemplate(Template template) {
    if (!ownsTemplate(template)) return false;
    templates.saveTheme(template.themeData);
    selectTheme(template.themeData.id);
    return true;
  }

  bool isTemplateApplied(Template template) =>
      user.selectedThemeId == template.themeData.id;

  /// VIP only: saves a template built in the Template Studio. Returns null
  /// for a Free user.
  Template? createTemplate({
    required String name,
    required String description,
    required int price,
    required String preview,
    required AppThemeData theme,
    String? id,
  }) {
    if (!canAccess(VipFeature.themeBuilder)) return null;
    final templateId = id ?? newId('template');
    final existing = templates.byId(templateId);
    final template = Template(
      id: templateId,
      name: name.trim().isEmpty ? 'Untitled' : name.trim(),
      description: description.trim(),
      creatorId: user.id,
      price: price,
      preview: preview,
      themeData: theme.copyWith(id: 'theme_$templateId', name: name.trim()),
      published: existing?.published ?? false,
    );
    templates.saveTemplate(template);
    if (isTemplateApplied(template)) applyTheme();
    return template;
  }

  /// VIP only: lists (or unlists) one of the user's templates in the store.
  bool publishTemplate(Template template, {bool published = true}) {
    if (!canAccess(VipFeature.publishTemplates) ||
        template.creatorId != user.id) {
      return false;
    }
    templates.setPublished(template, published);
    return true;
  }

  // ---- Notifications ------------------------------------------------------

  bool _syncQueued = false;

  /// Turns reminders on, asking for the system permission the first time.
  /// Returns false when the permission is denied.
  Future<bool> enableNotifications() async {
    var granted = await notifications.hasPermission();
    if (!granted) granted = await notifications.requestPermission();
    account.updateSettings((s) {
      s.notificationPermissionAsked = true;
      s.notificationsEnabled = granted;
    });
    return granted;
  }

  Future<void> disableNotifications() async {
    account.updateSettings((s) {
      s.notificationsEnabled = false;
      s.lockScreenEnabled = false;
    });
    await notifications.cancelReminders();
    await notifications.hideLockScreen();
  }

  /// Called when the user saves something with a reminder. Asks for the
  /// notification permission once; never again after a refusal.
  Future<void> ensureRemindersCanFire() async {
    if (settings.notificationsEnabled || settings.notificationPermissionAsked) {
      return;
    }
    await enableNotifications();
  }

  void setDefaultReminder(int minutes) =>
      account.updateSettings((s) => s.defaultReminderMinutes = minutes);

  /// Shows today's schedule and next to-do on the lock screen. Needs
  /// notifications to be on; returns false if they could not be enabled.
  Future<bool> setLockScreenNotification(bool value) async {
    if (value && !settings.notificationsEnabled) {
      if (!await enableNotifications()) return false;
    }
    account.updateSettings((s) => s.lockScreenEnabled = value);
    if (!value) await notifications.hideLockScreen();
    return true;
  }

  void setLockScreenHideDetails(bool value) =>
      account.updateSettings((s) => s.lockScreenHideDetails = value);

  LockScreenContent get lockScreenContent => LockScreenContent(
    events: events.on(today),
    tasks: tasks.pending(today),
    day: today,
    hideDetails: settings.lockScreenHideDetails,
  );

  /// Toggles the ongoing Quick Note notification (FR-20).
  ///
  /// When enabled, shows the current Quick Note text in the notification shade
  /// with a RemoteInput field.  Needs notifications to be on.
  Future<bool> setQuickNoteNotification(bool value) async {
    if (value && !settings.notificationsEnabled) {
      if (!await enableNotifications()) return false;
    }
    account.updateSettings((s) => s.quickNoteNotification = value);
    if (value) {
      await notifications.showQuickNoteNotification(notes.quickText);
    } else {
      await notifications.hideQuickNoteNotification();
    }
    return true;
  }

  /// Updates the Quick Note notification when its text changes (FR-20, AC-39).
  Future<void> updateQuickNoteNotification() async {
    if (!settings.quickNoteNotification) return;
    await notifications.showQuickNoteNotification(notes.quickText);
  }

  void _queueSync() {
    if (_syncQueued || !loaded) return;
    _syncQueued = true;
    scheduleMicrotask(() {
      _syncQueued = false;
      unawaited(syncNotifications());
    });
  }

  /// Reschedules reminders and refreshes the lock screen notification.
  /// Also updates the Quick Note notification when enabled (FR-20).
  Future<void> syncNotifications() async {
    if (!settings.notificationsEnabled) return;
    await notifications.syncReminders(
      tasks: tasks.items,
      events: events.items,
      now: now,
      habits: habits.active,
    );
    if (settings.lockScreenEnabled) {
      await notifications.showLockScreen(lockScreenContent);
    }
    if (settings.quickNoteNotification) {
      await notifications.showQuickNoteNotification(notes.quickText);
    }
  }

  // ---- System calendar ----------------------------------------------------

  /// True once the user has allowed reading the device calendar.
  bool systemCalendarGranted = false;

  /// Asks for the calendar permission and loads the device's events. When the
  /// user refuses, the app simply keeps using its local events.
  Future<bool> connectSystemCalendar() async {
    var granted = await systemCalendar.hasPermission();
    if (!granted) granted = await systemCalendar.requestPermission();
    systemCalendarGranted = granted;
    account.updateSettings((s) {
      s.calendarPermissionAsked = true;
      s.useSystemCalendar = granted;
    });
    if (granted) await refreshSystemCalendar();
    return granted;
  }

  void disconnectSystemCalendar() {
    account.updateSettings((s) => s.useSystemCalendar = false);
    events.setSystemEvents(const []);
  }

  void dismissCalendarBanner() =>
      account.updateSettings((s) => s.calendarBannerDismissed = true);

  /// Re-reads the device calendar around the selected day. Does nothing
  /// (and never prompts) unless the user has connected it.
  Future<void> refreshSystemCalendar() async {
    if (!settings.useSystemCalendar) return;
    systemCalendarGranted = await systemCalendar.hasPermission();
    if (!systemCalendarGranted) {
      events.setSystemEvents(const []);
      return;
    }
    final anchor = selectedDay;
    final from = DateTime(anchor.year, anchor.month - 1, 1);
    final to = DateTime(anchor.year, anchor.month + 2, 1);
    events.setSystemEvents(await systemCalendar.events(from, to));
  }

  // ---- Convenience writes that span features ------------------------------

  /// Quick Add from the lock screen or notification: a task due today.
  Task? quickAddTask(String title) => tasks.add(title, dueDate: today);

  // ---- Task convenience methods (BR-13, AC-25) ----------------------------

  /// Completes [task] and, for recurring tasks, generates the next occurrence.
  ///
  /// Returns the new recurring task when one was created, null otherwise.
  Task? completeTask(Task task) => tasks.completeAndReschedule(task);

  /// Deletes [task] and returns it so the presenter can offer undo (BR-13).
  Task? deleteTask(Task task) => tasks.delete(task);

  /// Restores a [deleteTask]'d task (BR-13 undo).
  void undoDeleteTask(Task task) => tasks.restore(task);

  /// Adds [tag] to [task] (creates tag if new) and persists.
  void addTagToTask(Task task, String tag) => tasks.addTag(task, tag);

  /// Removes [tag] from [task] and persists.
  void removeTagFromTask(Task task, String tag) => tasks.removeTag(task, tag);

  // ---- Note convenience methods (BR-13, AC-26, FR-20) ---------------------

  /// Pins [note] to the top of the notes list.
  void pinNote(Note note) => notes.pin(note);

  /// Unpins [note].
  void unpinNote(Note note) => notes.unpin(note);

  /// Toggles the pin state of [note].
  void togglePinNote(Note note) => notes.togglePin(note);

  /// Deletes [note] and returns it for undo (BR-13).
  Note? deleteNote(Note note) => notes.delete(note);

  /// Restores a [deleteNote]'d note (BR-13 undo).
  void undoDeleteNote(Note note) => notes.restore(note);

  /// Updates the Quick Note text and refreshes the notification (FR-20, AC-39).
  void saveQuickNote(String text) {
    notes.setQuick(text);
    unawaited(updateQuickNoteNotification());
  }

  // ---- Goals ---------------------------------------------------------------

  /// Active weekly goals for today.
  List<Goal> get weeklyGoals => goals.activeOn(today, GoalType.weekly);

  /// Active monthly goals for today.
  List<Goal> get monthlyGoals => goals.activeOn(today, GoalType.monthly);
}

/// Features locked behind VIP (BR-06); checked with [AppState.canAccess].
enum VipFeature {
  themeBuilder,
  freeFormLayout,
  customTypography,
  backgroundImages,
  publishTemplates,
}

/// Exposes [AppState] to the widget tree and rebuilds dependents on change.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Access without subscribing, for use in callbacks.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
