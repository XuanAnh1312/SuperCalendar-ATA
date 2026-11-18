class AuthAccount {
  const AuthAccount({required this.uid, this.email, this.displayName});

  final String uid;
  final String? email;
  final String? displayName;
}

/// Authentication only. Planner data and VIP rights are not changed here.
abstract interface class AuthRepository {
  AuthAccount? get currentAccount;
  Stream<AuthAccount?> accountChanges();
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}
