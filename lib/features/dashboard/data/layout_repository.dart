import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/features/dashboard/domain/screen_layout.dart';

/// Widget arrangement of the home dashboard and the lock screen.
class LayoutRepository extends Repository<ScreenLayout> {
  LayoutRepository(DocumentStore store) : super(store, Collections.layouts);

  @override
  ScreenLayout decode(Map<String, dynamic> json) => ScreenLayout.fromJson(json);

  @override
  Map<String, dynamic> encode(ScreenLayout item) => item.toJson();

  @override
  String idOf(ScreenLayout item) => item.id;

  @override
  void afterLoad() {
    // Guarantee both layouts exist and know every widget type, so a widget
    // added in a later version shows up (hidden) in the editor.
    for (final id in [ScreenLayout.home, ScreenLayout.lock]) {
      final layout = items.where((l) => l.id == id).firstOrNull;
      if (layout == null) {
        items.add(_fresh(id));
        continue;
      }
      final types = id == ScreenLayout.home ? WidgetType.home : WidgetType.lock;
      layout.items.removeWhere((item) => !types.contains(item.type));
      for (final type in types) {
        if (!layout.items.any((item) => item.type == type)) {
          layout.items.add(LayoutItem.sized(type, visible: false));
        }
      }
    }
  }

  ScreenLayout _fresh(String id) => ScreenLayout(
    id: id,
    items: ScreenLayout.presetItems(id, ScreenLayout.presetDefault),
    wallpaper: Wallpaper.defaultFor(id),
  );

  ScreenLayout get home => of(ScreenLayout.home);
  ScreenLayout get lock => of(ScreenLayout.lock);

  ScreenLayout of(String id) {
    var layout = items.where((l) => l.id == id).firstOrNull;
    if (layout == null) {
      layout = _fresh(id);
      items.add(layout);
    }
    return layout;
  }

  void applyPreset(String id, String preset) {
    of(id).applyPreset(preset);
    _save(id);
  }

  void setVisible(String id, String type, bool visible) {
    final layout = of(id);
    if (visible) {
      final item = layout.item(type);
      layout.place(type, item.x, item.y);
    } else {
      layout.hide(type);
    }
    _save(id);
  }

  /// FR-04: stores the draft edited in Edit Your Screen when Done is pressed.
  void save(ScreenLayout layout) {
    final index = items.indexWhere((l) => l.id == layout.id);
    if (index < 0) {
      items.add(layout);
    } else {
      items[index] = layout;
    }
    _save(layout.id);
  }

  void setBackground(String id, String? path) {
    of(id).backgroundPath = path;
    _save(id);
  }

  void _save(String id) {
    persist(of(id));
    notifyListeners();
  }
}
