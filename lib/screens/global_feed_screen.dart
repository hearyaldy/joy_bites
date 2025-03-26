import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class GlobalFeedScreen extends StatefulWidget {
  const GlobalFeedScreen({super.key});

  @override
  _GlobalFeedScreenState createState() => _GlobalFeedScreenState();
}

class _GlobalFeedScreenState extends State<GlobalFeedScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _entries = [];
  int _page = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _filterMood;
  final ScrollController _scrollController = ScrollController();

  // Get the current authenticated user.
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadEntries(reset: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        _loadMoreEntries();
      }
    });
  }

  Future<void> _loadEntries({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
      _entries.clear();
    }
    try {
      // Fetch all entries (global feed, no userId filter).
      final newEntries = await _supabaseService.fetchEntries(
        page: _page,
        limit: 10,
        mood: _filterMood,
      );
      setState(() {
        _entries.addAll(newEntries);
        if (newEntries.length < 10) {
          _hasMore = false;
        }
      });
    } catch (e) {
      print("Error fetching entries: $e");
    }
  }

  Future<void> _loadMoreEntries() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() {
      _isLoadingMore = true;
      _page++;
    });
    try {
      final newEntries = await _supabaseService.fetchEntries(
        page: _page,
        limit: 10,
        mood: _filterMood,
      );
      setState(() {
        _entries.addAll(newEntries);
        if (newEntries.length < 10) {
          _hasMore = false;
        }
      });
    } catch (e) {
      print("Error loading more entries: $e");
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onFilterChanged(String? selected) {
    setState(() {
      _filterMood = selected;
    });
    _loadEntries(reset: true);
  }

  Future<void> _deleteEntry(String id) async {
    try {
      final int parsedId = int.tryParse(id) ?? -1;
      if (parsedId == -1) {
        throw Exception("Invalid ID format");
      }
      await _supabaseService.deleteEntries([parsedId]);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted successfully!')),
        );
      }
      _loadEntries(reset: true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete entry: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Global Positivity Feed"),
        backgroundColor: primaryColor,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: _filterMood,
              hint: const Text("Filter by Mood", style: TextStyle(color: Colors.white)),
              dropdownColor: primaryColor,
              icon: const Icon(Icons.filter_list, color: Colors.white),
              underline: Container(),
              onChanged: _onFilterChanged,
              items: <String>["😊", "😐", "😔", "No mood"]
                  .map((mood) => DropdownMenuItem<String>(
                        value: mood,
                        child: Text(mood, style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
      body: _entries.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await _loadEntries(reset: true);
              },
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _entries.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _entries.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final entry = _entries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          // Show delete button only if this entry belongs to the current user.
                          if (entry['user_id'] == currentUser?.id)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Delete Entry"),
                                    content: const Text("Are you sure you want to delete this entry?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteEntry(entry['id'].toString());
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
