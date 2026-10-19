import 'package:flutter_application/core/data/repository.dart';

/// The outcome of a (mock) payment attempt (§20).
enum PaymentResult { success, failed, cancelled }

/// The type of product covered by a [Purchase] (§5.19).
enum ProductType { vip, template }

/// A record of a completed or cancelled mock purchase (§5.19).
///
/// Stored in [Collections.purchases].  Both VIP subscriptions and template
/// purchases share this table, distinguished by [productType].
class Purchase {
  Purchase({
    required this.id,
    required this.userId,
    required this.productType,
    required this.productId,
    required this.price,
    required this.status,
    required this.purchaseDate,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
    id: json['id'] as String,
    userId: json['userId'] as String? ?? '',
    productType: ProductType.values.firstWhere(
      (t) => t.name == json['productType'],
      orElse: () => ProductType.template,
    ),
    productId: json['productId'] as String? ??
        // Backwards-compatible: old records used 'templateId'
        (json['templateId'] as String? ?? ''),
    price: json['price'] as int? ?? 0,
    status: PaymentResult.values.firstWhere(
      (r) => r.name == json['status'],
      orElse: () => PaymentResult.failed,
    ),
    purchaseDate: parseDate(json['purchaseDate']) ??
        parseDate(json['purchasedAt']) ??
        DateTime.now(),
  );

  /// [productId] used for the VIP subscription itself (not a template id).
  static const vipProductId = 'vip_subscription';

  final String id;
  final String userId;
  final ProductType productType;

  /// Either [vipProductId] or a template id.
  final String productId;

  /// Simulated price in VND; 0 means free.
  final int price;

  final PaymentResult status;
  final DateTime purchaseDate;

  bool get isSuccessful => status == PaymentResult.success;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'productType': productType.name,
    'productId': productId,
    // Keep legacy key so old data round-trips without migration
    'templateId': productId,
    'price': price,
    'status': status.name,
    'purchaseDate': purchaseDate.toIso8601String(),
    // Legacy alias
    'purchasedAt': purchaseDate.toIso8601String(),
  };
}
