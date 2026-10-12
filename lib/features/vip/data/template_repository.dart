import 'package:flutter/foundation.dart';

import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/features/vip/domain/template.dart';

/// Themes, store templates and the purchase history, all kept locally.
class TemplateRepository extends ChangeNotifier {
  TemplateRepository(this.store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DocumentStore store;
  final DateTime Function() _clock;

  final List<Template> templates = [];
  final List<Purchase> purchases = [];
  final List<AppThemeData> customThemes = [];

  Future<void> _pending = Future.value();

  Future<void> load() async {
    await flush();
    templates
      ..clear()
      ..addAll(
        (await store.readAll(Collections.templates)).map(Template.fromJson),
      );
    purchases
      ..clear()
      ..addAll(
        (await store.readAll(Collections.purchases)).map(Purchase.fromJson),
      );
    customThemes
      ..clear()
      ..addAll(
        (await store.readAll(Collections.themes)).map(AppThemeData.fromJson),
      );
    notifyListeners();
  }

  Future<void> flush() => _pending;

  void _put(String collection, String id, Map<String, dynamic> data) {
    _pending = _pending.then((_) => store.put(collection, id, data));
  }

  // ---- Themes -------------------------------------------------------------

  List<AppThemeData> get themes => [...builtInThemes, ...customThemes];

  /// The theme with [id]; falls back to the default when it is unknown.
  AppThemeData theme(String id) =>
      themes.firstWhere((t) => t.id == id, orElse: () => builtInThemes.first);

  void saveTheme(AppThemeData theme) {
    customThemes
      ..removeWhere((t) => t.id == theme.id)
      ..add(theme);
    _put(Collections.themes, theme.id, theme.toJson());
    notifyListeners();
  }

  // ---- Templates ----------------------------------------------------------

  Template? byId(String id) {
    for (final template in templates) {
      if (template.id == id) return template;
    }
    return null;
  }

  /// Templates listed in the store.
  List<Template> get published => templates.where((t) => t.published).toList();

  List<Template> createdBy(String userId) =>
      templates.where((t) => t.creatorId == userId).toList();

  /// True when [userId] may apply [template]: it is free, theirs, or bought.
  bool owns(String userId, Template template) {
    if (template.price == 0 || template.creatorId == userId) return true;
    return purchases.any(
      (p) =>
          p.userId == userId &&
          p.templateId == template.id &&
          p.status == PaymentResult.success,
    );
  }

  List<Template> ownedBy(String userId) =>
      templates.where((t) => owns(userId, t)).toList();

  void saveTemplate(Template template) {
    templates
      ..removeWhere((t) => t.id == template.id)
      ..add(template);
    // The template's theme is stored too, so it can be selected by id.
    saveTheme(template.themeData);
    _put(Collections.templates, template.id, template.toJson());
    notifyListeners();
  }

  void setPublished(Template template, bool published) {
    template.published = published;
    _put(Collections.templates, template.id, template.toJson());
    notifyListeners();
  }

  /// Records the outcome of a payment for [productId].
  Purchase recordPurchase({
    required String userId,
    required String productId,
    required int price,
    required PaymentResult result,
  }) {
    final purchase = Purchase(
      id: newId('purchase'),
      userId: userId,
      templateId: productId,
      price: price,
      status: result,
      purchasedAt: _clock(),
    );
    purchases.add(purchase);
    _put(Collections.purchases, purchase.id, purchase.toJson());
    notifyListeners();
    return purchase;
  }
}
