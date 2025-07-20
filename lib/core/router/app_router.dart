import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:order_management_system/core/constants/route_constants.dart';
import 'package:order_management_system/core/router/route_guard.dart';
import 'package:order_management_system/features/auth/presentation/pages/client_verification_page.dart';
import 'package:order_management_system/features/auth/presentation/pages/login_page.dart';
import 'package:order_management_system/features/dashboard/presentation/admin_dashboard_page.dart';
import 'package:order_management_system/features/dashboard/presentation/client_list_page.dart';
import 'package:order_management_system/features/dashboard/presentation/client_shell_page.dart';
import 'package:order_management_system/features/notifications/presentation/pages/notifications_page.dart';
import 'package:order_management_system/features/notifications/presentation/pages/send_notifications_page.dart';
import 'package:order_management_system/features/orders/presentation/pages/orders_management_page.dart';
import 'package:order_management_system/features/orders/presentation/pages/orders_page.dart';
import 'package:order_management_system/features/products/presentation/pages/add_product_page.dart';
import 'package:order_management_system/features/products/presentation/pages/product_details_page.dart';
import 'package:order_management_system/features/products/presentation/pages/products_page.dart';
import 'package:order_management_system/features/profile/presentation/pages/profile_page.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter createRouter({
    required dynamic authNotifier,
    required dynamic authState,
  }) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppRoutes.login,
      debugLogDiagnostics: true,

      // Authentication redirect logic
      redirect: (BuildContext context, GoRouterState state) {
        return RouteGuard.handleRedirect(
          context: context,
          state: state,
          authState: authState,
        );
      },

      // Refresh router when auth state changes
      refreshListenable: GoRouterRefreshStream(
        authNotifier.authStateChanges(),
      ),

      routes: [
        // Authentication Routes
        GoRoute(
          path: AppRoutes.login,
          name: RouteNames.login,
          builder: (context, state) => const LoginPage(),
        ),

        GoRoute(
          path: AppRoutes.clientVerification,
          name: RouteNames.clientVerification,
          builder: (context, state) => const ClientVerificationPage(),
        ),

        // Admin Routes (Simple routes without shell)
        GoRoute(
          path: AppRoutes.adminDashboard,
          name: RouteNames.adminDashboard,
          builder: (context, state) => const AdminDashboardPage(),
          routes: [
            GoRoute(
              path: 'clients',
              name: RouteNames.clientList,
              builder: (context, state) => const ClientListPage(),
            ),
            GoRoute(
              path: 'orders',
              name: RouteNames.ordersManagement,
              builder: (context, state) => const OrdersManagementPage(),
            ),
            GoRoute(
              path: 'products/add',
              name: RouteNames.addProduct,
              builder: (context, state) => const AddProductPage(),
            ),
            GoRoute(
              path: 'notifications/send',
              name: RouteNames.sendNotifications,
              builder: (context, state) => const SendNotificationsPage(),
            ),
          ],
        ),

        // Client Shell Route with Bottom Navigation
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ClientShellPage(navigationShell: navigationShell);
          },
          branches: [
            // Products Branch
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.products,
                  name: RouteNames.products,
                  builder: (context, state) => const ProductsPage(),
                  routes: [
                    GoRoute(
                      path: ':productId',
                      name: RouteNames.productDetails,
                      builder: (context, state) {
                        final productId = state.pathParameters['productId']!;
                        return ProductDetailsPage(productId: productId);
                      },
                    ),
                  ],
                ),
              ],
            ),

            // Orders Branch
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.orders,
                  name: RouteNames.orders,
                  builder: (context, state) => const OrdersPage(),
                ),
              ],
            ),

            // Notifications Branch
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.notifications,
                  name: RouteNames.notifications,
                  builder: (context, state) => const NotificationsPage(),
                ),
              ],
            ),

            // Profile Branch
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  name: RouteNames.profile,
                  builder: (context, state) => const ProfilePage(),
                ),
              ],
            ),
          ],
        ),
      ],

      // Error handling
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page Not Found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                  'The page "${state.uri}" could not be found.'), // Updated here too
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom refresh stream for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
