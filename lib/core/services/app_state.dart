import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/core/services/seed_data.dart';
import 'package:flutter_application/core/services/system_calendar_service.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/features/calendar/data/event_repository.dart';
import 'package:flutter_application/features/calendar/data/goal_repository.dart';
import 'package:flutter_application/features/calendar/data/habit_repository.dart';
import 'package:flutter_application/features/calendar/domain/goal.dart';
import 'package:flutter_application/features/dashboard/data/layout_repository.dart';
import 'package:flutter_application/features/note/data/note_repository.dart';
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
    events = EventRepository(store);
    habits = HabitRepository(store);
    habitOccurrences = HabitOccurrenceRepository(store);
    goals = GoalRepository(store, clock: this.clock);
    notes = NoteRepository(store, clock: this.clock);
    account = UserRepository(store, clock: this.clock);
    templates = TemplateRepository(store, clock: this.clock);
    layouts = LayoutRepository(store);
    // Wire companions so deleteScope / updateRepeatRule enforce BR-10 / BR-17.
    events.attachExceptions(EventExceptionRepository(store));
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

  /// Pushes the user's theme choices into [AppTheme].
  void applyTheme() {
    final accent = settings.accentIndex;
    AppTheme.apply(
      selectedTheme,
      dark: settings.darkMode,
      accent: accent == null ? null : AppColors.accent(accent),
      // Custom typography is a VIP feature; a lapsed VIP falls back.
      typography: isVip ? settings.typography : null,
    );
    themeRevision.value++;
  }

  void selectTheme(String themeId) {
    account.selectTheme(themeId);
    // A theme brings its own primary color, so drop the accent override.
    account.updateSettings((s) => s.accentIndex = null);
    applyTheme();
  }

  void setDarkMode(bool value) {
    account.updateSettings((s) => s.darkMode = value);
    applyTheme();
  }

  void setAccent(int? index) {
    account.updateSettings((s) => s.accentIndex = index);
    applyTheme();
  }

  /// VIP only. Returns false (and changes nothing) for a Free user.
  bool setTypography(String? typography) {
    if (!isVip) return false;
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

  /// Back to Free, so the gating can be tested again.
  void cancelVip() {
    account.setVip(false);
    applyTheme();
  }

  // ---- Templates ----------------------------------------------------------

  bool ownsTemplate(Template template) => templates.owns(user.id, template);

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
    if (!isVip) return null;
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
    if (!isVip || template.creatorId != user.id) return false;
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

  LockScreenContent get lockScreenContent => LockScreenContent(
    events: events.on(today),
    tasks: tasks.pending(today),
    day: today,
  );

  void _queueSync() {
    if (_syncQueued || !loaded) return;
    _syncQueued = true;
    scheduleMicrotask(() {
      _syncQueued = false;
      unawaited(syncNotifications());
    });
  }

  /// Reschedules reminders and refreshes the lock screen notification.
  Future<void> syncNotifications() async {
    if (!settings.notificationsEnabled) return;
    await notifications.syncReminders(
      tasks: tasks.items,
      events: events.items,
      now: now,
    );
    if (settings.lockScreenEnabled) {
      await notifications.showLockScreen(lockScreenContent);
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

  // ---- Goals ---------------------------------------------------------------

  /// Active weekly goals for today.
  List<Goal> get weeklyGoals => goals.activeOn(today, GoalType.weekly);

  /// Active monthly goals for today.
  List<Goal> get monthlyGoals => goals.activeOn(today, GoalType.monthly);
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
