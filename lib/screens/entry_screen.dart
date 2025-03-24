import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  // Fixed: Using public type in public API
  State<EntryScreen> createState() => EntryScreenState();
}

// Fixed: Made the state class public
class EntryScreenState extends State<EntryScreen> {
  final TextEditingController _controller = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  String? _selectedMood;
  bool _isSaving = false;

  // Simple logging function
  void _log(String message, {bool isError = false}) {
    if (isError) {
      print('ERROR: $message');
    } else {
      print('INFO: $message');
    }
    // In the future, you could replace this with a proper logging framework
  }

  Future<int> calculateStreak() async {
    try {
      final lastEntryDate = await _supabaseService.getLastEntryDate();
      if (lastEntryDate == null) return 0;

      final now = DateTime.now();
      final difference = now.difference(lastEntryDate).inDays;

      if (difference == 0) {
        return 1; // Entry made today
      } else if (difference == 1) {
        return 2; // Entry made yesterday
      } else {
        return 0; // Streak broken
      }
    } catch (e) {
      // Fixed: Using _log instead of print
      _log("Error calculating streak: $e", isError: true);
      return 0; // Default to 0 if an error occurs
    }
  }

  Future<void> _saveEntry() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _isSaving = true;
      });
      try {
        await _supabaseService.saveEntry({
          'text': _controller.text,
          'mood': _selectedMood,
        });
        
        // BuildContext usage is already properly guarded
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry saved!')),
          );
        }
        
        _controller.clear();
        setState(() {
          _selectedMood = null;
        });
      } catch (e) {
        if (mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter something!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Positivity Journal"),
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
                FutureBuilder<int>(
                  future: calculateStreak(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return const Text("Error calculating streak");
                    } else {
                      final streak = snapshot.data ?? 0;
                      return Text(
                        "Streak: $streak days",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "What's your one good thing today?",
                border: const OutlineInputBorder(),
                counterText: "${_controller.text.length}/100",
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
                backgroundColor: Colors.orange,
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
                    return const Center(child: Text("Error loading entries"));
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
}