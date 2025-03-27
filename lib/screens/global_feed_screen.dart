import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class GlobalFeedScreen extends StatefulWidget {
  const GlobalFeedScreen({super.key});

  @override
  _GlobalFeedScreenState createState() => _GlobalFeedScreenState();
}

class _GlobalFeedScreenState extends State<GlobalFeedScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  // Get the current authenticated user.
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final entries = await _supabaseService.fetchEntries(page: 1, limit: 20);
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching entries: $e");
    }
  }

  // Group entries by date (formatted as "yyyy-MM-dd")
  Map<String, List<Map<String, dynamic>>> _groupEntriesByDate() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var entry in _entries) {
      DateTime dt = DateTime.parse(entry['created_at']).toLocal();
      String dateKey =
          "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(entry);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedEntries = _groupEntriesByDate();
    // Sort dates in descending order (most recent first)
    List<String> sortedDates = groupedEntries.keys.toList()..sort((a, b) => b.compareTo(a));
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEntries,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  String dateKey = sortedDates[index];
                  List<Map<String, dynamic>> entriesForDate = groupedEntries[dateKey]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date header
                      Container(
                        width: double.infinity,
                        color: Colors.grey[200],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          dateKey,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // List of entries for this date
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entriesForDate.length,
                        itemBuilder: (context, idx) {
                          final entry = entriesForDate[idx];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: entry['avatar_url'] != null
                                  ? NetworkImage(entry['avatar_url'])
                                  : null,
                              backgroundColor: Colors.grey[300],
                              child: entry['avatar_url'] == null
                                  ? const Icon(Icons.person, color: Colors.white)
                                  : null,
                            ),
                            title: Text(entry['text']),
                            subtitle: Text("Created: ${entry['created_at'].toString().split('.')[0]}"),
                            trailing: entry['user_id'] == currentUser?.id
                                ? IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                    onPressed: () {
                                      // Optionally implement delete functionality here.
                                    },
                                  )
                                : null,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
