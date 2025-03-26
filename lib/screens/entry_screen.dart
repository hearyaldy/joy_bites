import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import 'global_feed_screen.dart';
import 'mood_tracker_screen.dart';
import 'settings_screen.dart';
import 'auth_screen.dart';
import '../widgets/current_mood_widget.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  _EntryScreenState createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final TextEditingController _controller = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  String? _selectedMood;
  bool _isSaving = false;
  int? _cachedStreak;
  String _entryListStyle = 'card';

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _entryListStyle = prefs.getString('entryListStyle') ?? 'card';
    });
  }

  Future<void> _loadStreak() async {
    try {
      _cachedStreak = await calculateStreak();
    } catch (e) {
      print("Error loading streak: $e");
      _cachedStreak = 0;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _loadPreferences();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<int> calculateStreak() async {
    final lastEntryDate = await _supabaseService.getLastEntryDate();
    if (lastEntryDate == null) return 0;
    final now = DateTime.now().toUtc();
    final difference = now.difference(lastEntryDate.toUtc()).inDays;
    if (difference == 0) {
      return 1;
    } else if (difference == 1) {
      return 2;
    } else {
      return 0;
    }
  }

  Future<void> _saveEntry() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _isSaving = true;
      });
      try {
        final entry = {
          'text': _controller.text,
          'mood': _selectedMood ?? 'No mood',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };
        await _supabaseService.saveEntry(entry);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry saved!')),
          );
        }
        _controller.clear();
        setState(() {
          _selectedMood = null;
        });
        await _loadStreak();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save entry: $e')),
          );
        }
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter something!')),
        );
      }
    }
  }

  Widget _buildMoodButton(String mood) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMood = mood;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _selectedMood == mood ? Colors.orange : Colors.grey[300],
          ),
          child: Text(
            mood,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  // Returns a daily quote based on current time.
  String getDailyQuote() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good morning! Embrace the possibilities of the day.";
    } else if (hour < 18) {
      return "Good afternoon! Let your gratitude guide you.";
    } else {
      return "Good evening! Reflect on the blessings of today.";
    }
  }

  // Builds a daily summary combining streak, current mood, and a dynamic quote.
  Widget _buildDailySummary() {
    String dailyQuote = getDailyQuote();
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: Colors.orange),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              "Streak: ${_cachedStreak ?? 0} days",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
    Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mood, color: Colors.blue),
          const SizedBox(height: 4),
          SizedBox(
            height: 20,
            child: CurrentMoodWidget(),
          ),
        ],
      ),
    ),
  ],
),

            const SizedBox(height: 12),
            // Daily inspirational quote.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dailyQuote,
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Retrieve the current user.
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  @override
  Widget build(BuildContext context) {
    final user = currentUser;
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer header with user information.
            UserAccountsDrawerHeader(
              accountName: Text(user?.userMetadata?['full_name'] as String? ?? 'Guest User'),
              accountEmail: Text(user?.email ?? 'No Email'),
              currentAccountPicture: CircleAvatar(
                backgroundImage: ((user?.userMetadata?['avatar_url'] as String?) != null)
                    ? NetworkImage(user!.userMetadata!['avatar_url'] as String)
                    : null,
                child: ((user?.userMetadata?['avatar_url'] as String?) == null)
                    ? const Icon(Icons.person)
                    : null,
              ),
              decoration: BoxDecoration(
                color: primaryColor,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                // Navigate to a profile screen (to be implemented).
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text("Welcome, ${user?.userMetadata?['full_name'] as String? ?? 'Guest'}"),
        backgroundColor: primaryColor,
        actions: [
          // Mood Tracker button.
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MoodTrackerScreen()),
              );
            },
          ),
          // Global Feed button.
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GlobalFeedScreen()),
              );
            },
          ),
          // Settings button: reload preferences on return.
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              await _loadPreferences();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDailySummary(),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "What’s your one good thing today?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: '${_controller.text.length}/100',
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMoodButton("😊"),
                _buildMoodButton("😐"),
                _buildMoodButton("😔"),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveEntry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: primaryColor,
              ),
              child: Text(_isSaving ? 'Saving...' : 'Save'),
            ),
            const SizedBox(height: 20),
            const Text(
              "Recent Entries",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _supabaseService.fetchEntries(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error loading entries: ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text("No entries yet!", style: TextStyle(fontSize: 18, color: Colors.grey)),
                        ],
                      ),
                    );
                  } else {
                    final entries = snapshot.data!;
                    return ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        switch (_entryListStyle) {
                          case 'card':
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry['text'],
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text(entry['mood'] ?? 'No mood'),
                                          backgroundColor: Colors.orange.shade100,
                                          labelStyle: const TextStyle(color: Colors.orange),
                                        ),
                                        const Spacer(),
                                        Text(
                                          "Created at: ${entry['created_at'].toString().split('.')[0]}",
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          case 'compact':
                            return ListTile(
                              title: Text(entry['text']),
                              subtitle: Text("Mood: ${entry['mood'] ?? 'No mood'}"),
                            );
                          case 'minimal':
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                entry['text'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            );
                          default:
                            return const SizedBox();
                        }
                      },
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "\"Gratitude turns what we have into enough.\"",
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
