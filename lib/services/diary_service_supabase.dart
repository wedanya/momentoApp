// lib/services/diary_service_supabase.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/diary_entry.dart'; // Ensure your DiaryEntry model is correct

class DiaryServiceSupabase {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'diary_entries'; // Your Supabase table name for diary entries

  // Helper to get the current authenticated user's ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Fetches all diary entries for the current authenticated user from Supabase.
  Future<List<DiaryEntry>> getEntries() async {
    final userId = currentUserId;
    if (userId == null) {
      // If no user is logged in, return an empty list
      return [];
    }

    try {
      final response = await _supabase
          .from(_tableName)
          .select() // Select all columns
          .eq('user_id', userId) // userId is guaranteed non-null here
          .order('date', ascending: false) // Order by date descending (latest first)
          .limit(100); // Limit the number of entries for performance

      // Parse the list of maps into a list of DiaryEntry objects
      return response.map((map) => DiaryEntry.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Error fetching diary entries: $e');
    }
  }

  /// Adds a new diary entry to Supabase.
  Future<DiaryEntry> addEntry(DiaryEntry entry) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('No authenticated user found for adding entry.');
    }

    try {
      // Prepare the data for insertion.
      // Supabase will automatically generate 'id' if it's UUID and default is gen_random_uuid().
      // Ensure 'user_id' is included.
      final entryData = entry.toMap();
      entryData['user_id'] = userId; // userId is guaranteed non-null here

      final response = await _supabase
          .from(_tableName)
          .insert(entryData)
          .select() // Select the inserted row to get the generated ID and other data
          .single(); // Expect a single row back

      return DiaryEntry.fromMap(response); // Return the newly created entry with its Supabase ID
    } catch (e) {
      throw Exception('Error adding diary entry: $e');
    }
  }

  /// Updates an existing diary entry in Supabase.
  Future<void> updateEntry(DiaryEntry entry) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('No authenticated user found for updating entry.');
    }
    if (entry.id == null) {
      throw Exception('Cannot update entry without an ID.');
    }

    try {
      final entryData = entry.toMap();
      // Ensure user_id is included (though it shouldn't change for an existing entry)
      entryData['user_id'] = userId; 

      await _supabase
          .from(_tableName)
          .update(entryData)
          .eq('id', entry.id!) // ⬅️ Use null assertion operator here
          .eq('user_id', userId); // userId is guaranteed non-null here
    } catch (e) {
      throw Exception('Error updating diary entry: $e');
    }
  }

  /// Deletes a diary entry from Supabase by its ID.
  Future<void> deleteEntry(String entryId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('No authenticated user found for deleting entry.');
    }

    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', entryId) // entryId is already a non-nullable String
          .eq('user_id', userId); // userId is guaranteed non-null here
    } catch (e) {
      throw Exception('Error deleting diary entry: $e');
    }
  }
}