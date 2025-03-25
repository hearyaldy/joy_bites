import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/entry_screen.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    print("Supabase initialized successfully.");
  } catch (e) {
    print("Failed to initialize Supabase: $e");
    runApp(ErrorScreen(errorMessage: "Failed to initialize Supabase: $e"));
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          title: 'JoyBites',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.orange,
            fontFamily: 'Roboto',
            textTheme: const TextTheme(
              headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(fontSize: 16),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.orange,
            fontFamily: 'Roboto',
            textTheme: const TextTheme(
              headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(fontSize: 16),
            ),
          ),
          themeMode: currentTheme,
          home: const EntryScreen(),
        );
      },
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String errorMessage;
  const ErrorScreen({super.key, required this.errorMessage});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              errorMessage,
              style: const TextStyle(fontSize: 18, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
