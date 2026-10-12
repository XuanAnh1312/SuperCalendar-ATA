import 'package:flutter_application/app/theme/app_theme_data.dart';
import 'package:flutter_application/core/data/repository.dart';

/// A purchasable bundle of appearance settings.
class Template {
  Template({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.price,
    required this.preview,
    required this.themeData,
    this.published = false,
  });

  factory Template.fromJson(Map<String, dynamic> json) => Template(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    creatorId: json['creatorId'] as String? ?? systemCreator,
    price: json['price'] as int? ?? 0,
    preview: json['preview'] as String? ?? '🎨',
    themeData: AppThemeData.fromJson(
      (json['themeData'] as Map).cast<String, dynamic>(),
    ),
    published: json['published'] as bool? ?? false,
  );

  /// Creator id of the templates that ship with the store.
  static const systemCreator = 'supercalendar';

  final String id;
  String name;
  String description;
  final String creatorId;

  /// Price in VND; 0 means free.
  int price;

  /// Emoji shown as the template's thumbnail.
  String preview;
  AppThemeData themeData;
  bool published;

  String get priceLabel => price == 0 ? 'Free' : '${_thousands(price)}đ';

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
    'published': published,
  };
}

/// Outcome of a (mock) payment.
enum PaymentResult { success, failed, cancelled }

class Purchase {
  Purchase({
    required this.id,
    required this.userId,
    required this.templateId,
    required this.price,
    required this.status,
    required this.purchasedAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
    id: json['id'] as String,
    userId: json['userId'] as String? ?? '',
    templateId: json['templateId'] as String? ?? '',
    price: json['price'] as int? ?? 0,
    status: PaymentResult.values.firstWhere(
      (r) => r.name == json['status'],
      orElse: () => PaymentResult.failed,
    ),
    purchasedAt: parseDate(json['purchasedAt']) ?? DateTime.now(),
  );

  /// `templateId` used for the VIP subscription itself.
  static const vipProduct = 'vip_subscription';

  final String id;
  final String userId;
  final String templateId;
  final int price;
  final PaymentResult status;
  final DateTime purchasedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'templateId': templateId,
    'price': price,
    'status': status.name,
    'purchasedAt': purchasedAt.toIso8601String(),
  };
}
