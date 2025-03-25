import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class SupabaseService {
  final SupabaseClient supabase;
  final logger = Logger();

  // Constructor for dependency injection
  SupabaseService({SupabaseClient? client})
      : supabase = client ?? Supabase.instance.client;

  static const String tableName = 'entries'; // Centralize table name

  // Save a new entry to Supabase
  Future<void> saveEntry(Map<String, dynamic> entry) async {
    try {
      await supabase.from(tableName).insert(entry);
      logger.i("Entry saved successfully: $entry");
    } catch (e) {
      logger.e("Error saving entry: $e");
      throw Exception('Failed to save entry: $e');
    }
  }

  // Fetch all entries from Supabase with optional pagination
  Future<List<Map<String, dynamic>>> fetchEntries({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final from = (page - 1) * limit; // Calculate the starting index
      final to = from + limit - 1; // Calculate the ending index

      final response = await supabase
          .from(tableName)
          .select('*')
          .order('created_at', ascending: false)
          .range(from, to); // Use range for pagination

      logger.d("Fetched entries successfully");
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      logger.e("Error fetching entries: $e");
      throw Exception('Failed to fetch entries: $e');
    }
  }

  // Delete multiple entries by their IDs
  Future<void> deleteEntries(List<int> ids) async {
    try {
      for (final id in ids) {
        await supabase.from(tableName).delete().eq('id', id); // Compare as integers
      }
      logger.i("Deleted entries with IDs: $ids");
    } catch (e) {
      logger.e("Error deleting entries: $e");
      throw Exception('Failed to delete entries: $e');
    }
  }

  // Get the last entry date
  Future<DateTime?> getLastEntryDate() async {
    try {
      final response = await supabase
          .from(tableName)
          .select('created_at')
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty && response[0]['created_at'] != null) {
        return DateTime.tryParse(response[0]['created_at']); // Use tryParse for safety
      }
      return null;
    } catch (e) {
      logger.e("Error getting last entry date: $e");
      return null;
    }
  }
}