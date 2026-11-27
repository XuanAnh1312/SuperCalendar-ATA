import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/services/app_state.dart';
import 'package:flutter_application/core/services/auto_wallpaper_service.dart';
import 'package:flutter_application/core/services/planner_backup.dart';
import 'package:flutter_application/features/calendar/data/event_repository.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/settings_screen/domain/app_settings.dart';
import 'package:flutter_application/features/todo/data/task_repository.dart';
import 'package:flutter_application/features/todo/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingStore extends MemoryDocumentStore {
  bool failNext = true;

  @override
  Future<void> put(String collection, String id, Map<String, dynamic> data) {
    if (failNext) {
      failNext = false;
      return Future.error(StateError('Simulated disk write failure'));
    }
    return super.put(collection, id, data);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 11, 27, 10);

  test(
    'a failed write leaves subsequent saves usable and can be retried',
    () async {
      final store = _FailingStore();
      final repo = TaskRepository(store);
      addTearDown(repo.dispose);
      final first = repo.add('First')!;
      await expectLater(repo.flush(), throwsStateError);
      final second = Task(id: 'second', title: 'Second', createdAt: now);
      repo.insert(second);
      await expectLater(repo.flush(), throwsStateError);
      expect(repo.hasWriteFailures, isTrue);
      expect((await store.readAll(Collections.tasks)).single['id'], second.id);

      await repo.retryWrites();
      expect(repo.hasWriteFailures, isFalse);
      final saved = await store.readAll(Collections.tasks);
      expect(
        saved.map((item) => item['id']),
        unorderedEquals([first.id, second.id]),
      );
    },
  );

  test(
    'wallpaper revision changes when a note changes or the date rolls over',
    () async {
      var clock = now;
      final app = AppState(store: MemoryDocumentStore(), clock: () => clock);
      addTearDown(app.dispose);
      await app.load(seedDemoData: false);
      final first = AutoWallpaperService.contentRevision(app);
      expect(AutoWallpaperService.contentRevision(app), first);
      app.notes.setQuick('New note');
      final changed = AutoWallpaperService.contentRevision(app);
      expect(changed, isNot(first));
      clock = DateTime(now.year, now.month, now.day + 1);
      expect(AutoWallpaperService.contentRevision(app), isNot(changed));
      await app.flush();
    },
  );

  test(
    'backup merges missing items and rejects a duplicate before importing',
    () async {
      final source = MemoryDocumentStore();
      final repo = TaskRepository(source);
      addTearDown(repo.dispose);
      final original = repo.add('Original')!;
      final missing = repo.add('Missing')!;
      await repo.flush();
      final target = MemoryDocumentStore();
      await target.put(Collections.tasks, original.id, {
        ...original.toJson(),
        'title': 'My local edit',
      });
      final data = PlannerBackup.parse(await PlannerBackup.export(source));
      expect(await target.importMissingDocuments(data), 1);
      expect(await target.importMissingDocuments(data), 0);
      final tasks = {
        for (final item in await target.readAll(Collections.tasks))
          item['id']: item['title'],
      };
      expect(tasks, {original.id: 'My local edit', missing.id: 'Missing'});
      expect(
        () => PlannerBackup.parse(
          '{"format":"supercalendar-planner","version":1,'
          '"collections":{"tasks":[{"id":"same"},{"id":"same"}]}}',
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'onboarding starts empty on a new install and sample data is opt-in',
    () async {
      for (final demo in [false, true]) {
        final app = AppState(store: MemoryDocumentStore(), clock: () => now);
        addTearDown(app.dispose);
        await app.load(seedDemoData: false);
        expect(app.tasks.items, isEmpty);
        expect(app.events.items, isEmpty);
        app.finishOnboarding('Mia', useDemoData: demo);
        await app.flush();
        expect(app.tasks.items.isNotEmpty, demo);
        expect(app.events.items.isNotEmpty, demo);
      }
    },
  );

  test('calendar visibility also filters schedule notifications', () async {
    final store = MemoryDocumentStore();
    await store.put(
      Collections.settings,
      AppSettings.id,
      AppSettings(seeded: true, visibleCalendarIds: ['visible']).toJson(),
    );
    final app = AppState(store: store, clock: () => now);
    addTearDown(app.dispose);
    await app.load();
    app.events.setSystemEvents([
      for (final id in ['visible', 'hidden'])
        CalendarEvent(
          id: id,
          title: id,
          calendarId: id,
          source: CalendarEvent.sourceSystem,
          startTime: now,
          endTime: now.add(const Duration(hours: 1)),
        ),
    ]);
    expect(app.lockScreenContent.events.map((event) => event.id), ['visible']);
  });

  test(
    'overnight repeats use the original occurrence for both dates',
    () async {
      final store = MemoryDocumentStore();
      final exceptions = EventExceptionRepository(store);
      final events = EventRepository(store, exceptions: exceptions);
      addTearDown(exceptions.dispose);
      addTearDown(events.dispose);
      final night = DateTime(2026, 11, 27);
      final morning = DateTime(2026, 11, 28);
      final event = CalendarEvent(
        id: 'night',
        title: 'Night shift',
        repeatRule: 'FREQ=WEEKLY',
        startTime: DateTime(2026, 11, 27, 23),
        endTime: DateTime(2026, 11, 28, 1),
      );
      events.add(event);
      for (final day in [night, morning]) {
        expect(events.on(day).single.originalOccurrenceDate, night);
      }
      final midnight = CalendarEvent(
        id: 'midnight',
        title: 'Ends at midnight',
        startTime: event.startTime,
        endTime: morning,
      );
      expect(midnight.overlapsDay(morning), isFalse);
      events.deleteScope(event, DeleteScope.one, occurrenceDate: night);
      expect(events.on(night), isEmpty);
      expect(events.on(morning), isEmpty);
      expect(
        events.on(DateTime(2026, 12, 5)).single.originalOccurrenceDate,
        DateTime(2026, 12, 4),
      );
      await exceptions.flush();
      await events.flush();
    },
  );
}
