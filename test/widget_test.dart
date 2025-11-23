/// Basic Widget Tests
///
/// Tests basic UI components that don't require Firebase or complex providers.
/// Focuses on widget rendering and basic functionality.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_planner/providers/theme_provider.dart';

/// Test version of MyApp that provides necessary providers for testing
class TestMyApp extends StatelessWidget {
  const TestMyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Adaptive Planner',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          home: const Scaffold(
            body: Center(
              child: Text('Test App Loaded'),
            ),
          ),
        );
      },
    );
  }
}

void main() {
  group('Basic Widget Tests', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider();
    });

    group('Main App Widget', () {
      testWidgets('TestMyApp renders without crashing',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => themeProvider,
            child: const TestMyApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Verify the app renders
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.text('Test App Loaded'), findsOneWidget);
      });

      testWidgets('should have correct title', (WidgetTester tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => themeProvider,
            child: const TestMyApp(),
          ),
        );

        final materialApp =
            tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(materialApp.title, equals('Adaptive Planner'));
      });
    });

    group('Theme Provider', () {
      testWidgets('should toggle theme correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => themeProvider,
            child: MaterialApp(
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: themeProvider.themeMode,
              home: Scaffold(
                appBar: AppBar(
                  title: const Text('Test'),
                  actions: [
                    IconButton(
                      icon: Icon(
                        themeProvider.themeMode == ThemeMode.light
                            ? Icons.dark_mode
                            : Icons.light_mode,
                      ),
                      onPressed: () => themeProvider.toggleTheme(true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Initial theme should be light
        expect(themeProvider.themeMode, equals(ThemeMode.light));

        // Tap theme toggle button
        await tester.tap(find.byType(IconButton));
        await tester.pump();

        // Theme should change to dark
        expect(themeProvider.themeMode, equals(ThemeMode.dark));
      });
    });

    group('Basic UI Components', () {
      testWidgets('should render basic Material widgets',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Test App')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Welcome to Adaptive Planner'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: null,
                      child: Text('Test Button'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // Verify basic UI elements render
        expect(find.text('Test App'), findsOneWidget);
        expect(find.text('Welcome to Adaptive Planner'), findsOneWidget);
        expect(find.text('Test Button'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('should handle text input', (WidgetTester tester) async {
        String inputText = '';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  child: TextField(
                    onChanged: (value) => inputText = value,
                    decoration: const InputDecoration(
                      hintText: 'Enter text',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Find the text field
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        // Enter text
        await tester.enterText(textField, 'Hello World');
        expect(inputText, equals('Hello World'));
      });

      testWidgets('should render form elements', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                        ),
                        initialValue: 'medium',
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                          DropdownMenuItem(
                              value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'high', child: Text('High')),
                        ],
                        onChanged: (value) {},
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Remember me'),
                        value: false,
                        onChanged: (value) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // Verify form elements render
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Enter your email'), findsOneWidget);
        expect(find.text('Priority'), findsOneWidget);
        expect(find.text('Medium'),
            findsOneWidget); // Selected value should be visible
        expect(find.text('Remember me'), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
        expect(find.byType(CheckboxListTile), findsOneWidget);
      });
    });
  });
}
