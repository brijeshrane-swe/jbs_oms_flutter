import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final router = ref.watch(routerProvider);
    // final themeMode = ref.watch(themeModeProvider);
    // final fontScale = ref.watch(fontScaleProvider);

    return MaterialApp.router(
      title: 'Mom\'s Product Order Management',
      debugShowCheckedModeBanner: false,

      // Theme configuration
      // theme: AppTheme.lightTheme.copyWith(
      //   textTheme: AppTheme.lightTheme.textTheme.apply(
      //     fontSizeFactor: fontScale,
      //   ),
      // ),
      // darkTheme: AppTheme.darkTheme.copyWith(
      //   textTheme: AppTheme.darkTheme.textTheme.apply(
      //     fontSizeFactor: fontScale,
      //   ),
      // ),
      // themeMode: themeMode,
      //
      // // Router configuration
      // routerConfig: router,

      // Responsive design
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
              // textScaler: TextScaler.linear(fontScale),
              ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
