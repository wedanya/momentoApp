// lib/models/diary_entry.dart
class DiaryEntry {
  final String? id; // Changed from int? to String? for Supabase UUIDs
  final String? title;
  final String content;
  final String date;
  final String? imageUrl; // Correct: This is the property name in the class

  DiaryEntry({
    this.id, // Now a String?
    required this.title,
    required this.content,
    required this.date,
    this.imageUrl, // Correct: This is the parameter name for the constructor
  });

  // Converts a DiaryEntry object to a Map for Supabase insertion/update
  // Here, we use 'image_url' as the key to match common Supabase column naming conventions.
  Map<String, dynamic> toMap() {
    return {
      'id': id, // id is now String?
      'title': title,
      'content': content,
      'date': date,
      'image_url': imageUrl, // Use imageUrl (class property) as the value for the 'image_url' key
    };
  }

  // Creates a DiaryEntry object from a Map (e.g., from Supabase response)
  // Here, we read from 'image_url' (the database column name) and pass it to the
  // 'imageUrl' parameter of the constructor.
  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as String?, // id is now String?
      title: map['title'] as String,
      content: map['content'] as String,
      date: map['date'] as String,
      imageUrl: map['image_url'] as String?, // Correct: Pass map['image_url'] to constructor's imageUrl parameter
    );
  }

  // NOTE: fromJson and toJson are often used when dealing with actual JSON strings.
  // For Supabase, fromMap and toMap are usually sufficient as Supabase returns Maps directly.

  // Add this static method to enable fromJson deserialization
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String?, // id is now String?
      title: json['title'] as String,
      content: json['content'] as String,
      date: json['date'] as String,
      imageUrl: json['image_url'] as String?, // Correct: Pass json['image_url'] to constructor's imageUrl parameter
    );
  }

  Map<String, dynamic> toJson() {
    // This is typically used for converting to JSON string representation
    return {
      'id': id, // id is now String?
      'title': title,
      'content': content,
      'date': date,
      'image_url': imageUrl, // Use imageUrl (class property) as the value for the 'image_url' key
    };
  }

  // --- Removed: factory DiaryEntry.fromSqfliteMap (no longer needed) ---
}