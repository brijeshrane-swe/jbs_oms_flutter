import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/domain/entities/user_entity.dart';
import '../constants/route_constants.dart';

/// Handles authentication and role-based route protection
class RouteGuard {
  static String? handleRedirect({
    required BuildContext context,
    required GoRouterState state,
    required dynamic authState,
  }) {
    final currentLocation = state.uri.toString();
    final isAuthenticated = authState.user != null;
    final user = authState.user as UserEntity?;

    // Public routes that don't require authentication
    final publicRoutes = [
      AppRoutes.login,
      AppRoutes.clientVerification,
    ];

    // If not authenticated and trying to access protected route
    if (!isAuthenticated && !publicRoutes.contains(currentLocation)) {
      return AppRoutes.login;
    }

    // If authenticated and on login page, redirect to appropriate dashboard
    if (isAuthenticated && currentLocation == AppRoutes.login) {
      return _getInitialRouteForUser(user);
    }

    // Role-based access control
    if (isAuthenticated && user != null) {
      return _checkUserAccess(currentLocation, user);
    }

    return null; // No redirect needed
  }

  /// Get initial route based on user role and verification status
  static String _getInitialRouteForUser(UserEntity? user) {
    if (user == null) return AppRoutes.login;

    switch (user.role) {
      case UserRole.admin:
        return AppRoutes.adminDashboard;
      case UserRole.client:
        if (user.isVerified) {
          return AppRoutes.products;
        } else {
          return AppRoutes.clientVerification;
        }
      case UserRole.user:
        return AppRoutes.clientVerification;
    }
  }

  /// Check if user has access to specific route based on role and verification
  static String? _checkUserAccess(String currentLocation, UserEntity user) {
    // Admin routes
    final adminRoutes = ['/admin'];

    // Client routes (require verified client)
    final clientRoutes = ['/client'];

    // Verification routes
    final verificationRoutes = [AppRoutes.clientVerification];

    // Admin access
    if (adminRoutes.any((route) => currentLocation.startsWith(route))) {
      if (user.role != UserRole.admin) {
        return _getInitialRouteForUser(user);
      }
    }

    // Client access (verified clients only)
    if (clientRoutes.any((route) => currentLocation.startsWith(route))) {
      if (user.role == UserRole.admin) {
        return AppRoutes.adminDashboard;
      } else if (user.role != UserRole.client || !user.isVerified) {
        return AppRoutes.clientVerification;
      }
    }

    // Verification route access
    if (verificationRoutes.any((route) => currentLocation.startsWith(route))) {
      if (user.role == UserRole.admin) {
        return AppRoutes.adminDashboard;
      } else if (user.role == UserRole.client && user.isVerified) {
        return AppRoutes.products;
      }
      // Unverified users (role: user or unverified client) stay on verification
    }

    return null; // Access allowed
  }
}
