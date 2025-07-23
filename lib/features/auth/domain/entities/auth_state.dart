import 'package:order_management_system/features/auth/domain/entities/user_entity.dart';

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isGoogleSignInInitialized;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isGoogleSignInInitialized = false,
  });

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isGoogleSignInInitialized,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGoogleSignInInitialized:
          isGoogleSignInInitialized ?? this.isGoogleSignInInitialized,
    );
  }

  // Initial state
  static const AuthState initial = AuthState();

  // Loading state
  AuthState loading() => copyWith(isLoading: true, error: null);

  // Authenticated state
  AuthState authenticated(UserEntity user) => AuthState(
        user: user,
        isLoading: false,
        error: null,
        isAuthenticated: true,
        isGoogleSignInInitialized: isGoogleSignInInitialized,
      );

  // Error state
  AuthState failure(String error) => copyWith(
        isLoading: false,
        error: error,
        isAuthenticated: false,
        user: null,
      );

  // Add method to mark initialization complete
  AuthState initialized() => copyWith(isGoogleSignInInitialized: true);

  // Unauthenticated state
  static const AuthState unauthenticated = AuthState(
    user: null,
    isLoading: false,
    error: null,
    isAuthenticated: false,
  );
}
