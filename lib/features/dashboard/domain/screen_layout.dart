/// Widgets that can be placed on the home dashboard or the lock screen.
abstract final class WidgetType {
  static const todo = 'todo';
  static const habits = 'habits';
  static const week = 'week';
  static const goals = 'goals';
  static const quickNote = 'quick_note';
  static const snapshot = 'snapshot';
  static const schedule = 'schedule';
  static const weather = 'weather';

  static const home = [todo, habits, week, goals, quickNote, snapshot, weather];
  static const lock = [schedule, todo, quickNote, week, habits, weather];

  /// Size in grid cells (columns × rows) a widget gets when first placed.
  /// The four wallpaper widgets match the Personalize studio design: 7 or 5
  /// of the 12 columns, 4 rows.
  static (int, int) defaultSize(String type) => switch (type) {
    schedule => (12, 4),
    todo => (7, 5),
    week || quickNote => (7, 4),
    habits || weather => (5, 4),
    goals => (5, 3),
    _ => (12, 3),
  };

  static const labels = {
    todo: 'To-do',
    habits: 'Habits',
    week: 'This week',
    goals: 'Goals',
    quickNote: 'Quick Note',
    snapshot: 'Month snapshot',
    schedule: 'Schedule',
    weather: 'Weather',
  };
}

/// Built-in wallpapers. Soft morning is the artwork from the design; the
/// others are drawn from theme colors. A photo picked by a VIP user goes in
/// `backgroundPath`.
abstract final class Wallpaper {
  static const theme = 'theme';
  static const softMorning = 'soft_morning';
  static const quietGarden = 'quiet_garden';
  static const lavenderHaze = 'lavender_haze';

  static const gradients = [softMorning, quietGarden, lavenderHaze];

  /// Image of [softMorning].
  static const softMorningAsset = 'assets/wallpapers/soft_morning.jpg';

  /// The lock screen starts on the design's artwork, home on the theme.
  static String defaultFor(String layoutId) =>
      layoutId == ScreenLayout.lock ? softMorning : theme;

  static const names = {
    theme: 'Theme background',
    softMorning: 'Soft morning',
    quietGarden: 'Quiet garden',
    lavenderHaze: 'Lavender haze',
  };

  /// A plain color, by index of `AppColors.accentSurfaces`.
  static String solid(int accent) => 'solid_$accent';

  static int? solidIndex(String key) =>
      key.startsWith('solid_') ? int.tryParse(key.substring(6)) : null;
}

/// How a widget card is drawn (Style · Widget style).
abstract final class CardSurface {
  static const soft = 'soft';
  static const solid = 'solid';
  static const outline = 'outline';

  static const all = [soft, solid, outline];

  static const names = {
    soft: 'Soft cards',
    solid: 'Solid cards',
    outline: 'Outline',
  };

  /// The line under the Style options describing the surface.
  static const notes = {
    soft: 'Rounded corners · 16 px · Quiet border',
    solid: 'Rounded corners · 16 px · No border',
    outline: 'Rounded corners · 16 px · Clear fill, fine border',
  };
}

/// Result of putting a widget on the grid.
enum PlaceResult {
  /// Placed exactly where it was dropped.
  exact,

  /// AC-09: the spot was not valid; moved to the nearest free one.
  snapped,

  /// No free spot big enough; nothing changed.
  full,
}

/// One widget on a screen: its grid cell (x, y), size in cells (w × h) and
/// the Style choices: color (index of `AppColors.accents`), text size in px
/// and card surface. Null style values keep the widget's own look.
class LayoutItem {
  LayoutItem(
    this.type, {
    this.visible = true,
    this.x = 0,
    this.y = 0,
    this.w = 2,
    this.h = 2,
    this.color,
    this.textSize,
    this.surface,
  });

