import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/features/auth/domain/auth_repository.dart';
import 'package:flutter_application/features/auth/presentation/auth_controller.dart';
import 'package:flutter_application/features/auth/presentation/google_account_card.dart';

class FakeAuthRepository implements AuthRepository {
  final changes = StreamController<AuthAccount?>.broadcast(sync: true);
  @override
  AuthAccount? currentAccount;
  Completer<void>? pending;
  Object? failure;
  int signInCalls = 0;

  @override
  Stream<AuthAccount?> accountChanges() => changes.stream;

  @override
  Future<void> signInWithGoogle() async {
    signInCalls++;
    if (pending != null) await pending!.future;
    if (failure case final error?) throw error;
    currentAccount = const AuthAccount(
      uid: 'google-user',
      email: 'user@example.com',
    );
    changes.add(currentAccount);
  }

  @override
  Future<void> signOut() async {
    if (failure case final error?) throw error;
    currentAccount = null;
    changes.add(null);
  }
}

void main() {
  late FakeAuthRepository repository;
  late AuthController controller;

  setUp(() {
    repository = FakeAuthRepository();
    controller = AuthController(repository);
  });
  tearDown(() async {
    controller.dispose();
    await repository.changes.close();
  });

  test('restores SDK session and follows external sign-out', () {
    repository.currentAccount = const AuthAccount(uid: 'restored');
    final restored = AuthController(repository);
    expect(restored.account?.uid, 'restored');
    repository.changes.add(null);
    expect(restored.account, isNull);
    restored.dispose();
  });

  test('duplicate taps start only one sign-in operation', () async {
    repository.pending = Completer<void>();
    final first = controller.signInWithGoogle();
    await controller.signInWithGoogle();
    expect(controller.busy, isTrue);
    expect(repository.signInCalls, 1);
    repository.pending!.complete();
    await first;
    expect(controller.account?.uid, 'google-user');
    expect(controller.busy, isFalse);
    await controller.signOut();
    expect(controller.account, isNull);
  });

  test('cancelled sign-in is recoverable', () async {
    repository.failure = const AuthFailure('Sign-in was cancelled.');
    await controller.signInWithGoogle();
    expect(controller.message, 'Sign-in was cancelled.');
    expect(controller.account, isNull);
    expect(controller.busy, isFalse);
    repository.failure = null;
    await controller.signInWithGoogle();
    expect(controller.message, isNull);
    expect(controller.account, isNotNull);
  });

  test('failed sign-out retains current identity', () async {
    await controller.signInWithGoogle();
    repository.failure = const AuthFailure(
      'Could not sign out. Please try again.',
    );
    await controller.signOut();
    expect(controller.account?.uid, 'google-user');
    expect(controller.message, isNotNull);
  });

  testWidgets('Google account card signs in and signs out', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GoogleAccountCard(controller: controller)),
      ),
    );
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('user@example.com'), findsOneWidget);
    expect(
      find.text(
        'Your planner data stays on this device. Cloud sync is not available yet.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('user@example.com'), findsNothing);
  });
}
