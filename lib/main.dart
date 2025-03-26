import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/entry_screen.dart';
import 'screens/auth_screen.dart';

// Global theme notifier for dynamic theme switching.
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

  // Check if user is authenticated
  final session = Supabase.instance.client.auth.currentSession;
  runApp(MyApp(home: session != null ? const EntryScreen() : const AuthScreen()));
}

class MyApp extends StatelessWidget {
  final Widget home;
  const MyApp({super.key, required this.home});
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'JoyBites',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.orange,
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.orange,
            fontFamily: 'Roboto',
          ),
          themeMode: themeMode,
          home: home,
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
