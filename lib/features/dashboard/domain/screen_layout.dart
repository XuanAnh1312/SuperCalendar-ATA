/// Widgets that can be placed on the home dashboard or the lock screen.
abstract final class WidgetType {
  static const todo = 'todo';
  static const habits = 'habits';
  static const week = 'week';
  static const goals = 'goals';
  static const quickNote = 'quick_note';
  static const snapshot = 'snapshot';
  static const schedule = 'schedule';

  static const home = [todo, habits, week, goals, quickNote, snapshot];
  static const lock = [schedule, todo, quickNote];

  static const labels = {
    todo: 'To-do',
    habits: 'Habits',
    week: 'This week',
    goals: 'Goals',
    quickNote: 'Quick Note',
    snapshot: 'Month snapshot',
    schedule: 'Schedule',
  };
}

class LayoutItem {
  LayoutItem(this.type, {this.visible = true, this.wide = false});

  factory LayoutItem.fromJson(Map<String, dynamic> json) => LayoutItem(
    json['type'] as String,
    visible: json['visible'] as bool? ?? true,
    wide: json['wide'] as bool? ?? false,
  );

  final String type;
  bool visible;

  /// Full-width when true; otherwise it shares a row with its neighbor.
  bool wide;

  LayoutItem copy() => LayoutItem(type, visible: visible, wide: wide);

  Map<String, dynamic> toJson() => {
    'type': type,
    'visible': visible,
    'wide': wide,
  };
}

/// Which widgets a screen shows, in what order and at what size.
class ScreenLayout {
  ScreenLayout({
    required this.id,
    required this.items,
    this.preset = presetDefault,
    this.backgroundPath,
  });

  factory ScreenLayout.fromJson(Map<String, dynamic> json) => ScreenLayout(
    id: json['id'] as String,
    items: [
      for (final item in (json['items'] as List?) ?? const [])
        LayoutItem.fromJson((item as Map).cast<String, dynamic>()),
    ],
    preset: json['preset'] as String? ?? presetCustom,
    backgroundPath: json['backgroundPath'] as String?,
  );

  static const home = 'home';
  static const lock = 'lock';

  static const presetDefault = 'Balanced';
  static const presetFocus = 'Focus';
  static const presetPlanner = 'Planner';
  static const presetCustom = 'Custom';

  /// The layouts available to every user.
  static const presets = [presetDefault, presetFocus, presetPlanner];

  final String id;
  List<LayoutItem> items;

  /// Name of the preset in use, or [presetCustom] after free-form edits.
  String preset;

  /// Background image chosen by a VIP user; null for the theme background.
  String? backgroundPath;

  List<LayoutItem> get visibleItems =>
      items.where((item) => item.visible).toList();

  bool shows(String type) =>
      items.any((item) => item.type == type && item.visible);

  /// Items of a preset layout for the screen [id].
  static List<LayoutItem> presetItems(String id, String preset) {
    LayoutItem on(String type, {bool wide = false}) =>
        LayoutItem(type, wide: wide);
    LayoutItem off(String type, {bool wide = false}) =>
        LayoutItem(type, visible: false, wide: wide);

    if (id == lock) {
      return switch (preset) {
        presetFocus => [
          on(WidgetType.todo, wide: true),
          on(WidgetType.schedule, wide: true),
          off(WidgetType.quickNote, wide: true),
        ],
        presetPlanner => [
          on(WidgetType.schedule, wide: true),
          on(WidgetType.quickNote, wide: true),
          off(WidgetType.todo, wide: true),
        ],
        _ => [
          on(WidgetType.schedule, wide: true),
          on(WidgetType.todo, wide: true),
          on(WidgetType.quickNote, wide: true),
        ],
      };
    }
    return switch (preset) {
      presetFocus => [
        on(WidgetType.todo, wide: true),
        on(WidgetType.week, wide: true),
        on(WidgetType.quickNote, wide: true),
        off(WidgetType.habits),
        off(WidgetType.goals),
        off(WidgetType.snapshot, wide: true),
      ],
      presetPlanner => [
        on(WidgetType.week, wide: true),
        on(WidgetType.snapshot, wide: true),
        on(WidgetType.todo),
        on(WidgetType.habits),
        off(WidgetType.goals),
        off(WidgetType.quickNote),
      ],
      _ => [
        on(WidgetType.todo),
        on(WidgetType.habits),
        on(WidgetType.week, wide: true),
        on(WidgetType.goals),
        on(WidgetType.quickNote),
        on(WidgetType.snapshot, wide: true),
      ],
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': [for (final item in items) item.toJson()],
    'preset': preset,
    'backgroundPath': backgroundPath,
  };
}
