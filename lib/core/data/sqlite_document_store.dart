import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:flutter_application/core/data/document_store.dart';

/// SQLite database on the device: one table per collection, each row holding
/// a model as JSON keyed by its id.
class SqliteDocumentStore implements DocumentStore {
  SqliteDocumentStore._(this._db);

  static const _fileName = 'supercalendar.db';

  final Database _db;

  static Future<SqliteDocumentStore> open() async {
    final path = p.join(await getDatabasesPath(), _fileName);
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        for (final table in Collections.all) {
          await db.execute(
            'CREATE TABLE $table (id TEXT PRIMARY KEY, data TEXT NOT NULL)',
          );
        }
      },
    );
    return SqliteDocumentStore._(db);
  }

  @override
  Future<List<Map<String, dynamic>>> readAll(String collection) async {
    final rows = await _db.query(collection, orderBy: 'id');
    return [
      for (final row in rows)
        jsonDecode(row['data']! as String) as Map<String, dynamic>,
    ];
  }

  @override
  Future<void> put(String collection, String id, Map<String, dynamic> data) {
    return _db.insert(collection, {
      'id': id,
      'data': jsonEncode(data),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> delete(String collection, String id) {
    return _db.delete(collection, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> close() => _db.close();
}
