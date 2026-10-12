import 'package:flutter_application/core/data/repository.dart';

class Note {
  Note({
    required this.id,
    this.title = '',
    this.content = '',
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory Note.fromJson(Map<String, dynamic> json) {
    final created = parseDate(json['createdAt']) ?? DateTime.now();
    return Note(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: created,
      updatedAt: parseDate(json['updatedAt']) ?? created,
    );
  }

  /// Id of the single Quick Note shown on the dashboard, the lock screen and
  /// the notification.
  static const quickId = 'quick';

  final String id;
  String title;
  String content;
  final DateTime createdAt;
  DateTime updatedAt;

  bool get isQuick => id == quickId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
