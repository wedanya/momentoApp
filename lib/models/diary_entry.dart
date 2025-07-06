// lib/models/diary_entry.dart

class DiaryEntry {
  final String id;
  final String content;
  final String? imageUrl;
  final DateTime date;
  final String userId; // Add this if you track user_id in your table

  DiaryEntry({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.date,
    required this.userId, // Include in constructor
  });

  // Factory constructor to create a DiaryEntry from a Map (Supabase response)
  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as String,
      content: map['content'] as String,
      imageUrl: map['image_url'] as String?,
      date: DateTime.parse(map['created_at'] as String), // Parse ISO 8601 string
      userId: map['user_id'] as String, // Get user_id from map
    );
  }

  // Optional: toMap method if you need to convert back to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'image_url': imageUrl,
      'created_at': date.toIso8601String(),
      'user_id': userId,
    };
  }
}