import 'dart:convert';

import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/features/calendar/data/event_repository.dart';
import 'package:flutter_application/features/calendar/domain/event.dart';
import 'package:flutter_application/features/calendar/domain/goal.dart';
import 'package:flutter_application/features/calendar/domain/habit.dart';
import 'package:flutter_application/features/note/domain/note.dart';
import 'package:flutter_application/features/todo/domain/task.dart';

/// Portable planner data. Device permissions, account data, purchases and
/// wallpaper files are intentionally outside this format.
abstract final class PlannerBackup {
  static const maxBytes = 16 * 1024 * 1024;
  static final _decoders = <String, Object Function(Map<String, dynamic>)>{
    Collections.events: CalendarEvent.fromJson,
    Collections.eventExceptions: EventException.fromJson,
    Collections.tasks: Task.fromJson,
    Collections.notes: Note.fromJson,
    Collections.habits: Habit.fromJson,
    Collections.habitOccurrences: HabitOccurrence.fromJson,
    Collections.goals: Goal.fromJson,
  };

  static Future<String> export(PlannerBackupStore store) async => jsonEncode({
    'format': 'supercalendar-planner',
    'version': 1,
    'collections': await store.readPlannerSnapshot(_decoders.keys.toList()),
  });

  static Map<String, List<Map<String, dynamic>>> parse(String source) {
    final root = jsonDecode(source);
    if (root is! Map ||
        root['format'] != 'supercalendar-planner' ||
        root['version'] != 1 ||
        root['collections'] is! Map) {
      throw const FormatException('Unsupported planner backup');
    }
    final collections = root['collections'] as Map;
    final result = <String, List<Map<String, dynamic>>>{};
    for (final entry in collections.entries) {
      final decode = _decoders[entry.key];
      if (decode == null || entry.value is! List) {
        throw const FormatException('Invalid planner collection');
      }
      final documents = <Map<String, dynamic>>[];
      final ids = <String>{};
      for (final raw in entry.value as List) {
        if (raw is! Map<String, dynamic> ||
            raw['id'] is! String ||
            (raw['id'] as String).isEmpty ||
            !ids.add(raw['id'] as String)) {
          throw const FormatException('Invalid or duplicate document ID');
        }
        // Validate model shapes before starting a database transaction.
        decode(raw);
        documents.add(raw);
      }
      result[entry.key as String] = documents;
    }
    return result;
  }
}
