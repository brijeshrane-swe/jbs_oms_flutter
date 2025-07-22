import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_management_system/core/router/route_provider.dart';
import 'package:order_management_system/core/theme/app_theme.dart';
import 'package:order_management_system/core/theme/font_scale_provider.dart';
import 'package:order_management_system/core/theme/theme_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);

    return MaterialApp.router(
      title: 'Mom\'s Product Order Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final scaler = TextScaler.linear(fontScale);

        return MediaQuery(
          // Override the MediaQuery data to apply the custom text scaler.
          data: MediaQuery.of(context).copyWith(
            textScaler: scaler,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
