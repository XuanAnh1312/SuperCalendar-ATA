import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter_application/core/data/sqlite_document_store.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/features/settings_screen/data/user_repository.dart';
import 'package:flutter_application/features/calendar/data/habit_repository.dart';
import 'package:flutter_application/core/services/notification_actions.dart';
import 'package:flutter_application/features/calendar/data/event_repository.dart';
import 'package:flutter_application/features/todo/data/task_repository.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_application/core/utils/strings.dart';

import 'ios_notification_configuration.dart';

/// Port the UI isolate listens on to learn that a notification action changed
/// the database from the background isolate.
const _refreshPortName = 'supercalendar_data_changed';
Future<void> _backgroundActions = Future.value();

/// Entry point for notification action buttons. Android runs it in a separate
/// isolate, with or without the app's UI alive.
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  _backgroundActions = _backgroundActions
      .then((_) => _handleBackgroundResponse(response))
      .catchError((Object error, StackTrace stack) {
        debugPrint('Notification action failed: $error\n$stack');
      });
}

Future<void> _handleBackgroundResponse(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final notifications = LocalNotificationService();
  await notifications.init();
  // The database connection is shared with the UI isolate's process, so it
  // is intentionally left open here.
  final store = await SqliteDocumentStore.open();
  final changed = await handleNotificationAction(
    store: store,
    notifications: notifications,
    actionId: response.actionId,
    payload: response.payload,
    input: response.input,
  );
  if (changed || response.actionId == NotificationActions.snooze) {
    IsolateNameServer.lookupPortByName(_refreshPortName)?.send(true);
  }
  debugPrint('Notification action ${response.actionId}: changed=$changed');
}

/// Android notifications: reminders with Done / Snooze, and the persistent
/// lock screen notification with today's schedule and to-do quick actions.
class LocalNotificationService implements NotificationService {
  LocalNotificationService({
    this.store,
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? clock,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  Future<void>? _initialized;
  void Function(NotificationTarget)? _onOpen;
  void Function()? _onDataChanged;

  final DocumentStore? store;
  Future<DocumentStore> _openStore() async =>
      store ?? await SqliteDocumentStore.open();
  static const _lockScreenId = 1;
  static const _quickNoteId = 2;

  final FlutterLocalNotificationsPlugin _plugin;
  ReceivePort? _refreshPort;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<void> init({
    void Function(NotificationTarget target)? onOpen,
    void Function()? onDataChanged,
  }) async {
    if (onOpen != null) _onOpen = onOpen;
    if (onDataChanged != null) {
      _onDataChanged = onDataChanged;
      if (_refreshPort == null) {
        IsolateNameServer.removePortNameMapping(_refreshPortName);
        _refreshPort = ReceivePort()..listen((_) => _onDataChanged?.call());
        IsolateNameServer.registerPortWithName(
          _refreshPort!.sendPort,
          _refreshPortName,
        );
      }
    }
    return _initialized ??= _initializePlugin();
  }

  Future<void> _initializePlugin() async {
    try {
      await _plugin.initialize(
        settings: InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: iosNotificationConfiguration(),
        ),
        onDidReceiveNotificationResponse: (response) =>
            unawaited(_foregroundResponse(response)),
        onDidReceiveBackgroundNotificationResponse:
            onBackgroundNotificationResponse,
      );
    } catch (_) {
      _initialized = null;
      rethrow;
    }
  }

  Future<void> _foregroundResponse(NotificationResponse response) async {
    if ({
      NotificationActions.done,
      NotificationActions.skip,
      NotificationActions.snooze,
      NotificationActions.addTask,
      NotificationActions.saveNote,
    }.contains(response.actionId)) {
      final changed = await handleNotificationAction(
        store: await _openStore(),
        notifications: this,
        actionId: response.actionId,
        payload: response.payload,
        input: response.input,
      );
      if (changed || response.actionId == NotificationActions.snooze) {
        _onDataChanged?.call();
      }
      return;
    }
    final target = response.actionId == NotificationActions.schedule
        ? const NotificationTarget(NotificationTarget.schedule, '')
        : NotificationTarget.decode(response.payload);
    if (target != null) _onOpen?.call(target);
  }

  Future<
    ({
      ReminderContext context,
      EventRepository events,
      TaskRepository tasks,
      HabitRepository habits,
    })
  >
  _snapshot() async {
    final database = await _openStore();
    final account = UserRepository(database);
    await account.load();
    final exceptions = EventExceptionRepository(database);
    await exceptions.load();
    final events = EventRepository(database, exceptions: exceptions);
    await events.load();
    final occurrences = HabitOccurrenceRepository(database);
    await occurrences.load();
    final habits = HabitRepository(database, occurrences: occurrences);
    await habits.load();
    final tasks = TaskRepository(database);
    await tasks.load();
    return (
      context: ReminderContext(
        settings: account.settings,
        habitOccurrences: occurrences.items,
      ),
      events: events,
      tasks: tasks,
      habits: habits,
    );
  }

  Future<bool> _canShow({bool quickNote = false}) async {
    await init();
    final account = UserRepository(await _openStore());
    await account.load();
    return account.settings.notificationsEnabled &&
        (!quickNote || account.settings.quickNoteNotification) &&
        await hasPermission();
  }

  @override
  Future<NotificationTarget?> launchTarget() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    if (details.notificationResponse?.actionId ==
        NotificationActions.schedule) {
      return const NotificationTarget(NotificationTarget.schedule, '');
    }
    return NotificationTarget.decode(details.notificationResponse?.payload);
  }

