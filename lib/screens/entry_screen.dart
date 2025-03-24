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

  Future<int> calculateStreak() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appName),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GlobalFeedScreen(),
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
                Icon(Icons.stars, color: Colors.orange),
                SizedBox(width: 8),
                FutureBuilder<int>(
                  future: calculateStreak(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text("Error calculating streak");
                    } else {
                      final streak = snapshot.data ?? 0;
                      return Text(
                        "Streak: $streak days",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                labelText: "What’s your one good thing today?",
                border: OutlineInputBorder(),
                counterText: "${_controller.text.length}/100",
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Text("😊"),
                  onPressed: () {
                    setState(() {
                      _selectedMood = "😊";
                    });
                  },
                ),
                IconButton(
                  icon: Text("😐"),
                  onPressed: () {
                    setState(() {
                      _selectedMood = "😐";
                    });
                  },
                ),
                IconButton(
                  icon: Text("😔"),
                  onPressed: () {
                    setState(() {
                      _selectedMood = "😔";
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (_controller.text.isNotEmpty) {
                        setState(() {
                          _isSaving = true;
                        });
                        try {
                          await _supabaseService.saveEntry({
                            'text': _controller.text,
                            'mood': _selectedMood,
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Entry saved!')),
                            );
                          }
                          _controller.clear();
                          _selectedMood = null;
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
                            SnackBar(content: Text('Please enter something!')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: Text(_isSaving ? 'Saving...' : 'Save'),
            ),
            const SizedBox(height: 20),
            Text(
              "Recent Entries",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _supabaseService.fetchEntries(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error loading entries"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No entries yet!"));
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
            Text(
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