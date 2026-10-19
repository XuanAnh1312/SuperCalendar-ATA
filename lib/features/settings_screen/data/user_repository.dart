import 'package:flutter/foundation.dart';

import 'package:flutter_application/core/data/document_store.dart';
import 'package:flutter_application/features/settings_screen/domain/user.dart';

/// The single local user and the device settings.
class UserRepository extends ChangeNotifier {
  UserRepository(this.store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    user = _defaultUser();
  }

  static const localUserId = 'local_user';

  final DocumentStore store;
  final DateTime Function() _clock;

  late User user;
  AppSettings settings = AppSettings();

  Future<void> _pending = Future.value();

  User _defaultUser() =>
      User(id: localUserId, name: 'Mia Chen', createdAt: _clock());

  Future<void> load() async {
    await flush();
    final users = await store.readAll(Collections.users);
    user = users.isEmpty ? _defaultUser() : User.fromJson(users.first);
    final docs = await store.readAll(Collections.settings);
    settings = docs.isEmpty ? AppSettings() : AppSettings.fromJson(docs.first);
    notifyListeners();
  }

  Future<void> flush() => _pending;

  void setVip(bool value) {
    user.isVip = value;
    _saveUser();
  }

  void selectTheme(String themeId) {
    user.selectedThemeId = themeId;
    _saveUser();
  }

  void rename(String name) {
    if (name.trim().isEmpty) return;
    user.name = name.trim();
    _saveUser();
  }

  /// Updates the optional profile fields. An empty string clears the field;
  /// null leaves it unchanged.
  void updateProfile({String? email, String? avatar}) {
    if (email != null) user.email = email.trim().isEmpty ? null : email.trim();
    if (avatar != null) user.avatar = avatar.isEmpty ? null : avatar;
    _saveUser();
  }

  /// Applies [change] to the settings and persists every field of
  /// [AppSettings] (theme mode, week start, time format, ...).
  void updateSettings(void Function(AppSettings settings) change) {
    change(settings);
    final data = settings.toJson();
    _pending = _pending.then(
      (_) => store.put(Collections.settings, AppSettings.id, data),
    );
    notifyListeners();
  }

  void _saveUser() {
    user.updatedAt = _clock();
    final data = user.toJson();
    _pending = _pending.then(
      (_) => store.put(Collections.users, user.id, data),
    );
    notifyListeners();
  }
}
