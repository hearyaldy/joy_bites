import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../main.dart'; // for themeModeNotifier

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // "system", "light", or "dark"
  String _themeMode = 'system';
  // "card", "compact", or "minimal"
  String _entryListStyle = 'card';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeMode);
    await prefs.setString('entryListStyle', _entryListStyle);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = prefs.getString('themeMode') ?? 'system';
      _entryListStyle = prefs.getString('entryListStyle') ?? 'card';
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
    _updateTheme();
  }

  void _updateTheme() {
    switch (_themeMode) {
      case 'light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      case 'dark':
        themeModeNotifier.value = ThemeMode.dark;
        break;
      default:
        themeModeNotifier.value = ThemeMode.system;
    }
  }

  Future<void> _showResetStreakDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Streak"),
        content: const Text("Are you sure you want to reset your streak? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
        children: [
          _buildSectionTitle("Theme"),
          RadioListTile<String>(
            value: 'system',
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() {
                _themeMode = value!;
                _savePreferences();
                _updateTheme();
              });
            },
            title: const Text("System Default"),
            secondary: const Icon(Icons.settings_system_daydream),
          ),
          RadioListTile<String>(
            value: 'light',
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() {
                _themeMode = value!;
                _savePreferences();
                _updateTheme();
              });
            },
            title: const Text("Light Mode"),
            secondary: const Icon(Icons.wb_sunny),
          ),
          RadioListTile<String>(
            value: 'dark',
            groupValue: _themeMode,
            onChanged: (value) {
              setState(() {
                _themeMode = value!;
                _savePreferences();
                _updateTheme();
              });
            },
            title: const Text("Dark Mode"),
            secondary: const Icon(Icons.nightlight_round),
          ),
          const Divider(),
          _buildSectionTitle("Entry List Style"),
          RadioListTile<String>(
            value: 'card',
            groupValue: _entryListStyle,
            onChanged: (value) {
              setState(() {
                _entryListStyle = value!;
                _savePreferences();
              });
            },
            title: const Text("Card-Based"),
            secondary: const Icon(Icons.view_agenda),
          ),
          RadioListTile<String>(
            value: 'compact',
            groupValue: _entryListStyle,
            onChanged: (value) {
              setState(() {
                _entryListStyle = value!;
                _savePreferences();
              });
            },
            title: const Text("Compact"),
            secondary: const Icon(Icons.view_list),
          ),
          RadioListTile<String>(
            value: 'minimal',
            groupValue: _entryListStyle,
            onChanged: (value) {
              setState(() {
                _entryListStyle = value!;
                _savePreferences();
              });
            },
            title: const Text("Minimal"),
            secondary: const Icon(Icons.text_fields),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text("Enable Notifications"),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
                _savePreferences();
              });
            },
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text("Reset Streak"),
            onTap: _showResetStreakDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("About JoyBites"),
                  content: const Text("An app to share positivity and track your gratitude streak."),
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

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
