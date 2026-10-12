import 'package:flutter/foundation.dart';

import 'package:flutter_application/core/data/document_store.dart';

int _idCounter = 0;

/// Unique id for a new record, e.g. `task_1791800140684123_4`.
String newId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

/// Base of the feature repositories: an in-memory list mirrored to one
/// collection of the [DocumentStore]. Reads are synchronous; writes update
/// the list, notify listeners and are queued to the store.
abstract class Repository<T> extends ChangeNotifier {
  Repository(this.store, this.collection);

  final DocumentStore store;
  final String collection;
  final List<T> items = [];

  Future<void> _pending = Future.value();

  T decode(Map<String, dynamic> json);
  Map<String, dynamic> encode(T item);
  String idOf(T item);

  /// Replaces the list with what is stored on the device.
  Future<void> load() async {
    await flush();
    final docs = await store.readAll(collection);
    items
      ..clear()
      ..addAll(docs.map(decode));
    afterLoad();
    notifyListeners();
  }

  /// Hook for sorting or seeding derived state after [load].
  @protected
  void afterLoad() {}

  /// Completes when every queued write has reached the store.
  Future<void> flush() => _pending;

  @protected
  void persist(T item) {
    final id = idOf(item);
    final data = encode(item);
    _pending = _pending.then((_) => store.put(collection, id, data));
  }

  @protected
  void erase(T item) {
    final id = idOf(item);
    _pending = _pending.then((_) => store.delete(collection, id));
  }
}

/// `yyyy-mm-dd` key of a calendar day.
String dayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

DateTime? parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
