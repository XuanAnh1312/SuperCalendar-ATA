import 'dart:convert';

/// Names of the collections kept in the local database.
abstract final class Collections {
  static const users = 'users';
  static const settings = 'settings';
  static const events = 'events';
  static const tasks = 'tasks';
  static const notes = 'notes';
  static const habits = 'habits';
  static const habitOccurrences = 'habit_occurrences';
  static const goals = 'goals';
  static const themes = 'themes';
  static const templates = 'templates';
  static const purchases = 'purchases';
  static const layouts = 'layouts';
  static const eventExceptions = 'event_exceptions';

  static const all = [
    users,
    settings,
    events,
    tasks,
    notes,
    habits,
    habitOccurrences,
    goals,
    themes,
    templates,
    purchases,
    layouts,
    eventExceptions,
  ];
}

/// The single local data source. The app, the lock screen and the
/// notification actions all read and write through this interface.
abstract class DocumentStore {
  Future<List<Map<String, dynamic>>> readAll(String collection);

  Future<void> put(String collection, String id, Map<String, dynamic> data);

  Future<void> delete(String collection, String id);

  Future<void> close();
}

/// Consistent reads and an atomic, non-overwriting restore for planner data.
abstract interface class PlannerBackupStore implements DocumentStore {
  Future<Map<String, List<Map<String, dynamic>>>> readPlannerSnapshot(
    List<String> collections,
  );
  Future<int> importMissingDocuments(
    Map<String, List<Map<String, dynamic>>> collections,
  );
}

/// In-memory store used by tests. Documents are kept JSON-encoded so a model
/// that cannot be serialized fails here the same way it would on disk.
class MemoryDocumentStore implements PlannerBackupStore {
  final Map<String, Map<String, String>> _data = {};

  @override
  Future<List<Map<String, dynamic>>> readAll(String collection) async {
    final docs = _data[collection] ?? const <String, String>{};
    return [
      for (final raw in docs.values) jsonDecode(raw) as Map<String, dynamic>,
    ];
  }

  @override
  Future<void> put(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    (_data[collection] ??= {})[id] = jsonEncode(data);
  }

  @override
  Future<void> delete(String collection, String id) async {
    _data[collection]?.remove(id);
  }

  @override
  Future<void> close() async {}

  @override
  Future<Map<String, List<Map<String, dynamic>>>> readPlannerSnapshot(
    List<String> collections,
  ) async => {
    for (final name in collections)
      name: [
        for (final raw in _data[name]?.values ?? const <String>[])
          jsonDecode(raw) as Map<String, dynamic>,
      ],
  };

  @override
  Future<int> importMissingDocuments(
    Map<String, List<Map<String, dynamic>>> collections,
  ) async {
    final encoded = {
      for (final entry in collections.entries)
        entry.key: {
          for (final document in entry.value)
            document['id'] as String: jsonEncode(document),
        },
    };
    var count = 0;
    for (final entry in encoded.entries) {
      final target = _data[entry.key] ??= {};
      for (final document in entry.value.entries) {
        if (!target.containsKey(document.key)) {
          target[document.key] = document.value;
          count++;
        }
      }
    }
    return count;
  }
}
