import 'package:flutter_application/core/data/repository.dart';

/// A time-boxed objective tracked by the user (§5.11).
///
/// Goals are either [GoalType.weekly] or [GoalType.monthly] and are never
/// mixed in the same list (BR-03).  When [current] reaches [target] the
/// status automatically becomes [GoalStatus.completed]; when [periodEnd]
/// passes without reaching the target it becomes [GoalStatus.missed] (BR-11).
class Goal {
  Goal({
    required this.id,
    required this.type,
    required this.title,
    this.icon,
    this.color,
    this.target,
    this.current = 0,
    required this.periodStart,
    required this.periodEnd,
    this.status = GoalStatus.active,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory Goal.fromJson(Map<String, dynamic> json) {
    final created = parseDate(json['createdAt']) ?? DateTime.now();
    return Goal(
      id: json['id'] as String,
      type: GoalType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => GoalType.weekly,
      ),
      title: json['title'] as String? ?? '',
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      target: json['target'] as int?,
      current: json['current'] as int? ?? 0,
      periodStart: parseDate(json['periodStart']) ?? DateTime.now(),
      periodEnd:
          parseDate(json['periodEnd']) ??
          DateTime.now().add(const Duration(days: 7)),
      status: GoalStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => GoalStatus.active,
      ),
      createdAt: created,
      updatedAt: parseDate(json['updatedAt']) ?? created,
    );
  }

  final String id;

  /// Whether this goal spans a [GoalType.weekly] or [GoalType.monthly] period.
  final GoalType type;

  String title;

  /// Optional emoji or icon key shown next to the title.
  String? icon;

  /// Hex colour string (e.g. `#FF7BAC`); null uses the theme accent.
  String? color;

  /// How many times the activity should happen in the period; null means
  /// the goal is binary (done / not done).
  int? target;

  /// Progress counter, starting at 0.
  int current;

  /// Inclusive start of the tracking period (date only, time stripped).
  DateTime periodStart;

  /// Inclusive end of the tracking period (date only, time stripped).
  DateTime periodEnd;

  GoalStatus status;

  final DateTime createdAt;
  DateTime updatedAt;

  // ---------------------------------------------------------------------------
  // Derived helpers

  /// True when the goal is still accepting progress updates.
  bool get isActive => status == GoalStatus.active;

  /// Progress as a fraction in [0, 1]; 0 when [target] is null or zero.
  double get progress {
    final t = target;
    if (t == null || t == 0) return current > 0 ? 1.0 : 0.0;
    return (current / t).clamp(0.0, 1.0);
  }

  /// `"x of y"` label shown on chips; e.g. `"11 of 12"`.
  String get progressLabel {
    final t = target;
    return t != null ? '$current of $t' : '$current';
  }

  /// Re-evaluates [status] against [current], [target] and [periodEnd].
  /// Call this after incrementing [current] or when the date changes (BR-11).
  void recalculate(DateTime today) {
    if (status == GoalStatus.active) {
      final t = target;
      if (t != null && current >= t) {
        status = GoalStatus.completed;
      } else if (DateTime(
        today.year,
        today.month,
        today.day,
      ).isAfter(periodEnd)) {
        status = GoalStatus.missed;
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'icon': icon,
    'color': color,
    'target': target,
    'current': current,
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

enum GoalType { weekly, monthly }

enum GoalStatus { active, completed, missed }