  @override
  Future<bool> hasPermission() async {
    if (_isIos) return (await _ios?.checkPermissions())?.isEnabled ?? false;
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    if (_isIos) {
      return await _ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return await _android?.requestNotificationsPermission() ?? false;
  }

  // ---- Reminders ----------------------------------------------------------

  NotificationDetails _reminderDetails({
    required bool task,
    bool habit = false,
    String? tag,
    int? timeoutAfter,
  }) {
    return NotificationDetails(
      iOS: DarwinNotificationDetails(
        categoryIdentifier: task
            ? 'task_reminder'
            : habit
            ? 'habit_reminder'
            : 'event_reminder',
        threadIdentifier: 'reminders',
      ),
      android: AndroidNotificationDetails(
        'reminders',
        'Reminders',
        tag: tag,
        timeoutAfter: timeoutAfter,
        channelDescription: 'Event and task reminders',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        actions: [
          if (task)
            AndroidNotificationAction(NotificationActions.done, tr('Done')),
          AndroidNotificationAction(NotificationActions.snooze, tr('Snooze')),
          if (habit)
            AndroidNotificationAction(NotificationActions.skip, tr('Skip')),
        ],
      ),
    );
  }

  String _taskBody(Task task) => [
    task.title,
    if (task.dueTime != null) formatClock(task.dueTime!),
  ].join(' · ');

  String _eventBody(CalendarEvent event) => [
    event.title,
    event.startLabel,
    if (event.location.isNotEmpty) event.location,
  ].join(' · ');

  @override
  Future<void> syncReminders({
    required List<Task> tasks,
    required List<CalendarEvent> events,
    required DateTime now,
    List<Habit> habits = const [],
  }) async {
    await init();
    final snapshot = await _snapshot();
    // Global permission/on-off is owned by AppState. This lower-level API
    // also supports explicit previews; category switches still apply here.
    snapshot.context.settings.notificationsEnabled = true;
    events = [
      for (final event in events)
        snapshot.events.withOccurrenceLookup(
          CalendarEvent.fromJson(event.toJson()),
        ),
    ];
    final context = snapshot.context;
    final plan = buildReminderPlan(
      tasks: tasks,
      events: events,
      habits: habits,
      now: now,
      context: context,
    );
    bool valid(NotificationTarget target) => reminderTargetIsValid(
      target,
      tasks: tasks,
      events: events,
      habits: habits,
      now: now,
      context: context,
    );
    final snoozed = <String>{};
    for (final pending in await _plugin.pendingNotificationRequests()) {
      final target = NotificationTarget.decode(pending.payload);
      if (target == null ||
          !{
            NotificationTarget.task,
            NotificationTarget.event,
            NotificationTarget.habit,
          }.contains(target.type)) {
        continue;
      }
      final key = '${target.type}:${target.id}';
      if (target.snoozed && valid(target) && snoozed.add(key)) continue;
      await _plugin.cancel(id: pending.id);
    }
    // Android does not expose the payload of an active notification. The tag
    // carries the same target so deleted/edited occurrences can be cancelled.
    for (final active in await _plugin.getActiveNotifications()) {
      if ((!_isIos && active.channelId != 'reminders') ||
          active.id == null ||
          active.id == 1 ||
          active.id == 2) {
        continue;
      }
      final target = NotificationTarget.decode(
        _isIos ? active.payload : active.tag,
      );
      if (target == null || !valid(target)) {
        await _plugin.cancel(id: active.id!, tag: active.tag);
      }
    }
    // iOS keeps at most 64 pending local notifications; reserve two card IDs.
    for (final entry
        in _isIos ? plan.take(62 - snoozed.length.clamp(0, 62)) : plan) {
      if (snoozed.contains(entry.sourceKey)) continue;
      await _scheduleEntry(entry);
    }
  }

  Future<void> _scheduleEntry(ReminderPlanEntry entry) => _schedule(
    id: reminderNotificationId(
      '${entry.target.snoozed ? 'snooze:' : ''}${entry.sourceKey}',
    ),
    at: entry.at,
    expiresAt: entry.expiresAt,
    title: entry.task != null
        ? tr('Task reminder')
        : entry.event != null
        ? tr('Upcoming event')
        : tr('Habit reminder'),
    body: entry.task != null
        ? _taskBody(entry.task!)
        : entry.event != null
        ? _eventBody(entry.event!)
        : entry.habit!.title,
    target: entry.target,
  );

  Future<void> _schedule({
    required int id,
    required DateTime at,
    DateTime? expiresAt,
    required String title,
    required String body,
    required NotificationTarget target,
  }) async {
    if (expiresAt != null && !expiresAt.isAfter(at)) return;
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.UTC),
      notificationDetails: _reminderDetails(
        task: target.type == NotificationTarget.task,
        habit: target.type == NotificationTarget.habit,
        tag: target.encode(),
        timeoutAfter: expiresAt?.difference(at).inMilliseconds,
      ),
      androidScheduleMode: mode,
      payload: target.encode(),
    );
    try {
      await schedule(
        exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } on PlatformException catch (error) {
      if (!exact || !error.code.contains('exact_alarm')) rethrow;
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  @override
  Future<void> cancelReminders() async {
    await init();
    await _plugin.cancelAllPendingNotifications();
    for (final active in await _plugin.getActiveNotifications()) {
      if ((active.channelId == 'reminders' ||
              (_isIos && active.id != 1 && active.id != 2)) &&
          active.id != null) {
        await _plugin.cancel(id: active.id!, tag: active.tag);
      }
    }
  }

  @override
  Future<void> showTaskReminder(Task task) async {
    if (!await _canShow()) return;
    final target = NotificationTarget(
      NotificationTarget.task,
      task.id,
      occurrenceStart: task.dueAt,
    );
    await _plugin.show(
      id: reminderNotificationId('task:${task.id}'),
      title: tr('Task reminder'),
      body: _taskBody(task),
      notificationDetails: _reminderDetails(task: true, tag: target.encode()),
      payload: target.encode(),
    );
  }

  @override
  Future<void> snoozeTask(Task task, Duration delay) => _snooze(
    NotificationTarget(
      NotificationTarget.task,
      task.id,
      snoozed: true,
      occurrenceStart: task.dueAt,
    ),
    delay,
  );

  @override
  Future<void> snoozeEvent(CalendarEvent event, Duration delay) => _snooze(
    NotificationTarget(
      NotificationTarget.event,
      event.id,
      snoozed: true,
      occurrenceDate: event.originalOccurrenceDate ?? dateOnly(event.startTime),
      occurrenceStart: event.startTime,
    ),
    delay,
  );

  @override
  Future<void> snoozeHabit(Habit habit, Duration delay) => _snooze(
    NotificationTarget(
      NotificationTarget.habit,
      habit.id,
      snoozed: true,
      occurrenceDate: dateOnly(_clock()),
      occurrenceStart: habit.time == null
          ? null
          : DateTime(
              _clock().year,
              _clock().month,
              _clock().day,
              0,
              habit.time!,
            ),
    ),
    delay,
  );

  Future<void> _snooze(NotificationTarget target, Duration delay) async {
    await init();
    final data = await _snapshot();
    final now = _clock();
    if (!reminderTargetIsValid(
          target,
          tasks: data.tasks.items,
          events: data.events.items,
          habits: data.habits.items,
          now: now,
          context: data.context,
        ) ||
        !await hasPermission()) {
      return;
    }
    final day = target.occurrenceDate ?? now;
    final task = data.tasks.byId(target.id);
    final event = data.events.byId(target.id)?.resolvedOccurrenceOn(day);
    final baseHabit = data.habits.byId(target.id);
    final habit = baseHabit == null
        ? null
        : effectiveHabit(baseHabit, day, data.context);
    await cancel(target.type, target.id);
    await _scheduleEntry(
      ReminderPlanEntry(
        target: target,
        at: now.add(delay),
        task: task,
        event: event,
        habit: habit,
        expiresAt:
            event?.endTime ??
            (habit == null ? null : DateTime(day.year, day.month, day.day + 1)),
      ),
    );
  }

  // ---- Lock screen --------------------------------------------------------

  @override
  Future<void> showLockScreen(LockScreenContent content) async {
    if (!await _canShow()) return;
    final events = content.events;
    final tasks = content.tasks;
    final next = tasks.firstOrNull;
    final hide = content.hideDetails;
    final lines = [
      if (!hide) ...[
        for (final event in events) '${event.startLabel}  ${event.title}',
        if (events.isEmpty) tr('Nothing scheduled today'),
        for (final task in tasks) '☐ ${task.title}',
      ],
    ];
    final summary = [
      trf(events.length == 1 ? '{n} event' : '{n} events', {
        'n': events.length,
      }),
      trf(tasks.length == 1 ? '{n} to-do' : '{n} to-dos', {'n': tasks.length}),
    ].join(' · ');
    return _plugin.show(
      id: _lockScreenId,
      title: shortDate(content.day),
      body: summary,
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          categoryIdentifier: next == null ? 'schedule' : 'schedule_task',
          threadIdentifier: 'schedule',
          subtitle: hide ? null : lines.join('\n'),
          presentSound: false,
        ),
        android: AndroidNotificationDetails(
          'lock_screen',
          'Lock screen',
          channelDescription: "Today's schedule and to-do on the lock screen",
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          // Public: the content is shown without unlocking the phone.
          visibility: NotificationVisibility.public,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          playSound: false,
          enableVibration: false,
          styleInformation: InboxStyleInformation(
            lines,
            contentTitle: shortDate(content.day),
            summaryText: summary,
          ),
          actions: [
            AndroidNotificationAction(
              NotificationActions.schedule,
              tr('Schedule'),
              showsUserInterface: true,
              cancelNotification: false,
            ),
            if (next != null)
              AndroidNotificationAction(
                NotificationActions.done,
                hide ? tr('✓ Next to-do') : '✓ ${next.title}',
                cancelNotification: false,
              ),
            AndroidNotificationAction(
              NotificationActions.addTask,
              tr('Add task'),
              cancelNotification: false,
              inputs: [AndroidNotificationActionInput(label: tr('New task'))],
            ),
          ],
        ),
      ),
      // The Done action completes the task named in the payload.
      payload: NotificationTarget(
        NotificationTarget.lockScreen,
        next?.id ?? '',
      ).encode(),
    );
  }

