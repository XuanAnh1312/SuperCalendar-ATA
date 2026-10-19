import 'package:flutter_application/core/data/repository.dart';

export 'package:flutter_application/features/settings_screen/domain/app_settings.dart';

/// The local user profile (§5.1).
///
/// Only one user exists in the Prototype (id = [UserRepository.localUserId]).
/// VIP status is mock-toggled via [isVip]; in Production this would come from
/// a verified entitlement.
class User {
  User({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    this.isVip = false,
    this.selectedThemeId = 'pastel_minimal',
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    final created = parseDate(json['createdAt']) ?? DateTime.now();
    return User(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
      isVip: json['isVip'] as bool? ?? false,
      selectedThemeId: json['selectedThemeId'] as String? ?? 'pastel_minimal',
      createdAt: created,
      updatedAt: parseDate(json['updatedAt']) ?? created,
    );
  }

  final String id;

  /// Display name shown in greetings and the account screen (max 30 chars).
  String name;

  /// Optional email address (not used in Prototype).
  String? email;

  /// Local file path of the avatar image; null shows initials instead.
  String? avatar;

  /// Mock VIP flag (BR-06).  Set to true after a successful mock purchase.
  bool isVip;

  /// Id of the [AppThemeData] currently applied across the app.
  String selectedThemeId;

  final DateTime createdAt;
  DateTime updatedAt;

  // ---------------------------------------------------------------------------
  // Derived helpers

  /// First word of [name], used in greetings ("Good morning, Mia").
  String get firstName => name.split(' ').first;

  /// One or two uppercase initials from [name].
  String get initials => name
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar': avatar,
    'isVip': isVip,
    'selectedThemeId': selectedThemeId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
