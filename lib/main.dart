import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/entry_screen.dart';
import 'utils/constants.dart';

void main() async {
  // Load .env file
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with credentials from .env
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!, // Fetch from .env
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!, // Fetch from .env
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: EntryScreen(),
    );
  }
}