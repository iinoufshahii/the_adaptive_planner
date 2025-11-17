// lib/main.dart
import 'package:adaptive_planner/Theme/App_Theme.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'Screens/welcome_screen.dart';
import 'Service/focus_timer_manager.dart';
import 'Service/mood_service.dart';
import 'Service/notification_service.dart';

void main() {
  runApp(const FirebaseInitializer());
}

class FirebaseInitializer extends StatelessWidget {
  const FirebaseInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Error initializing app: ${snapshot.error}'),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return snapshot.data!;
        }

        return const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  Future<Widget> _initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    final focusTimerManager = FocusTimerManager();
    await focusTimerManager.loadPrefs();

    // Initialize notification service
    final notificationService = NotificationService();
    await notificationService.initialize();

    return DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider.value(value: focusTimerManager),
          ChangeNotifierProvider.value(value: notificationService),
          Provider<MoodService>(create: (_) => MoodService()),
        ],
        child: const MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // A Consumer widget listens to the ThemeProvider for changes.
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final mode = themeProvider.themeMode;
        final Brightness statusBarIconBrightness =
            mode == ThemeMode.dark ? Brightness.light : Brightness.dark;

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: statusBarIconBrightness,
        ));

        return MaterialApp(
          title: 'Adaptive Student Planner & Journal',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          // DevicePreview configuration
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          home: const _RootEntry(),
        );
      },
    );
  }
}

/// Root entry shows WelcomeScreen after authentication check.
/// After authentication, login/signup screens navigate to DashboardScreen explicitly.
class _RootEntry extends StatefulWidget {
  const _RootEntry();

  @override
  State<_RootEntry> createState() => _RootEntryState();
}

class _RootEntryState extends State<_RootEntry> {
  @override
  Widget build(BuildContext context) {
    // Stack ensures welcome screen displays on app start
    return Stack(
      children: [
        const WelcomeScreen(),
      ],
    );
  }
}