  @override
  Future<void> hideLockScreen() => _plugin.cancel(id: _lockScreenId);

  // ---- Individual scheduling (FR-18) ──────────────────────────────────────

  Future<DateTime?> _scheduleOne({
    Task? task,
    CalendarEvent? event,
    Habit? habit,
  }) async {
    await init();
    final data = await _snapshot();
    data.context.settings.notificationsEnabled = true;
    final plan = buildReminderPlan(
      tasks: task == null ? [] : [task],
      events: event == null
          ? []
          : [
              data.events.withOccurrenceLookup(
                CalendarEvent.fromJson(event.toJson()),
              ),
            ],
      habits: habit == null ? [] : [habit],
      now: _clock(),
      context: data.context,
    );
    final type = task != null
        ? NotificationTarget.task
        : event != null
        ? NotificationTarget.event
        : NotificationTarget.habit;
    await cancel(type, task?.id ?? event?.id ?? habit!.id);
    if (plan.isEmpty) return null;
    await _scheduleEntry(plan.first);
    return plan.first.at;
  }

  @override
  Future<DateTime?> scheduleForEvent(CalendarEvent event) =>
      _scheduleOne(event: event);
  @override
  Future<DateTime?> scheduleForTask(Task task) => _scheduleOne(task: task);
  @override
  Future<DateTime?> scheduleForHabit(Habit habit) => _scheduleOne(habit: habit);

