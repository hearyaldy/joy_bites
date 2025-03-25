import 'package:flutter/material.dart';
import 'package:joy_bites/utils/constants.dart';
import '../services/supabase_service.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, int> moodCounts = {};
  bool isLoading = true;

  Future<void> _loadMoodCounts() async {
    try {
      // Fetch a larger batch of entries for mood tracking analysis
      final entries = await _supabaseService.fetchEntries(page: 1, limit: 100);
      final Map<String, int> counts = {};
      for (var entry in entries) {
        String mood = entry['mood'] ?? 'No mood';
        counts[mood] = (counts[mood] ?? 0) + 1;
      }
      setState(() {
        moodCounts = counts;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading mood counts: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMoodCounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mood Tracker"),
        backgroundColor: primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: moodCounts.entries.map((e) {
                return ListTile(
                  title: Text("Mood: ${e.key}"),
                  trailing: Text(e.value.toString()),
                );
              }).toList(),
            ),
    );
  }
}
