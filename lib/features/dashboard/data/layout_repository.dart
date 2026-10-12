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
          layout.items.add(LayoutItem(type, visible: false));
        }
      }
    }
  }

  ScreenLayout _fresh(String id) => ScreenLayout(
    id: id,
    items: ScreenLayout.presetItems(id, ScreenLayout.presetDefault),
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
    of(id)
      ..items = ScreenLayout.presetItems(id, preset)
      ..preset = preset;
    _save(id);
  }

  void setVisible(String id, String type, bool visible) {
    final layout = of(id);
    layout.items.firstWhere((item) => item.type == type).visible = visible;
    layout.preset = ScreenLayout.presetCustom;
    _save(id);
  }

  void setWide(String id, String type, bool wide) {
    final layout = of(id);
    layout.items.firstWhere((item) => item.type == type).wide = wide;
    layout.preset = ScreenLayout.presetCustom;
    _save(id);
  }

  /// [newIndex] is the position after the item at [oldIndex] is removed.
  void reorder(String id, int oldIndex, int newIndex) {
    final layout = of(id);
    layout.items.insert(newIndex, layout.items.removeAt(oldIndex));
    layout.preset = ScreenLayout.presetCustom;
    _save(id);
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
