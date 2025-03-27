import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

enum FeedLayout { timeline, list, grid }

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
  FeedLayout _feedLayout = FeedLayout.timeline;

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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
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
      final newEntries = await _supabaseService.fetchEntries(
        page: _page,
        limit: 10,
        mood: _filterMood,
      );
      setState(() {
        _entries.addAll(newEntries);
        if (newEntries.length < 10) _hasMore = false;
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
        if (newEntries.length < 10) _hasMore = false;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry deleted successfully!')),
      );
      _loadEntries(reset: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete entry: $e')),
      );
    }
  }

  // Group entries by date (yyyy-MM-dd).
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

  Widget _buildTimelineView() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return FadeTransition(
          opacity: _animationController,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (index != _entries.length - 1)
                    Container(
                      width: 2,
                      height: 60,
                      color: Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
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
                            ),
                            const Spacer(),
                            Text(
                              "Created: ${entry['created_at'].toString().split('.')[0]}",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return FadeTransition(
          opacity: _animationController,
          child: ListTile(
            title: Text(entry['text']),
            subtitle: Text("Mood: ${entry['mood'] ?? 'No mood'}\nCreated: ${entry['created_at'].toString().split('.')[0]}"),
            trailing: entry['user_id'] == currentUser?.id
                ? IconButton(
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
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return FadeTransition(
          opacity: _animationController,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
    );
  }

  // Build the feed based on selected layout.
  Widget _buildFeed() {
    switch (_feedLayout) {
      case FeedLayout.timeline:
        return _buildTimelineView();
      case FeedLayout.list:
        return _buildListView();
      case FeedLayout.grid:
        return _buildGridView();
      default:
        return _buildTimelineView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedEntries = _groupEntriesByDate();
    List<String> sortedDates = groupedEntries.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      // No AppBar here.
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
