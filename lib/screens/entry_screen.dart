import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import '../widgets/current_mood_widget.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});
  @override
  EntryScreenState createState() => EntryScreenState();
}

class EntryScreenState extends State<EntryScreen> {
  final TextEditingController _controller = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  String? _selectedMood;
  bool _isSaving = false;
  int? _cachedStreak;
  String _entryListStyle = 'card';

  // Key to force rebuild of CurrentMoodWidget.
  Key _currentMoodKey = UniqueKey();

  Future<void> loadPreferences() async {
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
    loadPreferences();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<int> calculateStreak() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;
    final entries = await _supabaseService.fetchEntries(userId: user.id, page: 1, limit: 30);
    if (entries.isEmpty) return 0;
    final datesSet = entries.map((entry) {
      DateTime dt = DateTime.parse(entry['created_at']).toLocal();
      return DateTime(dt.year, dt.month, dt.day);
    }).toSet();
    List<DateTime> dates = datesSet.toList();
    dates.sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime today = DateTime.now();
    DateTime currentDay = DateTime(today.year, today.month, today.day);
    while (dates.contains(currentDay.subtract(Duration(days: streak)))) {
      streak++;
    }
    return streak;
  }

  Future<void> _saveEntry() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _isSaving = true;
      });
      try {
        final user = Supabase.instance.client.auth.currentUser;
        final entry = {
          'user_id': user?.id,
          'text': _controller.text,
          'mood': _selectedMood ?? 'No mood',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };
        print("Saving entry: $entry");
        await _supabaseService.saveEntry(entry);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry saved!')),
        );
        _controller.clear();
        setState(() {
          _selectedMood = null;
          _currentMoodKey = UniqueKey();
        });
        await _loadStreak();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save entry: $e')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter something!')),
      );
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
          print("Selected mood: $mood");
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

  String getDailyQuote() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning! Embrace the possibilities of the day.";
    if (hour < 18) return "Good afternoon! Let your gratitude guide you.";
    return "Good evening! Reflect on the blessings of today.";
  }

  Widget _buildDailySummary() {
    String dailyQuote = getDailyQuote();
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Column(
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
                    children: [
                      const Icon(Icons.mood, color: Colors.blue),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 20,
                        child: CurrentMoodWidget(key: _currentMoodKey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            Center(
              child: Text(
                (_cachedStreak ?? 0) >= 7
                    ? "Amazing! You've reached a 7-day streak!"
                    : "Keep going! Every entry counts!",
                style: TextStyle(
                  fontSize: 16,
                  color: (_cachedStreak ?? 0) >= 7 ? Colors.green : Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar.
      body: SingleChildScrollView(
        child: Padding(
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
              SizedBox(
                height: 300,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _supabaseService.fetchEntries(userId: Supabase.instance.client.auth.currentUser?.id),
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
                                        "Created: ${entry['created_at'].toString().split('.')[0]}",
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
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
      ),
    );
  }
}
