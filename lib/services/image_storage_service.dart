import 'dart:io';
// ignore: unnecessary_import
import 'dart:typed_data'; // Add this import for Uint8List
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class ImageStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'images'; // Define your storage bucket name

  // Method for mobile platforms (takes File)
  Future<String> uploadDiaryImage(File imageFile, String userId) async {
    try {
      final String fileName = '$userId/${DateTime.now().microsecondsSinceEpoch}.png';
      await _supabase.storage
          .from(_bucketName)
          .upload(fileName, imageFile, fileOptions: const FileOptions(cacheControl: '3600', upsert: false));

      final String publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image from File: $e');
    }
  }

  // NEW METHOD for web platforms (takes Uint8List)
  Future<String> uploadDiaryImageBytes(Uint8List imageBytes, String userId) async {
    try {
      final String fileName = '$userId/${DateTime.now().microsecondsSinceEpoch}.png';
      await _supabase.storage
          .from(_bucketName)
          .uploadBinary( // Use uploadBinary for bytes
            fileName,
            imageBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: 'image/png', // Important: specify content type for binary uploads
            ),
          );

      final String publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image from Bytes: $e');
    }
  } // <--- This closing brace was missing!

  // Deletes an image from storage using its URL
  Future<void> deleteImageByUrl(String imageUrl) async {
    if (imageUrl.isEmpty) return;

    try {
      // Extract the file path from the public URL.
      // Supabase public URLs are like: [supabase_url]/storage/v1/object/public/bucket_name/path/to/file
      final Uri uri = Uri.parse(imageUrl);
      // The relevant part of the path starts after 'public/bucket_name/'
      final int publicPathIndex = uri.pathSegments.indexOf('public');
      if (publicPathIndex == -1 || publicPathIndex + 2 >= uri.pathSegments.length) {
        debugPrint('Invalid Supabase URL for deletion: $imageUrl');
        return;
      }
      // Construct the file path relative to the bucket
      final String filePath = uri.pathSegments.sublist(publicPathIndex + 2).join('/');
      debugPrint('Attempting to delete Supabase path: $_bucketName/$filePath');

      await _supabase.storage.from(_bucketName).remove([filePath]);
      debugPrint('Deleted image from Supabase: $imageUrl');
    } catch (e) {
      debugPrint('Error deleting image from Supabase: $e');
      rethrow;
    }
  }
}