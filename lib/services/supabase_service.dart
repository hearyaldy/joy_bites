import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart'; // Add this import

class SupabaseService {
  final supabase = Supabase.instance.client;
  final logger = Logger(); // Add logger instance
  
  // Save a new entry to Supabase
  Future<void> saveEntry(Map<String, dynamic> entry) async {
    try {
      await supabase.from('entries').insert(entry);
      logger.i("Entry saved successfully: $entry"); // Use logger instead of print
    } catch (e) {
      logger.e("Error saving entry: $e"); // Use logger instead of print
      throw Exception('Failed to save entry: $e');
    }
  }

  // Fetch all entries from Supabase
  Future<List<Map<String, dynamic>>> fetchEntries() async {
    try {
      final response = await supabase.from('entries').select('*');
      logger.d("Fetched entries successfully"); // Use logger instead of print
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      logger.e("Error fetching entries: $e"); // Use logger instead of print
      throw Exception('Failed to fetch entries: $e');
    }
  }

  // Delete multiple entries by their IDs
  Future<void> deleteEntries(List<String> ids) async {
    try {
      // Fix: Use 'in' instead of 'isIn'
      await supabase.from('entries').delete().any('id', ids);
      logger.i("Deleted entries with IDs: $ids"); // Use logger instead of print
    } catch (e) {
      logger.e("Error deleting entries: $e"); // Use logger instead of print
      throw Exception('Failed to delete entries: $e');
    }
  }
  
  // Add the missing getLastEntryDate method
  Future<DateTime?> getLastEntryDate() async {
    try {
      final response = await supabase
          .from('entries')
          .select('created_at')
          .order('created_at', ascending: false)
          .limit(1);
      
      if (response.isNotEmpty && response[0]['created_at'] != null) {
        return DateTime.parse(response[0]['created_at']);
      }
      return null;
    } catch (e) {
      logger.e("Error getting last entry date: $e");
      return null;
    }
  }
}

extension on PostgrestFilterBuilder {
  any(String s, List<String> ids) {}
}