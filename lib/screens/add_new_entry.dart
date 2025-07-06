import 'dart:io'; // Required for File
import 'dart:typed_data'; // Required for Uint8List (web)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Required for ImagePicker
import 'package:supabase_flutter/supabase_flutter.dart'; // To get current user ID
import 'package:google_fonts/google_fonts.dart'; // For consistent fonts

import '../../models/diary_entry.dart'; // Adjust path if necessary
import '../services/diary_service_supabase.dart'; // Adjust path if necessary
import '../services/image_storage_service.dart'; // Adjust path if necessary

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final DiaryServiceSupabase _diaryService = DiaryServiceSupabase();
  final ImageStorageService _imageStorageService = ImageStorageService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile; // To store the picked image file (for mobile platforms)
  Uint8List? _imageBytes; // To store image bytes (for web and other non-File platforms)
  bool _isLoading = false; // For showing loading indicator

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Helper method to pick image from a given source (gallery or camera)
  // In _AddEntryScreenState
Future<void> _getImage(ImageSource source) async {
  try {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      // Check if running on mobile (Android/iOS) where File API is available
      // ignore: use_build_context_synchronously
      if (Theme.of(context).platform == TargetPlatform.android ||
          // ignore: use_build_context_synchronously
          Theme.of(context).platform == TargetPlatform.iOS) {
        setState(() {
          _imageFile = File(pickedFile.path); // Use File for mobile
          _imageBytes = null; // Clear web bytes if previously set
        });
      } else {
        // For web, desktop, and other platforms where File is not directly supported
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes; // Use bytes for web
          _imageFile = null; // Clear mobile file if previously set
        });
      }
    }
  } catch (e) {
    debugPrint("Error picking image: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }
}

  // Function to present choice between gallery and camera
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from Gallery'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _getImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Function to remove the selected image
  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imageBytes = null; // Clear bytes if set
    });
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not authenticated. Cannot save entry.')),
        );
      }
      setState(() { _isLoading = false; }); // Stop loading
      return;
    }

    String? imageUrl;
    if (_imageFile != null) {
      try {
        // Use ImageStorageService for actual upload
        imageUrl = await _imageStorageService.uploadDiaryImage(_imageFile!, currentUserId);
      } catch (e) {
        debugPrint('Error uploading image: $e');
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
          );
        }
        setState(() { _isLoading = false; }); // Stop loading
        return; // Stop saving if image upload fails
      }
    }
    else if (_imageBytes != null) { // For web (Uint8List bytes)
    try {
      // This method will be added/modified in ImageStorageService
      imageUrl = await _imageStorageService.uploadDiaryImageBytes(_imageBytes!, currentUserId);
    } catch (e) {
      debugPrint('Error uploading image (Bytes): $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image (web): ${e.toString()}')),
        );
      }
      setState(() { _isLoading = false; });
      return;
    }
  }

    final newEntry = DiaryEntry(
      id: null, // Supabase will generate the ID
      title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(), // Optional title
      content: _contentController.text.trim(),
      date: DateTime.now().toIso8601String(), // Use current time
      imageUrl: imageUrl, // Pass the uploaded image URL
    );

    try {
      await _diaryService.addEntry(newEntry); // Use DiaryServiceSupabase
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diary entry saved successfully!')),
        );
        // ignore: use_build_context_synchronously
        Navigator.pop(context, true); // Pop with true to indicate success and reload list
      }
    } catch (e) {
      debugPrint('Error saving entry to Supabase: $e');
      if (context.mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save entry: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; // Stop loading regardless of outcome
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Entry',
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey[800], // Darker app bar
        foregroundColor: Colors.white,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveEntry,
                ),
        ],
      ),
      // Apply a consistent background, perhaps similar to your DiaryListScreen
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF263238), // Dark Blue Grey
              Color(0xFF37474F), // Lighter Blue Grey
            ],
          ),
        ),
        child: SingleChildScrollView(
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
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.1), // Semi-transparent background
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white54),
                    ),
                    alignment: Alignment.center,
                    child: (_imageFile != null || _imageBytes != null)
                        ? Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(9), // Slightly less than container
                                child: _imageFile != null
                    ? Image.file( // Use Image.file for mobile
                        _imageFile!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Image.memory( // Use Image.memory for web
                        _imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 30),
                                onPressed: _removeImage,
                                splashRadius: 20,
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ignore: prefer_const_constructors
                              Icon(Icons.add_photo_alternate, size: 50, color: Colors.white70),
                              const SizedBox(height: 8),
                              Text('Add Image (Optional)', style: GoogleFonts.roboto(color: Colors.white70)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title (Optional)',
                    labelStyle: GoogleFonts.roboto(color: Colors.white70),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.title, color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    // ignore: deprecated_member_use
                    fillColor: Colors.white.withOpacity(0.1),
                    filled: true,
                  ),
                  style: GoogleFonts.roboto(color: Colors.white),
                  maxLength: 100,
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    labelStyle: GoogleFonts.roboto(color: Colors.white70),
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.edit_note, color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    // ignore: deprecated_member_use
                    fillColor: Colors.white.withOpacity(0.1),
                    filled: true,
                  ),
                  style: GoogleFonts.roboto(color: Colors.white),
                  maxLines: null,
                  minLines: 5,
                  keyboardType: TextInputType.multiline,
                  validator: (value) => value!.isEmpty ? 'Content cannot be empty' : null,
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveEntry, // Disable button while loading
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    // ignore: deprecated_member_use
                    backgroundColor: Colors.white.withOpacity(0.3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.white70),
                    ),
                    textStyle: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Save Entry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}