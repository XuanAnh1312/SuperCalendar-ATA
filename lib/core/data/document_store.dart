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

/// In-memory store used by tests. Documents are kept JSON-encoded so a model
/// that cannot be serialized fails here the same way it would on disk.
class MemoryDocumentStore implements DocumentStore {
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
}
