import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/document_store.dart';
import 'services/settings_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SettingsStore.instance.load();
  await DocumentStore.instance.load();
  runApp(const DocScannerApp());
}

class DocScannerApp extends StatelessWidget {
  const DocScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) => MaterialApp(
        title: 'Document Scanner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: SettingsStore.instance.themeMode,
        home: const SplashScreen(),
      ),
    );
  }
}
