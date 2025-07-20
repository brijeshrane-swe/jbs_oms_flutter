import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    googleSignIn: GoogleSignIn(),
  );
});

// Auth state provider - this is the one referenced in router
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

// Stream provider for auth state changes
final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

// Current user provider
final currentUserProvider = FutureProvider<UserEntity?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getCurrentUser();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial) {
    _initAuthState();
  }

  void _initAuthState() {
    _authRepository.authStateChanges().listen(
      (user) {
        if (user != null) {
          state = state.authenticated(user);
        } else {
          state = AuthState.unauthenticated;
        }
      },
      onError: (error) {
        state = state.failure(error.toString());
      },
    );
  }

  Future<void> signInWithGoogle() async {
    state = state.loading();
    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        state = state.authenticated(user);
      } else {
        state = state.failure('Sign-in was cancelled');
      }
    } catch (e) {
      state = state.failure(e.toString());
    }
  }

  Future<void> signOut() async {
    state = state.loading();
    try {
      await _authRepository.signOut();
      state = AuthState.unauthenticated;
    } catch (e) {
      state = state.failure(e.toString());
    }
  }

  Future<bool> verifyClientCode(String code) async {
    try {
      return await _authRepository.verifyClientCode(code);
    } catch (e) {
      state = state.failure(e.toString());
      return false;
    }
  }

  Future<void> requestClientAccess(String email, String displayName) async {
    try {
      await _authRepository.requestClientAccess(email, displayName);
    } catch (e) {
      state = state.failure(e.toString());
    }
  }

  // Stream for router refresh
  Stream<UserEntity?> authStateChanges() {
    return _authRepository.authStateChanges();
  }
}
