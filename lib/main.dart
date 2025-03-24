import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/entry_screen.dart'; // Import the EntryScreen widget

void main() async {
  // Ensure Flutter bindings are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Load the .env file
  await dotenv.load(fileName: ".env");

  try {
    // Initialize Supabase with credentials from the .env file
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    print("Supabase initialized successfully.");
  } catch (e) {
    // Handle initialization errors gracefully
    print("Failed to initialize Supabase: $e");
    // Optionally, show an error message to the user or exit the app
    runApp(ErrorScreen(errorMessage: "Failed to initialize Supabase: $e"));
    return;
  }

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JoyBites',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Roboto', // Optional: Use a custom font for consistency
        textTheme: TextTheme(
          // Replace headline1 with headlineLarge
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          // Replace bodyText1 with bodyLarge
          bodyLarge: TextStyle(fontSize: 16),
        ),
      ),
      home: const EntryScreen(), // Set EntryScreen as the home screen
    );
  }
}

// Error Screen Widget
class ErrorScreen extends StatelessWidget {
  final String errorMessage;

  const ErrorScreen({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Error"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              errorMessage,
              style: TextStyle(fontSize: 18, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}