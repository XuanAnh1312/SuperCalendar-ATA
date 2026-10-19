import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/data/repository.dart';
import 'package:flutter_application/features/vip/domain/purchase.dart';

export 'package:flutter_application/features/vip/domain/purchase.dart';

/// A purchasable bundle of appearance settings (§5.16 WidgetTemplate).
///
/// Templates are stored in [Collections.templates].  Owning a template and
/// applying a template are separate actions (BR-07).  Free templates
/// ([price] == 0) are available to everyone; paid templates require a
/// successful [Purchase] or VIP status.
class Template {
  Template({
    required this.id,
    required this.name,
    this.description = '',
    required this.creatorId,
    this.price = 0,
    this.preview = '🎨',
    required this.themeData,
    this.isSystem = false,
    this.isPremium = false,
    this.status = TemplateStatus.published,
    this.category,
    this.previewImagePath,
    this.published = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Template.fromJson(Map<String, dynamic> json) {
    final created = parseDate(json['createdAt']) ?? DateTime.now();
    return Template(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      creatorId: json['creatorId'] as String? ?? systemCreator,
      price: json['price'] as int? ?? 0,
      preview: json['preview'] as String? ?? '🎨',
      themeData: AppThemeData.fromJson(
        (json['themeData'] as Map).cast<String, dynamic>(),
      ),
      isSystem: json['isSystem'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      status: TemplateStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TemplateStatus.published,
      ),
      category: json['category'] as String?,
      previewImagePath: json['previewImagePath'] as String?,
      published: json['published'] as bool? ?? false,
      createdAt: created,
      updatedAt: parseDate(json['updatedAt']) ?? created,
    );
  }

  /// Creator id for templates that ship with the app.
  static const systemCreator = 'supercalendar';

  final String id;
  String name;
  String description;
  final String creatorId;

  /// Price in VND; 0 means free.
  int price;

  /// Emoji or short string shown as the template's thumbnail.
  String preview;

  AppThemeData themeData;

  /// True for templates bundled with the app (not user-created).
  bool isSystem;

  /// True when the template requires VIP or a paid purchase to apply.
  bool isPremium;

  TemplateStatus status;

  /// Optional category label for marketplace browsing.
  String? category;

  /// Local path to a preview screenshot.
  String? previewImagePath;

  /// Legacy field: true when the template is visible in the store.
  bool published;

  final DateTime createdAt;
  DateTime updatedAt;

  // ---------------------------------------------------------------------------
  // Derived helpers

  String get priceLabel => price == 0 ? 'Free' : '${_thousands(price)}đ';

  bool get isFree => price == 0;

  static String _thousands(int value) {
    final digits = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'creatorId': creatorId,
    'price': price,
    'preview': preview,
    'themeData': themeData.toJson(),
    'isSystem': isSystem,
    'isPremium': isPremium,
    'status': status.name,
    'category': category,
    'previewImagePath': previewImagePath,
    'published': published,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

enum TemplateStatus { draft, published, unpublished }
