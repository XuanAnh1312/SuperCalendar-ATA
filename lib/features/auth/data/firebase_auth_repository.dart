import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter_application/features/auth/domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({firebase.FirebaseAuth? auth})
    : _auth = auth ?? firebase.FirebaseAuth.instance;

  final firebase.FirebaseAuth _auth;
  Future<void>? _googleInitialization;

  static AuthAccount? _account(firebase.User? user) => user == null
      ? null
      : AuthAccount(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
        );

  @override
  AuthAccount? get currentAccount => _account(_auth.currentUser);

  @override
  Stream<AuthAccount?> accountChanges() =>
      _auth.authStateChanges().map(_account);

  @override
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = firebase.GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        await _auth.signInWithPopup(provider);
      } else {
        await (_googleInitialization ??= GoogleSignIn.instance.initialize());
        final account = await GoogleSignIn.instance.authenticate();
        final token = account.authentication.idToken;
        if (token == null) {
          throw const AuthFailure('Google did not return a sign-in token.');
        }
        await _auth.signInWithCredential(
          firebase.GoogleAuthProvider.credential(idToken: token),
        );
      }
    } on firebase.FirebaseAuthException catch (error) {
      throw AuthFailure(switch (error.code) {
        'popup-closed-by-user' ||
        'cancelled-popup-request' => 'Sign-in was cancelled.',
        'popup-blocked' => 'Allow pop-ups in your browser, then try again.',
        'unauthorized-domain' =>
          'This app address is not authorized for Google sign-in.',
        'operation-not-allowed' =>
          'Google sign-in has not been enabled for this app.',
        'network-request-failed' =>
          'Check your internet connection and try again.',
        'account-exists-with-different-credential' =>
          'This email already uses another sign-in method.',
        _ => 'Could not sign in. Please try again.',
      });
    } on GoogleSignInException catch (error) {
      throw AuthFailure(
        error.code == GoogleSignInExceptionCode.canceled
            ? 'Sign-in was cancelled.'
            : 'Could not sign in with Google. Check the sign-in configuration for this device.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on firebase.FirebaseAuthException {
      throw const AuthFailure('Could not sign out. Please try again.');
    }
    // Firebase owns the application session. Google account consent remains
    // intact; the next sign-in still lets the user choose an account.
  }
}
