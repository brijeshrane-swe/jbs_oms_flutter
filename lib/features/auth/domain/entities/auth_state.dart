import 'package:order_management_system/features/auth/domain/entities/user_entity.dart';

class AuthState {
  final UserEntity? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserEntity? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
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
      );

  // Error state
  AuthState failure(String error) => copyWith(
        isLoading: false,
        error: error,
        isAuthenticated: false,
        user: null,
      );

  // Unauthenticated state
  static const AuthState unauthenticated = AuthState(
    user: null,
    isLoading: false,
    error: null,
    isAuthenticated: false,
  );
}
