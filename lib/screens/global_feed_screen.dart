import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart'; // Import constants for theming

class GlobalFeedScreen extends StatefulWidget {
  const GlobalFeedScreen({super.key});

  @override
  _GlobalFeedScreenState createState() => _GlobalFeedScreenState();
}

class _GlobalFeedScreenState extends State<GlobalFeedScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final Map<String, bool> _selectedEntries = {};

  // Delete selected entries after confirmation
  Future<void> _deleteSelectedEntries() async {
    try {
      final selectedIds = _selectedEntries.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      if (selectedIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No entries selected to delete.')),
        );
        return;
      }

      // Show confirmation dialog before deleting
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete the selected entries?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _supabaseService.deleteEntries(selectedIds);
        setState(() {
          _selectedEntries.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entries deleted successfully.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete entries: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Global Positivity Feed"),
        backgroundColor: primaryColor, // Use centralized theme color
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteSelectedEntries,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _supabaseService.fetchEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading feed: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No entries yet!",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
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