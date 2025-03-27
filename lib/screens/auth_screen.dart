import 'package:flutter/material.dart';
import 'entry_screen.dart'; // Update this import if EntryScreen is in another folder

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Example authentication method
  Future<void> _login() async {
    // Simulate an authentication delay
    await Future.delayed(const Duration(seconds: 1));
    // After successful auth, navigate to EntryScreen
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const EntryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Authentication"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _login,
          child: const Text("Login"),
        ),
      ),
    );
  }
}
