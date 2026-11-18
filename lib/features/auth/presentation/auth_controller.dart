import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_application/features/auth/domain/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.repository) : account = repository.currentAccount {
    _subscription = repository.accountChanges().listen(
      (value) {
        account = value;
        notifyListeners();
      },
      onError: (Object error) {
        message = 'Could not restore your sign-in session. Please try again.';
        notifyListeners();
      },
    );
  }

  final AuthRepository repository;
  late final StreamSubscription<AuthAccount?> _subscription;
  AuthAccount? account;
  bool busy = false;
  String? message;
  bool _disposed = false;

  Future<void> signInWithGoogle() => _run(repository.signInWithGoogle);
  Future<void> signOut() => _run(repository.signOut);

  Future<void> _run(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    message = null;
    notifyListeners();
    try {
      await action();
      if (!_disposed) account = repository.currentAccount;
    } on AuthFailure catch (error) {
      if (!_disposed) message = error.message;
    } catch (_) {
      if (!_disposed) message = 'Something went wrong. Please try again.';
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
