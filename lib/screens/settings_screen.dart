import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Theme options
  bool _isDarkMode = false;
  String _themeMode = 'system'; // Can be 'light', 'dark', or 'system'

  // Entry list style options
  String _entryListStyle = 'card'; // Can be 'card', 'compact', or 'minimal'

  // Notifications
  bool _notificationsEnabled = true;

  // Load saved preferences on initialization
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Save preferences using SharedPreferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeMode);
    await prefs.setString('entryListStyle', _entryListStyle);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
  }

  // Load preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = prefs.getString('themeMode') ?? 'system';
      _entryListStyle = prefs.getString('entryListStyle') ?? 'card';
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _isDarkMode = _themeMode == 'dark';
    });
  }

  // Show dialog for resetting streaks
  Future<void> _showResetStreakDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Streak"),
        content: const Text(
            "Are you sure you want to reset your streak? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              // Reset streak logic here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Streak reset successfully!')),
              );
              Navigator.pop(context);
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Mode Selection
          ListTile(
            title: const Text("Theme"),
            subtitle: Text(_themeMode.capitalize()),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text("System Default"),
                      onTap: () {
                        setState(() {
                          _themeMode = 'system';
                          _isDarkMode = false;
                        });
                        _savePreferences();
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: const Text("Light Mode"),
                      onTap: () {
                        setState(() {
                          _themeMode = 'light';
                          _isDarkMode = false;
                        });
                        _savePreferences();
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: const Text("Dark Mode"),
                      onTap: () {
                        setState(() {
                          _themeMode = 'dark';
                          _isDarkMode = true;
                        });
                        _savePreferences();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          // Entry List Style Selection
          ListTile(
            title: const Text("Entry List Style"),
            subtitle: Text(_entryListStyle.capitalize()),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text("Card-Based"),
                      onTap: () {
                        setState(() => _entryListStyle = 'card');
                        _savePreferences();
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: const Text("Compact"),
                      onTap: () {
                        setState(() => _entryListStyle = 'compact');
                        _savePreferences();
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: const Text("Minimal"),
                      onTap: () {
                        setState(() => _entryListStyle = 'minimal');
                        _savePreferences();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          // Notifications Toggle
          SwitchListTile(
            title: const Text("Enable Notifications"),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _savePreferences();
            },
          ),

          // Reset Streak Option
          ListTile(
            title: const Text("Reset Streak"),
            onTap: _showResetStreakDialog,
          ),

          // About Section
          ListTile(
            title: const Text("About"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("About JoyBites"),
                  content: const Text(
                      "An app to share positivity and track your gratitude streak."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helper extension to capitalize strings.
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
