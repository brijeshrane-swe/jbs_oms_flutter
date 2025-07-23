import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final googleSignIn = ref.watch(googleSignInProvider);
  return AuthRepositoryImpl(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    googleSignIn: googleSignIn,
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

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial) {
    _initAuthState();
  }

  void _initAuthState() {
    _authRepository.authStateChanges().listen(
      (user) {
        if (user == null) {
          state = AuthState.unauthenticated.copyWith(
            isGoogleSignInInitialized: state.isGoogleSignInInitialized,
          );
        } else {
          state = state.authenticated(user);
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Auth stream error: $error');
        }

        if (!error.toString().contains('User document not found')) {
          state = state.failure(error.toString());
        }
      },
    );
  }

  Future<void> signInWithGoogle() async {
    state = state.loading();
    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null) {
        state = state.authenticated(user).initialized(); // Mark as initialized
      } else {
        state = state.copyWith(
          isLoading: false,
          isGoogleSignInInitialized:
              true, // Mark as initialized even if cancelled
        );
      }
    } catch (e) {
      state = state.failure(_handleAuthError(e));
    }
  }

  // Add method to check initialization status
  bool get isGoogleSignInInitialized => state.isGoogleSignInInitialized;

  Future<void> signInWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      state = state.failure('Email and password cannot be empty');
      return;
    }

    state = state.loading();
    try {
      final user = await _authRepository.signInWithEmail(email, password);
      if (user != null) {
        state = state.authenticated(user);
      } else {
        state = state.failure('Sign-in failed. Please try again');
      }
    } catch (e) {
      state = state.failure(_handleAuthError(e));
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      state = state.failure('Email and password cannot be empty');
      return;
    }

    if (password.length < 6) {
      state = state.failure('Password must be at least 6 characters long');
      return;
    }

    state = state.loading();
    try {
      final user = await _authRepository.signUpWithEmail(email, password);
      if (user != null) {
        state = state.authenticated(user);
      } else {
        state = state.failure('Sign-up failed. Please try again');
      }
    } catch (e) {
      state = state.failure(_handleAuthError(e));
    }
  }

  Future<void> signOut() async {
    state = state.loading();
    try {
      await _authRepository.signOut();
      state = AuthState.unauthenticated;
    } catch (e) {
      if (kDebugMode) {
        print('Sign out error: $e');
      }
      // Even if sign out fails, treat user as signed out locally
      state = AuthState.unauthenticated;
    }
  }

  Future<bool> verifyClientCode(String code) async {
    if (code.isEmpty) {
      state = state.failure('Please enter a valid code');
      return false;
    }

    state = state.loading();
    try {
      final isValid = await _authRepository.verifyClientCode(code);
      if (isValid) {
        // Refresh the current user state after successful verification
        final updatedUser = await _authRepository.getCurrentUser();
        if (updatedUser != null) {
          state = state.authenticated(updatedUser);
        }
        return true;
      } else {
        state = state.failure('Invalid or expired verification code');
        return false;
      }
    } catch (e) {
      state = state.failure('Failed to verify code: ${_handleAuthError(e)}');
      return false;
    }
  }

  Future<void> requestClientAccess(String email, String displayName) async {
    if (email.isEmpty || displayName.isEmpty) {
      state = state.failure('Email and display name are required');
      return;
    }

    state = state.loading();
    try {
      await _authRepository.requestClientAccess(email, displayName);
      // Don't change auth state, just show success
      // The UI should handle showing success message
    } catch (e) {
      state = state.failure('Failed to request access: ${_handleAuthError(e)}');
    }
  }

  /// Clear any current error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser != null) {
        state = state.authenticated(currentUser);
      } else {
        state = AuthState.unauthenticated;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to refresh user: $e');
      }
    }
  }

  // Stream for router refresh
  Stream<UserEntity?> authStateChanges() {
    return _authRepository.authStateChanges();
  }

  // Helper method to handle Firebase Auth errors
  String _handleAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('user-not-found')) {
      return 'No account found with this email address';
    } else if (errorString.contains('wrong-password')) {
      return 'Incorrect password';
    } else if (errorString.contains('email-already-in-use')) {
      return 'An account already exists with this email address';
    } else if (errorString.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters';
    } else if (errorString.contains('invalid-email')) {
      return 'Please enter a valid email address';
    } else if (errorString.contains('user-disabled')) {
      return 'This account has been disabled';
    } else if (errorString.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled';
    } else if (errorString.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later';
    } else if (errorString.contains('network-request-failed') ||
        errorString.contains('network error')) {
      return 'Network error. Please check your connection';
    } else if (errorString.contains('pigeonuserdetails') ||
        errorString.contains('pigeon')) {
      return 'Authentication error. Please try again';
    } else if (errorString.contains('sign_in_failed')) {
      return 'Google Sign-In failed. Please try again';
    } else if (errorString
        .contains('account-exists-with-different-credential')) {
      return 'An account already exists with a different sign-in method';
    } else {
      // Return a generic message but log the specific error for debugging
      if (kDebugMode) {
        print('Unhandled auth error: $error');
      }
      return 'Authentication failed. Please try again';
    }
  }
}

// Additional utility providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.isAuthenticated;
});

final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user?.role;
});

final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user?.role == UserRole.admin;
});

final isVerifiedClientProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;
  return user?.role == UserRole.client && user?.isVerified == true;
});
