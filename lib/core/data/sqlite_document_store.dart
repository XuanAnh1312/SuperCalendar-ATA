import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:flutter_application/core/data/document_store.dart';

/// SQLite database on the device: one table per collection, each row holding
/// a model as JSON keyed by its id.
///
/// Schema versioning:
///   v1 – initial tables: users, settings, events, tasks, notes, habits,
///         themes, templates, purchases, layouts
///   v2 – added: habit_occurrences, goals, event_exceptions
class SqliteDocumentStore implements DocumentStore {
  SqliteDocumentStore._(this._db);

  static const _fileName = 'supercalendar.db';

  /// Increment this whenever new tables are added so [_onUpgrade] runs on
  /// existing installs.
  static const _version = 2;

  final Database _db;

  static Future<SqliteDocumentStore> open() async {
    final path = p.join(await getDatabasesPath(), _fileName);
    final db = await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return SqliteDocumentStore._(db);
  }

  /// Creates every table from scratch on a fresh install.
  static Future<void> _onCreate(Database db, int version) async {
    for (final table in Collections.all) {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS $table '
        '(id TEXT PRIMARY KEY, data TEXT NOT NULL)',
      );
    }
  }

  /// Migrates an existing database to [_version] without losing data.
  ///
  /// Each migration block is additive: only creates tables / columns that
  /// don't already exist.
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // v1 → v2: add habit_occurrences, goals, event_exceptions
    if (oldVersion < 2) {
      const newTables = [
        Collections.habitOccurrences,
        Collections.goals,
        Collections.eventExceptions,
      ];
      for (final table in newTables) {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS $table '
          '(id TEXT PRIMARY KEY, data TEXT NOT NULL)',
        );
      }
    }
    // Future migrations go here:
    // if (oldVersion < 3) { ... }
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
    return _db.insert(
      collection,
      {'id': id, 'data': jsonEncode(data)},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String collection, String id) {
    return _db.delete(collection, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> close() => _db.close();
}
