import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final supabase = Supabase.instance.client;

  // Save a new entry to Supabase
  Future<void> saveEntry(Map<String, dynamic> entry) async {
    try {
      await supabase.from('entries').insert(entry);
    } catch (e) {
      throw Exception('Failed to save entry: $e');
    }
  }

  // Fetch all entries from Supabase
  Future<List<Map<String, dynamic>>> fetchEntries() async {
    try {
      final response = await supabase.from('entries').select('*');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch entries: $e');
    }
  }

  // Get the date of the last entry
  Future<DateTime?> getLastEntryDate() async {
    try {
      final response = await supabase
          .from('entries')
          .select('created_at')
          .order('created_at', ascending: false)
          .limit(1);
      if (response.isNotEmpty) {
        return DateTime.parse(response[0]['created_at']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch last entry date: $e');
    }
  }

  // Delete multiple entries by their IDs
  Future<void> deleteEntries(List<String> ids) async {
    try {
      await supabase.from('entries').delete().in_('id', ids);
    } catch (e) {
      throw Exception('Failed to delete entries: $e');
    }
  }
}