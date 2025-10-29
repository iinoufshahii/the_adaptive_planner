// lib/main.dart
import 'package:adaptive_planner/providers/theme_provider.dart';
import 'package:adaptive_planner/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/focus_timer_manager.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart'; 
import 'services/focus_service.dart';
import 'screens/pomodoro_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/mood_service.dart';

void main() async {
  // Ensure Flutter widgets are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set preferred orientations and system UI overlay style for a cleaner look
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // The app now starts wrapped in a provider for theme management
  final focusTimerManager = FocusTimerManager();
  await focusTimerManager.loadPrefs();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: focusTimerManager),
        // Provide a global MoodService so any legacy or hot-reload path using context can still resolve it.
        Provider<MoodService>(create: (_) => MoodService()),
      ],
      child: const MyApp(),
    ),
  );
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
            home: const _RootEntry(),
        );
      },
    );
  }
}

/// Root entry now starts at WelcomeScreen. After authentication, code in
/// login/signup screens should navigate to DashboardScreen explicitly.
class _RootEntry extends StatefulWidget {
  const _RootEntry();

  @override
  State<_RootEntry> createState() => _RootEntryState();
}

class _RootEntryState extends State<_RootEntry> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        WelcomeScreen(),
        FocusFloatingTimerOverlay(),
      ],
    );
  }
}

class FocusFloatingTimerOverlay extends StatefulWidget {
  const FocusFloatingTimerOverlay({super.key});

  @override
  State<FocusFloatingTimerOverlay> createState() => _FocusFloatingTimerOverlayState();
}

class _FocusFloatingTimerOverlayState extends State<FocusFloatingTimerOverlay> {
  Offset position = const Offset(20, 100);
  bool dragging = false;
  late final FocusTimerManager _manager = FocusTimerManager();

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _manager.addListener(_listener);
  }

  @override
  void dispose() {
    _manager.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _manager.phase;
    final running = phase != PomodoroPhase.idle && _manager.remainingSeconds > 0;
    if (!running) return const SizedBox.shrink();
    final theme = Theme.of(context);
    String format(int ts) {
      final m = (ts / 60).floor().toString().padLeft(2, '0');
      final s = (ts % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Listener(
        onPointerDown: (_) => setState(() => dragging = true),
        onPointerUp: (_) => setState(() => dragging = false),
        child: Draggable(
          feedback: _bubble(theme, format(_manager.remainingSeconds)),
          childWhenDragging: Opacity(opacity: 0.3, child: _bubble(theme, format(_manager.remainingSeconds))),
          onDragEnd: (d) {
            // Validate offset to prevent NaN values and keep within screen bounds
            final newOffset = d.offset;
            if (newOffset.dx.isFinite && newOffset.dy.isFinite) {
              final size = MediaQuery.of(context).size;
              final constrainedOffset = Offset(
                newOffset.dx.clamp(0.0, size.width - 84),
                newOffset.dy.clamp(0.0, size.height - 84),
              );
              setState(() => position = constrainedOffset);
            }
          },
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => PomodoroScreen(focusService: FocusService())));
            },
            child: _bubble(theme, format(_manager.remainingSeconds)),
          ),
        ),
      ),
    );
  }

  Widget _bubble(ThemeData theme, String time) {
    return Material(
      elevation: 6,
      shape: const CircleBorder(),
      color: Colors.transparent,
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
          boxShadow: [
            BoxShadow(color: theme.colorScheme.primary.withOpacity(.4), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          time,
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}