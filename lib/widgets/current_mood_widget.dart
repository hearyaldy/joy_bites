import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class CurrentMoodWidget extends StatelessWidget {
  final SupabaseService supabaseService = SupabaseService();

  CurrentMoodWidget({super.key});

  Future<String> _getCurrentMood() async {
    DateTime now = DateTime.now().toUtc();
    DateTime startOfDay = DateTime.utc(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));
    List<Map<String, dynamic>> todayEntries = await supabaseService.fetchEntries(
      page: 1,
      limit: 100,
      startDate: startOfDay,
      endDate: endOfDay,
    );
    Map<String, int> moodCount = {};
    for (var entry in todayEntries) {
      String mood = entry['mood'] ?? 'No mood';
      moodCount[mood] = (moodCount[mood] ?? 0) + 1;
    }
    if (moodCount.isEmpty) {
      return "No mood recorded";
    } else {
      // Return the mood with the highest count.
      return moodCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getCurrentMood(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Current Mood: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(snapshot.data!, style: const TextStyle(fontSize: 18)),
            ],
          );
        }
      },
    );
  }
}
