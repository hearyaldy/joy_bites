import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class GlobalFeedScreen extends StatefulWidget {
  const GlobalFeedScreen({super.key});

  @override
  _GlobalFeedScreenState createState() => _GlobalFeedScreenState();
}

class _GlobalFeedScreenState extends State<GlobalFeedScreen> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _entries = [];
  int _page = 1;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _filterMood;
  final ScrollController _scrollController = ScrollController();

  // Get the current authenticated user.
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadEntries(reset: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
        _loadMoreEntries();
      }
    });
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _hasMore = true;
      _entries.clear();
    }
    try {
      // Fetch all entries (global feed, not filtering by userId)
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
      _animationController.forward(from: 0.0);
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
      _animationController.forward(from: 0.0);
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
      if (parsedId == -1) throw Exception("Invalid ID format");
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

  // Group entries by date (formatted as yyyy-MM-dd).
  Map<String, List<Map<String, dynamic>>> _groupEntriesByDate() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var entry in _entries) {
      DateTime dt = DateTime.parse(entry['created_at']).toLocal();
      String dateKey = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(entry);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedEntries = _groupEntriesByDate();
    List<String> sortedDates = groupedEntries.keys.toList()..sort((a, b) => b.compareTo(a));

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.orange.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _entries.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await _loadEntries(reset: true);
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      ...sortedDates.map((dateKey) {
                        List<Map<String, dynamic>> entriesForDate = groupedEntries[dateKey]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              color: Colors.orange.shade100,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              child: Text(
                                dateKey,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            MasonryGridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              itemCount: entriesForDate.length,
                              itemBuilder: (context, index) {
                                final entry = entriesForDate[index];
                                return FadeTransition(
                                  opacity: _animationController,
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry['text'],
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Chip(
                                                label: Text(entry['mood'] ?? 'No mood', style: const TextStyle(fontSize: 12)),
                                                backgroundColor: Colors.orange.shade100,
                                              ),
                                              const Spacer(),
                                              Text(
                                                entry['created_at'].toString().split('.')[0],
                                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          if (entry['user_id'] == currentUser?.id)
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 16),
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
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Divider(thickness: 2, height: 32),
                          ],
                        );
                      }).toList(),
                      if (_isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
