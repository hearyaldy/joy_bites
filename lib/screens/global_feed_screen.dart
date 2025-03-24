import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class GlobalFeedScreen extends StatefulWidget {
  const GlobalFeedScreen({super.key});

  @override
  _GlobalFeedScreenState createState() => _GlobalFeedScreenState();
}

class _GlobalFeedScreenState extends State<GlobalFeedScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final Map<String, bool> _selectedEntries = {};

  Future<void> deleteSelectedEntries() async {
    try {
      final selectedIds = _selectedEntries.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();
      await _supabaseService.deleteEntries(selectedIds);
      setState(() {
        _selectedEntries.clear();
      });
    } catch (e) {
      print("Error deleting selected entries: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Global Positivity Feed"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: deleteSelectedEntries,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _supabaseService.fetchEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading feed: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No entries yet!"));
          } else {
            final entries = snapshot.data!;
            return ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return CheckboxListTile(
                  title: Text(entry['text']),
                  subtitle: Text(entry['created_at'].toString()),
                  value: _selectedEntries[entry['id']] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _selectedEntries[entry['id']] = value!;
                    });
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}