/// Route paths and names for the application
class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String clientVerification = '/client-verification';

  // Dashboard routes
  static const String adminDashboard = '/admin';
  static const String clientDashboard = '/client';

  // Admin specific routes
  static const String clientList = '/admin/clients';
  static const String ordersManagement = '/admin/orders';
  static const String addProduct = '/admin/products/add';
  static const String sendNotifications = '/admin/notifications/send';

  // Client specific routes
  static const String products = '/client/products';
  static const String productDetails = '/client/products/:productId';
  static const String orders = '/client/orders';
  static const String notifications = '/client/notifications';
  static const String profile = '/client/profile';

  // Shared routes
  static const String settings = '/settings';
}

/// Route names for named navigation
class RouteNames {
  // Auth
  static const String login = 'login';
  static const String clientVerification = 'client-verification';

  // Dashboard
  static const String adminDashboard = 'admin-dashboard';
  static const String clientDashboard = 'client-dashboard';

  // Admin
  static const String clientList = 'client-list';
  static const String ordersManagement = 'orders-management';
  static const String addProduct = 'add-product';
  static const String sendNotifications = 'send-notifications';

  // Client
  static const String products = 'products';
  static const String productDetails = 'product-details';
  static const String orders = 'orders';
  static const String notifications = 'notifications';
  static const String profile = 'profile';

  // Shared
  static const String settings = 'settings';
}
