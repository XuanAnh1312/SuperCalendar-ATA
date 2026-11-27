import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_application/core/data/document_store.dart';

/// Serializes local writes and keeps the latest failed operation per document.
/// A write failure must not prevent later documents from being saved.
mixin PersistentWrites on ChangeNotifier {
  DocumentStore get store;

  Future<void> _tail = Future.value();
  final _failed =
      <(String, String), (Map<String, dynamic>?, Object, StackTrace)>{};
  bool _disposed = false;

  bool get hasWriteFailures => _failed.isNotEmpty;

  void putDocument(String collection, String id, Map<String, dynamic> data) {
    // Freeze nested model lists before the caller can mutate them again.
    final snapshot = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    _enqueue((collection, id), snapshot);
  }

  void deleteDocument(String collection, String id) =>
      _enqueue((collection, id), null);

  void _enqueue((String, String) key, Map<String, dynamic>? data) {
    _tail = _tail.then((_) => _write(key, data));
  }

  Future<void> _write((String, String) key, Map<String, dynamic>? data) async {
    final (collection, id) = key;
    final hadFailure = hasWriteFailures;
    try {
      if (data == null) {
        await store.delete(collection, id);
      } else {
        await store.put(collection, id, data);
      }
      _failed.remove(key);
    } catch (error, stack) {
      _failed[key] = (data, error, stack);
    }
    if (!_disposed && hadFailure != hasWriteFailures) notifyListeners();
  }

  Future<void> flush() async {
    await _tail;
    if (_failed.values.firstOrNull case final failure?) {
      Error.throwWithStackTrace(failure.$2, failure.$3);
    }
  }

  Future<void> retryWrites() async {
    _tail = _tail.then((_) async {
      for (final entry in _failed.entries.toList()) {
        await _write(entry.key, entry.value.$1);
      }
    });
    await flush();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
