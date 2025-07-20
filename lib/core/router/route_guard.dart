import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_constants.dart';

/// Handles authentication and role-based route protection
class RouteGuard {
  static String? handleRedirect({
    required BuildContext context,
    required GoRouterState state,
    required dynamic authState,
  }) {
    // Use state.uri.toString() instead of deprecated state.location
    final currentLocation = state.uri.toString();

    // Check if user is authenticated
    final isAuthenticated = authState.user != null;
    final userRole = authState.user?.role;

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
      return _getInitialRouteForRole(userRole);
    }

    // Role-based access control
    if (isAuthenticated) {
      return _checkRoleBasedAccess(currentLocation, userRole);
    }

    return null; // No redirect needed
  }

  /// Get initial route based on user role
  static String _getInitialRouteForRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return AppRoutes.adminDashboard;
      case 'client':
        return AppRoutes.products; // Start clients at products page
      default:
        return AppRoutes.login;
    }
  }

  /// Check if user has access to specific route based on role
  static String? _checkRoleBasedAccess(String currentLocation, String? role) {
    // Admin routes - only admins can access
    final adminRoutes = [
      AppRoutes.adminDashboard, // Catch all admin routes
    ];

    // Client routes - only clients can access
    final clientRoutes = [
      AppRoutes.products,
      AppRoutes.orders,
      AppRoutes.notifications,
      AppRoutes.profile,
      AppRoutes.clientDashboard, // Catch all client routes
    ];

    // Check admin access
    if (adminRoutes.any((route) => currentLocation.startsWith(route))) {
      if (role?.toLowerCase() != 'admin') {
        return AppRoutes.products; // Redirect non-admin to client area
      }
    }

    // Check client access
    if (clientRoutes.any((route) => currentLocation.startsWith(route))) {
      if (role?.toLowerCase() != 'client') {
        return AppRoutes.adminDashboard; // Redirect non-client to admin area
      }
    }

    return null; // Access allowed
  }
}
