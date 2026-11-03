import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application/app/app.dart';
import 'package:flutter_application/app/theme/app_colors.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/utils/strings.dart';
import 'package:flutter_application/core/utils/date_formatter.dart';
import 'package:flutter_application/core/services/notification_actions.dart';
import 'package:flutter_application/core/services/notification_service.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/appearance_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/notification_settings_screen.dart';
import 'package:flutter_application/features/settings_screen/presentation/screens/settings_screen.dart';
import 'package:flutter_application/features/vip/domain/purchase.dart';
import 'package:flutter_application/features/vip/presentation/screens/template_studio_screen.dart';
import 'package:flutter_application/features/vip/presentation/screens/vip_screen.dart';

/// Person 3 tests: Settings, Theme, VIP and templates (FR-02, FR-13 … FR-16,
/// FR-21).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Wednesday 14 Oct 2026, 10:00 (morning, for the greeting).
  final now = DateTime(2026, 10, 14, 10);

  Future<AppState> loadedApp([DocumentStore? store]) async {
    final app = AppState(
      store: store ?? MemoryDocumentStore(),
      clock: () => now,
    );
    await app.load();
    return app;
  }

  Future<void> pumpApp(WidgetTester tester, AppState app) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(SuperCalendarApp(state: app));
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// [screen] inside the app shell, so AppScope and the theme are in place.
  Future<void> pumpScreen(
    WidgetTester tester,
    AppState app,
    Widget screen,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('AC-01: Home opens first with exactly the 5 tabs', (
    tester,
  ) async {
    final app = await loadedApp();
    app.finishOnboarding('Mia');
    await pumpApp(tester, app);

    expect(app.tab, 0);
    expect(find.textContaining('Good morning, Mia'), findsOneWidget);
    for (final tab in ['Home', 'Calendar', 'To-do', 'VIP', 'Settings']) {
      expect(find.text(tab), findsWidgets, reason: tab);
    }
    expect(find.text('Notes'), findsNothing);
  });

  testWidgets('AC-06: a new display name reaches the Home greeting at once', (
    tester,
  ) async {
    final app = await loadedApp();
    app.finishOnboarding('Mia');
    await pumpApp(tester, app);

    app.account.rename('An');
    await tester.pump();
    expect(find.textContaining('Good morning, An'), findsOneWidget);
  });

  test('AC-07: a ticked task is done on Home, To-do and Lock Screen', () async {
    final app = await loadedApp();
    final task = app.quickAddTask('Buy milk')!;
    expect(app.lockScreenContent.tasks, contains(task));

    app.completeTask(task);
    expect(app.tasks.byId(task.id)!.completed, isTrue);
    expect(app.lockScreenContent.tasks, isNot(contains(task)));
  });

  test('AC-10: a Free user cannot set a premium font', () async {
    final app = await loadedApp();
    expect(app.setTypography('serif'), isFalse);
    expect(app.settings.typography, isNull);

    app.completeVipPayment(PaymentResult.success);
    expect(app.setTypography('serif'), isTrue);
    expect(app.settings.typography, 'serif');
  });

  testWidgets('AC-10: choosing a font as a Free user opens the paywall', (
    tester,
  ) async {
    final app = await loadedApp();
    await pumpScreen(tester, app, const AppearanceScreen());

    await tester.ensureVisible(find.text('Font style'));
    await tester.tap(find.text('Font style'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Custom typography is a VIP feature'), findsOneWidget);
  });

  test('AC-29: switching to Dark repaints with the dark palette', () async {
    final app = await loadedApp();
    app.setDarkMode(false);
    final lightBackground = AppColors.background;
    final revision = app.themeRevision.value;

    app.setDarkMode(true);
    expect(app.settings.themeMode, ThemeModeSetting.dark);
    expect(app.themeRevision.value, greaterThan(revision));
    expect(AppColors.background, isNot(lightBackground));
    app.setDarkMode(false);
  });

  test('AC-30: a Free user owns exactly the 3 free templates', () async {
    final app = await loadedApp();
    final owned = app.templates.templates.where(app.ownsTemplate).toList();
    expect(owned.length, 3);
    expect(owned.every((t) => t.price == 0 && !t.isPremium), isTrue);
  });

  test('AC-31: a mock purchase unlocks a premium template', () async {
    final app = await loadedApp();
    final premium = app.templates.templates.firstWhere(
      (t) => !app.ownsTemplate(t),
    );
    expect(app.applyTemplate(premium), isFalse);

    app.completeTemplatePayment(premium, PaymentResult.cancelled);
    expect(app.ownsTemplate(premium), isFalse);

    app.completeTemplatePayment(premium, PaymentResult.success);
    expect(app.ownsTemplate(premium), isTrue);
    expect(app.templates.hasPurchased(app.user.id, premium.id), isTrue);
    expect(app.applyTemplate(premium), isTrue);
  });

  testWidgets('AC-32: widget size L enlarges the Template Studio preview', (
    tester,
  ) async {
    final app = await loadedApp();
    app.completeVipPayment(PaymentResult.success);
    await pumpScreen(tester, app, const TemplateStudioScreen());

    // Event bars on the canvas are 22 + spacing tall: 12 for M, 14 for L.
    Finder eventBars(double height) => find.byWidgetPredicate(
      (w) => w is Container && w.constraints?.minHeight == height,
    );
    expect(eventBars(34), findsWidgets);
    await tester.ensureVisible(find.text('L'));
    await tester.tap(find.text('L'));
    await tester.pump();
    expect(eventBars(34), findsNothing);
    expect(eventBars(36), findsWidgets);
  });

  test('AC-33: a saved Studio template is listed in Presets', () async {
    final app = await loadedApp();
    expect(
      app.createTemplate(
        name: 'Free try',
        description: '',
        price: 0,
        preview: '*',
        theme: app.selectedTheme,
      ),
      isNull,
    );

    app.completeVipPayment(PaymentResult.success);
    final mine = app.createTemplate(
      name: 'My Calm Week',
      description: '',
      price: 0,
      preview: '*',
      theme: app.selectedTheme,
    )!;
    final presets = app.templates.templates.where(
      (t) => t.creatorId == app.user.id,
    );
    expect(presets.map((t) => t.id), contains(mine.id));
  });

  testWidgets('UI-09: Settings has the Tasks, Data and Privacy rows', (
    tester,
  ) async {
    final app = await loadedApp();
    await pumpScreen(tester, app, const SettingsScreen());

    expect(app.settings.hideCompletedTasks, isFalse);
    await tester.ensureVisible(find.text('Hide completed tasks'));
    await tester.tap(find.text('Hide completed tasks'));
    await tester.pump();
    expect(app.settings.hideCompletedTasks, isTrue);

    await tester.ensureVisible(find.text('Privacy & Terms'));
    await tester.tap(find.text('Privacy & Terms'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('no cloud sync'), findsOneWidget);
  });

  test('UI-09: the new Settings texts have Vietnamese translations', () async {
    final app = await loadedApp();
    app.setLanguage(AppStrings.vietnamese);
    for (final en in [
      'Hide completed tasks',
      'Data',
      'On this device',
      'Privacy & Terms',
    ]) {
      expect(tr(en), isNot(en), reason: en);
    }
    expect(tr('Privacy & Terms'), 'Quyền riêng tư & Điều khoản');
    app.setLanguage('English');
  });

  testWidgets('Settings 26: the rows of the design, in its order', (
    tester,
  ) async {
    final app = await loadedApp();
    await pumpScreen(tester, app, const SettingsScreen());

    final rows = [
      'Account',
      'Appearance',
      'Language',
      'Date & Time',
      'Calendar',
      'Notifications',
      'Lock Screen',
      'Help',
      'App Version',
    ];
    final tops = [for (final r in rows) tester.getTopLeft(find.text(r)).dy];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.text('Mia Chen · Free'), findsOneWidget);
    expect(find.text('Synced across 3 devices'), findsOneWidget);
    expect(find.text('Template Store'), findsNothing);
    expect(find.text('Mobile Screen'), findsNothing);
  });

  testWidgets('FR-02: Profile & account saves name and email together', (
    tester,
  ) async {
    final app = await loadedApp();
    await pumpScreen(tester, app, const SettingsScreen());
    await tester.tap(find.text('Mia Chen · Free'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Profile & account'), findsOneWidget);

    await tester.tap(find.text('Mia Chen'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'An Nguyen');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 300));
    // Nothing is written before "Save profile".
    expect(app.user.name, 'Mia Chen');

    await tester.tap(find.text('Save profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(app.user.name, 'An Nguyen');
  });

  testWidgets('Settings 29: sync status shows the offline state', (
    tester,
  ) async {
    final app = await loadedApp();
    await pumpScreen(tester, app, const SettingsScreen());
    await tester.tap(find.text('Synced across 3 devices'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Couldn’t sync yet'), findsOneWidget);
    expect(find.text('Your local data remains saved'), findsOneWidget);
  });

  testWidgets('VIP 25: a VIP sees the membership page, then the Studio', (
    tester,
  ) async {
    final app = await loadedApp();
    app.completeVipPayment(PaymentResult.success);
    await pumpScreen(tester, app, const VipScreen());

    expect(find.text('You’re a VIP, Mia'), findsOneWidget);
    expect(find.text('Free & VIP, at a glance'), findsOneWidget);
    await tester.ensureVisible(find.text('Explore styles'));
    await tester.tap(find.text('Explore styles'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Template Studio'), findsOneWidget);
  });

  testWidgets('VIP 25: a Free user still gets the offer', (tester) async {
    final app = await loadedApp();
    await pumpScreen(tester, app, const VipScreen());
    expect(find.text('Subscribe'), findsOneWidget);
    expect(find.text('Free & VIP, at a glance'), findsNothing);
  });

  test('Settings 28: reminder types persist; old data keeps them on', () async {
    final old = AppSettings.fromJson({});
    expect(
      old.eventReminders && old.taskReminders && old.habitReminders,
      isTrue,
    );
    expect(old.taskReminderMinutes, 30);
    expect(old.habitReminderMinutes, isNull);

    final store = MemoryDocumentStore();
    final app = await loadedApp(store);
    app.account.updateSettings((s) {
      s.taskReminders = false;
      s.taskReminderMinutes = null;
    });
    await app.flush();
    final reopened = await loadedApp(store);
    expect(reopened.settings.taskReminders, isFalse);
    expect(reopened.settings.taskReminderMinutes, isNull);
  });

  testWidgets('Settings 28: Notifications lists Events, Tasks and Habits', (
    tester,
  ) async {
    final app = await loadedApp();
    await pumpScreen(tester, app, const NotificationSettingsScreen());
    for (final type in ['Events', 'Tasks', 'Habits']) {
      expect(find.text(type), findsOneWidget, reason: type);
    }
    expect(find.text('At the scheduled time'), findsOneWidget);
    expect(find.text('Quick Note on your lock screen'), findsOneWidget);
  });

  testWidgets('NFR-11: the first tap asks Android, later taps open settings', (
    tester,
  ) async {
    final app = await loadedApp();
    await pumpScreen(tester, app, const NotificationSettingsScreen());
    expect(find.text('Allow notifications'), findsOneWidget);

    await tester.ensureVisible(find.text('Allow notifications'));
    await tester.tap(find.text('Allow notifications'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(app.settings.notificationPermissionAsked, isTrue);
    expect(find.text('Open Android notification settings'), findsOneWidget);
  });

  testWidgets('AC-38: Lock Screen settings keep the Hide details switch', (
    tester,
  ) async {
    final app = await loadedApp();
    await pumpScreen(tester, app, const LockScreenSettingsScreen());
    await tester.tap(find.text('Hide details'));
    await tester.pump();
    expect(app.settings.lockScreenHideDetails, isTrue);
  });

  test('FR-21: the date format orders numeric dates', () async {
    final store = MemoryDocumentStore();
    final app = await loadedApp(store);
    app.setLanguage(AppStrings.vietnamese);
    final oct30 = DateTime(2026, 10, 30);
    expect(relativeDay(oct30, now), '30/10');

    app.account.updateSettings((s) => s.dateFormat = 'MM/dd/yyyy');
    expect(relativeDay(oct30, now), '10/30');
    expect(shortDate(oct30), endsWith('10/30'));

    await app.flush();
    app.account.updateSettings((s) => s.dateFormat = 'dd/MM/yyyy');
    await app.flush();
    // Reopening restores the saved choice.
    app.account.updateSettings((s) => s.dateFormat = 'MM/dd/yyyy');
    await app.flush();
    await loadedApp(store);
    expect(DateFormatPrefs.monthFirst, isTrue);

    app.account.updateSettings((s) => s.dateFormat = 'dd/MM/yyyy');
    app.setLanguage('English');
  });

  test('§5.2: new tasks start with the default priority', () async {
    final app = await loadedApp();
    expect(app.quickAddTask('Buy milk')!.priority, Task.priorityMedium);

    app.account.updateSettings((s) => s.defaultPriority = Task.priorityHigh);
    expect(app.quickAddTask('Call mom')!.priority, Task.priorityHigh);
  });

  test('§5.2: a task added from a notification uses the default too', () async {
    final store = MemoryDocumentStore();
    final app = await loadedApp(store);
    app.account.updateSettings((s) => s.defaultPriority = Task.priorityLow);
    await app.flush();
    await handleNotificationAction(
      store: store,
      notifications: NoopNotificationService(),
      actionId: NotificationActions.addTask,
      payload: null,
      input: 'Water plants',
      clock: () => now,
    );
    final reopened = await loadedApp(store);
    final task = reopened.tasks.items.firstWhere(
      (t) => t.title == 'Water plants',
    );
    expect(task.priority, Task.priorityLow);
  });

  test(
    'Settings 28: without Android the settings button reports false',
    () async {
      expect(await openAndroidNotificationSettings(), isFalse);
    },
  );

  test('FR-22: visible device calendars persist, old data shows all', () async {
    expect(AppSettings.fromJson({}).visibleCalendarIds, isEmpty);
    final store = MemoryDocumentStore();
    final app = await loadedApp(store);
    app.account.updateSettings((s) => s.visibleCalendarIds = ['3', '7']);
    await app.flush();
    final reopened = await loadedApp(store);
    expect(reopened.settings.visibleCalendarIds, ['3', '7']);
  });
}
