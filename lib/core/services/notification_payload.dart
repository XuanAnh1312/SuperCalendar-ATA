import 'dart:convert';

class NotificationTarget {
  const NotificationTarget(
    this.type,
    this.id, {
    this.snoozed = false,
    this.reminderLead,
    this.occurrenceDate,
    this.occurrenceStart,
  });

  static const task = 'task';
  static const event = 'event';
  static const habit = 'habit';
  static const lockScreen = 'lock';
  static const quickNote = 'quick_note';
  static const schedule = 'schedule';
  final String type;
  final String id;
  final bool snoozed;
  final int? reminderLead;
  final DateTime? occurrenceDate;
  final DateTime? occurrenceStart;

  String encode() => jsonEncode({
    'type': type,
    'id': id,
    if (reminderLead != null) 'reminderLead': reminderLead,
    if (snoozed) 'snoozed': true,
    if (occurrenceDate != null)
      'occurrenceDate': occurrenceDate!.toIso8601String(),
    if (occurrenceStart != null)
      'occurrenceStart': occurrenceStart!.toIso8601String(),
  });

  static NotificationTarget? decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      return NotificationTarget(
        data['type'] as String,
        data['id'] as String,
        reminderLead: data['reminderLead'] as int?,
        snoozed: data['snoozed'] as bool? ?? false,
        occurrenceDate: DateTime.tryParse(
          data['occurrenceDate'] as String? ?? '',
        ),
        occurrenceStart: DateTime.tryParse(
          data['occurrenceStart'] as String? ?? '',
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

abstract final class NotificationActions {
  static const done = 'done';
  static const snooze = 'snooze';
  static const skip = 'skip';
  static const addTask = 'add_task';
  static const saveNote = 'save_note';
  static const openApp = 'open_app';
  static const schedule = 'schedule';
}
