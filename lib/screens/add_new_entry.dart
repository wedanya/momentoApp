// lib/screens/add_new_entry.dart
import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:supabase_flutter/supabase_flutter.dart'; // To get current user ID

import '../../models/diary_entry.dart';
import '../services/diary_service_supabase.dart'; // Your Supabase diary service
import '../services/image_storage_service.dart'; // Your Supabase image storage service

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // --- Correct Service Instances ---
  final DiaryServiceSupabase _diaryService = DiaryServiceSupabase();
  final ImageStorageService _imageStorageService = ImageStorageService(); // Instantiate ImageStorageService
  final ImagePicker _picker = ImagePicker(); // Instance of ImagePicker
  File? _imageFile; // To store the selected image file temporarily

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Function to pick an image from gallery or camera
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery); // Or ImageSource.camera

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Function to remove the selected image
  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      // Get current user ID for image upload
      final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User not authenticated. Cannot save entry.')),
          );
        }
        return;
      }

      String? imageUrl;
      if (_imageFile != null) {
        try {
          // --- Use ImageStorageService for actual upload ---
          imageUrl = await _imageStorageService.uploadDiaryImage(_imageFile!, currentUserId);
        } catch (e) {
          debugPrint('Error uploading image: $e');
          if (context.mounted) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
            );
          }
          return; // Stop saving if image upload fails
        }
      }

      final newEntry = DiaryEntry(
        id: null, // Supabase will generate the ID
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: DateTime.now().toIso8601String(),
        imageUrl: imageUrl, // Pass the uploaded image URL
      );

      try {
        await _diaryService.addEntry(newEntry); // Use DiaryServiceSupabase
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          Navigator.pop(context, true); // Pop with true to indicate success and reload list
        }
      } catch (e) {
        debugPrint('Error saving entry to Supabase: $e'); // Corrected message
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save entry: ${e.toString()}')),
          );
        }
      }
    }
  }

  // --- Removed Placeholder _uploadImageToCloudStorage function ---
  // Now directly using ImageStorageService

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Image selection section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: _imageFile != null
                      ? Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: _removeImage,
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text('Add Image (Optional)', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration( // Keep const for this if no TextStyle is added within it
                  labelText: 'Title (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                maxLength: 100,
                // Add style here for the input text if desired for the title field as well
                // style: TextStyle(fontFamily: 'Roboto'),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                controller: _contentController,
                // REMOVE `const` from InputDecoration if you add non-const TextStyles
                decoration: const InputDecoration( // Removed `const` here
                  labelText: 'Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(), // Keep const for border if it's constant
                  prefixIcon: Icon(Icons.edit_note), // Keep const for icon if it's constant
                  // Add TextStyle for the label text here (now valid without `const InputDecoration`)
                  labelStyle: TextStyle( // Use const if possible for TextStyle
                    fontFamily: 'Roboto', // Sets the font for the label text
                  ),
                  // If you add hintText, you can style it here
                  // hintStyle: const TextStyle(
                  //   fontFamily: 'Roboto',
                  // ),
                  // If you use maxLength, you can style the counter text here
                  // counterStyle: const TextStyle(
                  //   fontFamily: 'Roboto',
                  // ),
                ),
                // Apply style directly to the input text itself
                style: const TextStyle( // Apply style directly to the TextFormField
                  fontFamily: 'Roboto',
                ),
                maxLines: null, // Allow multiple lines
                minLines: 5,
                keyboardType: TextInputType.multiline,
                validator: (value) => value!.isEmpty ? 'Content cannot be empty' : null,
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Save Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}