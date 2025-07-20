import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import 'app_router.dart';

/// Provider for GoRouter instance with authentication state management
final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state directly
  final authState = ref.watch(authStateProvider);
  final authNotifier = ref.read(authStateProvider.notifier);

  return AppRouter.createRouter(
    authNotifier: authNotifier,
    authState: authState,
  );
});

/// Stream provider for router refresh on auth state changes
final routerRefreshProvider = StreamProvider<bool>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges().map((user) => user != null);
});