  @override
  Future<void> cancel(String sourceType, String sourceId) async {
    await init();
    await _plugin.cancel(id: reminderNotificationId('$sourceType:$sourceId'));
    await _plugin.cancel(
      id: reminderNotificationId('snooze:$sourceType:$sourceId'),
    );
    for (final active in await _plugin.getActiveNotifications()) {
      final target = NotificationTarget.decode(
        _isIos ? active.payload : active.tag,
      );
      if (active.id != null &&
          target?.type == sourceType &&
          target?.id == sourceId) {
        await _plugin.cancel(id: active.id!, tag: active.tag);
      }
    }
  }

  // ---- Quick Note notification (FR-20) ────────────────────────────────────

  /// The ongoing Quick Note notification (FR-20).
  ///
  /// Shows the current Quick Note text, with a RemoteInput field for editing
  /// and Save / Open app action buttons (FR-20.02, FR-20.03).
  @override
  Future<void> showQuickNoteNotification(String text) async {
    if (!await _canShow(quickNote: true)) return;
    final displayText = text.isEmpty ? tr('Tap to write a quick note') : text;
    return _plugin.show(
      id: _quickNoteId,
      title: 'SuperCalendar · Quick Note',
      body: displayText,
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'quick_note',
          threadIdentifier: 'quick_note',
          presentSound: false,
        ),
        android: AndroidNotificationDetails(
          'quick_note',
          'Quick Note',
          channelDescription: 'Quick Note for fast capture from the shade',
          importance: Importance.low,
          priority: Priority.low,
          visibility: NotificationVisibility.public,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          playSound: false,
          enableVibration: false,
          category: AndroidNotificationCategory.status,
          styleInformation: BigTextStyleInformation(
            displayText,
            contentTitle: 'SuperCalendar · Quick Note',
            summaryText: tr('Saved'),
          ),
          actions: [
            AndroidNotificationAction(
              NotificationActions.saveNote,
              tr('Save note'),
              cancelNotification: false,
              inputs: [
                AndroidNotificationActionInput(label: tr('Type a note…')),
              ],
            ),
            AndroidNotificationAction(
              NotificationActions.openApp,
              tr('Open app'),
              showsUserInterface: true,
              cancelNotification: false,
            ),
          ],
        ),
      ),
      payload: NotificationTarget(NotificationTarget.quickNote, '').encode(),
    );
  }

  @override
  Future<void> hideQuickNoteNotification() => _plugin.cancel(id: _quickNoteId);
}
