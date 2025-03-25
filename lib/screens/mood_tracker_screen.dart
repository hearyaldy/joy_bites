import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, int> moodCounts = {};
  bool isLoading = true;
  int maxCount = 1;

  Future<void> _loadMoodCounts() async {
    try {
      final entries = await _supabaseService.fetchEntries(page: 1, limit: 100);
      final Map<String, int> counts = {};
      for (var entry in entries) {
        String mood = entry['mood'] ?? 'No mood';
        counts[mood] = (counts[mood] ?? 0) + 1;
      }
      if (counts.isNotEmpty) {
        maxCount = counts.values.reduce((a, b) => a > b ? a : b);
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : moodCounts.isEmpty
                ? Center(child: Text("No mood data available", style: TextStyle(fontSize: 18, color: Colors.grey)))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: moodCounts.entries.map((e) {
                      double progress = e.value / maxCount;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Text(e.key, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.shade200,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(e.value.toString(), style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
      ),
    );
  }
}
