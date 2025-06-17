import 'package:flutter/material.dart';
import 'package:order_management_system/presentation/providers/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'JBS OMS',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: tp.themeMode,
      home: Scaffold(
        appBar: AppBar(
          title: Text('JBS OMS'),
        ),
        body: SwitchListTile(
          title: const Text('Dark mode'),
          value: context.watch<ThemeProvider>().isDarkMode,
          onChanged: (v) => context.read<ThemeProvider>().toggleTheme(v),
        ),
      ),
    );
  }
}