  /// Older layouts stored only the order; [ScreenLayout] packs those onto
  /// the grid at each widget's default size when `x` is missing.
  factory LayoutItem.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final (w, h) = WidgetType.defaultSize(type);
    return LayoutItem(
      type,
      visible: json['visible'] as bool? ?? true,
      x: json['x'] as int? ?? 0,
      y: json['y'] as int? ?? 0,
      w: json['w'] as int? ?? w,
      h: json['h'] as int? ?? h,
      color: json['color'] as int?,
      textSize: json['textSize'] as int?,
      surface: json['surface'] as String?,
    );
  }

  /// A widget of [type] at its default size.
  factory LayoutItem.sized(String type, {bool visible = true}) {
    final (w, h) = WidgetType.defaultSize(type);
    return LayoutItem(type, visible: visible, w: w, h: h);
  }

  final String type;
  bool visible;
  int x;
  int y;
  int w;
  int h;
  int? color;
  int? textSize;
  String? surface;

  bool overlaps(int ox, int oy, int ow, int oh) =>
      x < ox + ow && ox < x + w && y < oy + oh && oy < y + h;

  LayoutItem copy() => LayoutItem(
    type,
    visible: visible,
    x: x,
    y: y,
    w: w,
    h: h,
    color: color,
    textSize: textSize,
    surface: surface,
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'visible': visible,
    'x': x,
    'y': y,
    'w': w,
    'h': h,
    'color': color,
    'textSize': textSize,
    'surface': surface,
  };
}

/// Which widgets a screen shows, where on its grid, and its wallpaper
/// (DashboardLayout + WidgetPlacement, README 5.17–5.18).
class ScreenLayout {
  ScreenLayout({
    required this.id,
    required this.items,
    this.preset = presetDefault,
    this.backgroundPath,
    this.wallpaper = Wallpaper.theme,
  });

