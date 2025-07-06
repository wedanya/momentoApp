// Ensure these imports are at the very top of your list_diary.dart file
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
// Make sure this path is correct

import 'dart:io'; // Required for File
import 'package:image_picker/image_picker.dart'; // Required for ImagePicker

// ... (Your DiaryContentPage and SettingsPage should be above this)

// --- START OF COMPLETE UPDATED AddEntryPage CLASS ---
class AddEntryPage extends StatefulWidget {
  const AddEntryPage({super.key});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  // --- All State Variables Declared Here ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;
  File? _selectedImage; // <--- This is the variable causing the error if misplaced
  final ImagePicker _picker = ImagePicker(); // ImagePicker instance

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // --- Image Picking Methods ---
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

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
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

  // --- Image Upload Method ---
  Future<String?> _uploadImage() async {
    if (_selectedImage == null) {
      return null; // No image selected
    }

    final String userId = Supabase.instance.client.auth.currentUser!.id;
    final String fileName = '$userId/${DateTime.now().microsecondsSinceEpoch}.png'; // Unique file path

    try {
      // Ensure 'diary-images' is your correct Supabase Storage bucket name
      final String publicUrl = await Supabase.instance.client.storage
          .from('diary-images')
          .upload(fileName, _selectedImage!,
              fileOptions: const FileOptions(
                cacheControl: '3600', // Cache for 1 hour
                upsert: false, // Don't overwrite if file exists
              ));
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
        );
      }
      return null; // Return null on error
    }
  }

  // --- Add Diary Entry Method ---
  Future<void> _addDiaryEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final User? currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to add an entry.')),
        );
      }
      setState(() { _isLoading = false; });
      return;
    }

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadImage(); // Upload image first
      if (imageUrl == null) {
        setState(() { _isLoading = false; });
        return; // Stop if image upload failed
      }
    }

    try {
      // Ensure 'new_diary' is your correct Supabase database table name
      await Supabase.instance.client.from('new_diary').insert({
        'content': _contentController.text.trim(),
        'user_id': currentUser.id,
        'image_url': imageUrl, // Include the image URL here
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diary entry added successfully!')),
        );
        _contentController.clear();
        setState(() {
          _selectedImage = null; // Clear selected image after successful submission
        });
      }
    } catch (e) {
      debugPrint('Error adding diary entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add entry: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- Build Method for UI ---
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Add New Diary Entry',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _contentController,
              maxLines: 8,
              minLines: 3,
              decoration: InputDecoration(
                labelText: 'Your thoughts...',
                labelStyle: GoogleFonts.roboto(color: Colors.white70),
                alignLabelWithHint: true,
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
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Entry cannot be empty.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // --- Image Picking Button ---
            ElevatedButton.icon(
              icon: const Icon(Icons.image, color: Colors.white),
              label: Text(
                _selectedImage == null ? 'Pick Image' : 'Change Image',
                style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
              ),
              onPressed: _pickImage, // Calls the method to show bottom sheet
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                // ignore: deprecated_member_use
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // --- Image Preview ---
            if (_selectedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white54),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    _selectedImage!,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : ElevatedButton(
                    onPressed: _addDiaryEntry,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      // ignore: deprecated_member_use
                      backgroundColor: Colors.white.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.white70),
                      ),
                      textStyle: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Save Entry'),
                  ),
          ],
        ),
      ),
    );
  }
}
// --- END OF COMPLETE UPDATED AddEntryPage CLASS ---