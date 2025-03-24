import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'global_feed_screen.dart'; // Import the Global Feed screen
import '../utils/constants.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  _EntryScreenState createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final TextEditingController _controller = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  String? _selectedMood;
  bool _isSaving = false; // Track if the save operation is in progress
  int? _cachedStreak; // Cache streak value to avoid recalculating

  // Load streak on initialization
  Future<void> _loadStreak() async {
    try {
      _cachedStreak = await calculateStreak();
    } catch (e) {
      print("Error loading streak: $e");
      _cachedStreak = 0; // Default to 0 if an error occurs
    }
    setState(() {}); // Update UI after loading streak
  }

  @override
  void initState() {
    super.initState();
    _loadStreak(); // Load streak when the widget initializes
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose of the controller to prevent memory leaks
    super.dispose();
  }

  // Calculate streak based on last entry date
  Future<int> calculateStreak() async {
    final lastEntryDate = await _supabaseService.getLastEntryDate();
    if (lastEntryDate == null) return 0;

    final now = DateTime.now().toUtc(); // Use UTC to avoid time zone issues
    final difference = now.difference(lastEntryDate.toUtc()).inDays;

    if (difference == 0) {
      return 1; // Entry made today
    } else if (difference == 1) {
      return 2; // Entry made yesterday
    } else {
      return 0; // Streak broken
    }
  }

  // Save the user's entry to Supabase
  Future<void> _saveEntry() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _isSaving = true; // Disable save button while saving
      });
      try {
        await _supabaseService.saveEntry({
          'text': _controller.text,
          'mood': _selectedMood,
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry saved!')),
          );
        }

        _controller.clear(); // Clear text field
        setState(() {
          _selectedMood = null; // Reset mood selection
        });

        // Reload streak after saving a new entry
        await _loadStreak();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save entry: $e')),
          );
        }
      } finally {
        setState(() {
          _isSaving = false; // Re-enable save button
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

  // Build reusable mood buttons
  Widget _buildMoodButton(String mood) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMood = mood;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _selectedMood == mood ? primaryColor : Colors.grey[300],
          ),
          child: Text(
            mood,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appName),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GlobalFeedScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.stars, color: Colors.orange),
                const SizedBox(width: 8),
                _cachedStreak != null
                    ? Text(
                        "Streak: $_cachedStreak days",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      )
                    : const CircularProgressIndicator(), // Show loader while streak loads
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "What’s your one good thing today?",
                border: const OutlineInputBorder(),
                counterText: '${_controller.text.length}/100', // Dynamic counter
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
                    return const Center(child: Text("No entries yet!"));
                  } else {
                    final entries = snapshot.data!;
                    return ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return ListTile(
                          title: Text(entry['text']),
                          subtitle: Text(entry['created_at'].toString()),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "\"Gratitude turns what we have into enough.\"",
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}