  factory ScreenLayout.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    final items = [
      for (final item in rawItems)
        LayoutItem.fromJson((item as Map).cast<String, dynamic>()),
    ];
    final id = json['id'] as String;
    // Layouts saved for another grid (or before the grid existed) keep their
    // order and colors; positions, sizes and wallpaper start from defaults.
    final legacy = json['grid'] != columns;
    return ScreenLayout(
      id: id,
      items: legacy
          ? pack(id, [
              for (final item in items)
                LayoutItem.sized(item.type, visible: item.visible)
                  ..color = item.color,
            ])
          : items,
      preset: _renamed[json['preset']] ?? json['preset'] as String? ??
          presetCustom,
      backgroundPath: json['backgroundPath'] as String?,
      wallpaper: legacy
          ? Wallpaper.defaultFor(id)
          : json['wallpaper'] as String? ?? Wallpaper.defaultFor(id),
    );
  }

  static const home = 'home';
  static const lock = 'lock';

  /// 12 columns: 7 + 5 give the two widget widths of the design.
  static const columns = 12;

  /// Smallest widget, in cells.
  static const minWidth = 3;
  static const minHeight = 2;

  /// Rows of the grid: what fits under the lock screen clock, and one phone
  /// screen of the home dashboard.
  static int rowsOf(String id) => id == lock ? 9 : 16;

  /// Style · Layout: widget width in columns.
  static const widths = {'Stacked': 5, 'Two columns': 7, 'Wide': 12};

  /// Style · Widget size: widget height in rows.
  static const heights = {'S': 3, 'M': 4, 'L': 5};

  /// Layouts of "Find your calm" (Personalize 20).
  static const presetDefault = 'Calm Week';
  static const presetFocus = 'Simple Day';
  static const presetPlanner = 'Gentle Focus';
  static const presetFocusedWork = 'Focused Work';
  static const presetDailyReset = 'Daily Reset';
  static const presetCustom = 'Custom';

  /// The layouts available to every user (AC-30: three free).
  static const presets = [presetDefault, presetFocus, presetPlanner];

  /// Layouts that need VIP.
  static const vipPresets = [presetFocusedWork, presetDailyReset];

  /// Names used before the layouts were renamed after the design.
  static const _renamed = {
    'Balanced': presetDefault,
    'Focus': presetFocus,
    'Planner': presetPlanner,
  };

  final String id;
  List<LayoutItem> items;

  /// Name of the preset in use, or [presetCustom] after free-form edits.
  String preset;

  /// Background photo chosen by a VIP user; drawn over [wallpaper].
  String? backgroundPath;

  /// Key of a [Wallpaper].
  String wallpaper;

  int get rows => rowsOf(id);

  List<LayoutItem> get visibleItems =>
      items.where((item) => item.visible).toList();

  bool shows(String type) =>
      items.any((item) => item.type == type && item.visible);

  LayoutItem item(String type) => items.firstWhere((i) => i.type == type);

  /// Independent copy, edited as a draft in Edit Your Screen.
  ScreenLayout copy() => ScreenLayout(
    id: id,
    items: [for (final item in items) item.copy()],
    preset: preset,
    backgroundPath: backgroundPath,
    wallpaper: wallpaper,
  );

  /// True when the area is on the grid and no other visible widget is there.
  bool isFree(int x, int y, int w, int h, {LayoutItem? ignore}) {
    if (x < 0 || y < 0 || x + w > columns || y + h > rows) return false;
    return !items.any(
      (o) => o.visible && !identical(o, ignore) && o.overlaps(x, y, w, h),
    );
  }

  /// Free spot for a w × h widget closest to (x, y), or null when full.
  (int, int)? nearestFree(int w, int h, int x, int y, {LayoutItem? ignore}) {
    (int, int)? best;
    var bestDistance = 1 << 30;
    for (var cy = 0; cy + h <= rows; cy++) {
      for (var cx = 0; cx + w <= columns; cx++) {
        if (!isFree(cx, cy, w, h, ignore: ignore)) continue;
        final distance = (cx - x) * (cx - x) + (cy - y) * (cy - y);
        if (distance < bestDistance) {
          best = (cx, cy);
          bestDistance = distance;
        }
      }
    }
    return best;
  }

  /// FR-04 / AC-08: shows [type] with its top-left cell at (x, y).
  /// AC-09: off the grid (e.g. on the clock) or on another widget, it moves
  /// to the nearest free spot instead.
  PlaceResult place(String type, int x, int y) {
    final target = item(type);
    final w = target.w.clamp(1, columns);
    final h = target.h.clamp(1, rows);
    final spot = isFree(x, y, w, h, ignore: target)
        ? (x, y)
        : nearestFree(
            w,
            h,
            x.clamp(0, columns - w),
            y.clamp(0, rows - h),
            ignore: target,
          );
    if (spot == null) return PlaceResult.full;
    target
      ..visible = true
      ..x = spot.$1
      ..y = spot.$2
      ..w = w
      ..h = h;
    preset = presetCustom;
    return spot == (x, y) ? PlaceResult.exact : PlaceResult.snapped;
  }

  /// Changes the area of a visible widget; refused when it would leave the
  /// grid or cover another widget.
  bool resize(String type, int x, int y, int w, int h) {
    final target = item(type);
    if (w < minWidth ||
        h < minHeight ||
        !isFree(x, y, w, h, ignore: target)) {
      return false;
    }
    target
      ..x = x
      ..y = y
      ..w = w
      ..h = h;
    preset = presetCustom;
    return true;
  }

  void hide(String type) {
    item(type).visible = false;
    preset = presetCustom;
  }

  void setColor(String type, int? color) {
    item(type).color = color;
    preset = presetCustom;
  }

  /// Style choices of one widget; null keeps the widget's own look.
  void setStyle(String type, {int? color, int? textSize, String? surface}) {
    item(type)
      ..color = color
      ..textSize = textSize
      ..surface = surface;
    preset = presetCustom;
  }

  void applyPreset(String name) {
    items = presetItems(id, name);
    preset = name;
  }

  /// Lays visible [items] out in order, first free spot from the top-left.
  /// A widget that does not fit is narrowed before it is left hidden.
  static List<LayoutItem> pack(String id, List<LayoutItem> items) {
    final layout = ScreenLayout(id: id, items: []);
    for (final item in items) {
      layout.items.add(item);
      if (!item.visible) continue;
      var spot = layout._firstFree(item);
      while (spot == null && item.w > 5) {
        item.w -= 2;
        spot = layout._firstFree(item);
      }
      if (spot == null) {
        item.visible = false;
      } else {
        item
          ..x = spot.$1
          ..y = spot.$2;
      }
    }
    return layout.items;
  }

  (int, int)? _firstFree(LayoutItem item) {
    for (var y = 0; y + item.h <= rows; y++) {
      for (var x = 0; x + item.w <= columns; x++) {
        if (isFree(x, y, item.w, item.h, ignore: item)) return (x, y);
      }
    }
    return null;
  }

  /// Items of a preset layout for the screen [id].
  static List<LayoutItem> presetItems(String id, String preset) {
    LayoutItem on(String type) => LayoutItem.sized(type);
    LayoutItem off(String type) => LayoutItem.sized(type, visible: false);

    if (id == lock) {
      return pack(id, switch (preset) {
        presetFocus => [
          on(WidgetType.todo),
          on(WidgetType.schedule),
          off(WidgetType.quickNote),
          off(WidgetType.week),
          off(WidgetType.habits),
          off(WidgetType.weather),
        ],
        presetPlanner => [
          on(WidgetType.schedule),
          on(WidgetType.week),
          on(WidgetType.weather),
          off(WidgetType.todo),
          off(WidgetType.quickNote),
          off(WidgetType.habits),
        ],
        presetFocusedWork => [
          on(WidgetType.schedule),
          on(WidgetType.quickNote),
          on(WidgetType.weather),
          off(WidgetType.todo),
          off(WidgetType.week),
          off(WidgetType.habits),
        ],
        presetDailyReset => [
          on(WidgetType.habits),
          on(WidgetType.quickNote),
          on(WidgetType.week),
          off(WidgetType.schedule),
          off(WidgetType.todo),
          off(WidgetType.weather),
        ],
        // The design's lock screen: calendar, weather, mini note, habits.
        _ => [
          on(WidgetType.week),
          on(WidgetType.weather),
          on(WidgetType.quickNote),
          on(WidgetType.habits),
          off(WidgetType.schedule),
          off(WidgetType.todo),
        ],
      });
    }
    return pack(id, switch (preset) {
      presetFocus => [
        on(WidgetType.todo),
        on(WidgetType.week),
        on(WidgetType.quickNote),
        off(WidgetType.habits),
        off(WidgetType.goals),
        off(WidgetType.snapshot),
        off(WidgetType.weather),
      ],
      presetPlanner => [
        on(WidgetType.week),
        on(WidgetType.snapshot),
        on(WidgetType.todo),
        on(WidgetType.habits),
        off(WidgetType.goals),
        off(WidgetType.quickNote),
        off(WidgetType.weather),
      ],
      presetFocusedWork => [
        on(WidgetType.todo),
        on(WidgetType.goals),
        on(WidgetType.week),
        on(WidgetType.quickNote),
        off(WidgetType.habits),
        off(WidgetType.snapshot),
        off(WidgetType.weather),
      ],
      presetDailyReset => [
        on(WidgetType.habits),
        on(WidgetType.weather),
        on(WidgetType.quickNote),
        on(WidgetType.week),
        off(WidgetType.todo),
        off(WidgetType.goals),
        off(WidgetType.snapshot),
      ],
      _ => [
        on(WidgetType.todo),
        on(WidgetType.habits),
        on(WidgetType.week),
        on(WidgetType.goals),
        on(WidgetType.quickNote),
        on(WidgetType.snapshot),
        off(WidgetType.weather),
      ],
    });
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'items': [for (final item in items) item.toJson()],
    'preset': preset,
    'backgroundPath': backgroundPath,
    'wallpaper': wallpaper,
    // Marks positions as cells of this grid.
    'grid': columns,
  };
}
