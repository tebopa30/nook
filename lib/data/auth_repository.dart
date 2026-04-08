import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final isInitialized = ref.watch(firebaseInitializedProvider);
  if (isInitialized) {
    return FirebaseAuthRepository(FirebaseAuth.instance);
  } else {
    return MockAuthRepository();
  }
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<UserCredential> signInAnonymously();
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  FirebaseAuthRepository(this._auth);

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

class MockAuthRepository implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signInAnonymously() async {
    throw UnimplementedError('Mock login not implemented');
  }

  @override
  Future<void> signOut() async {
    // No-op
  }
}
