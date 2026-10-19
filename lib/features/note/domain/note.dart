import 'package:flutter_application/core/data/repository.dart';

/// A user-written note (§5.14).
///
/// The Quick Note is a special singleton kept under [quickId]; all other
/// notes are regular notes displayed in the Notes list.  Only one Quick Note
/// may be active at a time (BR-09).
class Note {
  Note({
    required this.id,
    this.title = '',
    this.content = '',
    this.color,
    this.isPinned = false,
    this.isQuickNote = false,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory Note.fromJson(Map<String, dynamic> json) {
    final created = parseDate(json['createdAt']) ?? DateTime.now();
    // Backwards-compatible: old Quick Note used id == quickId with no flag
    final id = json['id'] as String;
    final isQuickFlagSet = json['isQuickNote'] as bool? ?? false;
    return Note(
      id: id,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      color: json['color'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      isQuickNote: isQuickFlagSet || id == quickId,
      createdAt: created,
      updatedAt: parseDate(json['updatedAt']) ?? created,
    );
  }

  /// Id of the single Quick Note shown on the dashboard, lock screen and
  /// the notification (BR-09).
  static const quickId = 'quick';

  final String id;
  String title;

  /// Plain-text content.  Quick Note is capped at 500 characters (FR-11.02).
  String content;

  /// Optional hex colour string (e.g. `'#FFD6E0'`) for the note card.
  String? color;

  /// Pinned notes appear at the top of the list.
  bool isPinned;

  /// True for the single active Quick Note (BR-09).
  bool isQuickNote;

  final DateTime createdAt;
  DateTime updatedAt;

  // ---------------------------------------------------------------------------
  // Derived helpers

  bool get isQuick => isQuickNote || id == quickId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'color': color,
    'isPinned': isPinned,
    'isQuickNote': isQuickNote,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
