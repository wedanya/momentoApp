// lib/screens/add_new_entry.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb

import 'dart:io'; // Required for File
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // Required for Uint8List

import '../widgets/liquid_background.dart';
import '../models/diary_entry.dart'; // Import the DiaryEntry model

class AddEntryPage extends StatefulWidget {
  const AddEntryPage({super.key});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _selectedImageBytes; // For web preview and web upload
  File? _selectedImageFile; // For mobile/desktop file operations and upload
  final ImagePicker _picker = ImagePicker(); // ImagePicker instance

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

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
          _selectedImageBytes = null; // Clear previous bytes
          _selectedImageFile = null; // Clear previous file

          if (kIsWeb) {
            pickedFile.readAsBytes().then((bytes) {
              setState(() {
                _selectedImageBytes = bytes;
              });
            });
          } else {
            _selectedImageFile = File(pickedFile.path);
          }
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

  Future<String?> _uploadImage() async {
    if (_selectedImageFile == null && _selectedImageBytes == null) {
      return null; // No image selected
    }

    final String userId = Supabase.instance.client.auth.currentUser!.id;
    final String fileName = '$userId/${DateTime.now().microsecondsSinceEpoch}.png';

    try {
      if (_selectedImageFile != null) { // If running on mobile/desktop (File is available)
        final String publicUrl = await Supabase.instance.client.storage
            .from('images') // Corrected bucket name
            .upload(fileName, _selectedImageFile!,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ));
        return Supabase.instance.client.storage.from('images').getPublicUrl(fileName); // Get public URL
      } else if (_selectedImageBytes != null) { // If running on web (bytes are available)
        final String publicUrl = await Supabase.instance.client.storage
            .from('images') // Corrected bucket name
            .uploadBinary(fileName, _selectedImageBytes!,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ));
        return Supabase.instance.client.storage.from('images').getPublicUrl(fileName); // Get public URL
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
        );
      }
      return null;
    }
  }

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
    if (_selectedImageFile != null || _selectedImageBytes != null) {
      imageUrl = await _uploadImage();
      if (imageUrl == null) {
        setState(() { _isLoading = false; });
        return;
      }
    }

    try {
      // You were creating a DiaryEntry object that required 'date'.
      // Although Supabase handles 'created_at', if you use DiaryEntry locally,
      // it needs all its required parameters.
      // We will now create the map for Supabase directly,
      // as the DiaryEntry model is mostly for fetching/displaying.
      // If you intended to use the DiaryEntry object for more complex local logic,
      // you would instantiate it like:
      // final newEntry = DiaryEntry(
      //   id: '', // Supabase generates this, so can be empty for new
      //   content: _contentController.text.trim(),
      //   imageUrl: imageUrl,
      //   userId: currentUser.id,
      //   date: DateTime.now(), // Provided as per error
      // );


      // Ensure 'new_diary' is your correct Supabase database table name
      await Supabase.instance.client.from('new_diary').insert({
        'content': _contentController.text.trim(),
        'user_id': currentUser.id,
        'image_url': imageUrl, // Include the image URL here (can be null if no image)
        // 'created_at' is typically handled by a default value in your Supabase table schema
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diary entry added successfully!')),
        );
        _contentController.clear();
        setState(() {
          _selectedImageBytes = null;
          _selectedImageFile = null;
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

            ElevatedButton.icon(
              icon: const Icon(Icons.image, color: Colors.white),
              label: Text(
                (_selectedImageFile == null && _selectedImageBytes == null) ? 'Pick Image' : 'Change Image',
                style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
              ),
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // --- Image Preview (Platform-aware) ---
            if (_selectedImageFile != null || _selectedImageBytes != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white54),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: kIsWeb && _selectedImageBytes != null
                      ? Image.memory(
                          _selectedImageBytes!,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : _selectedImageFile != null
                          ? Image.file(
                              _selectedImageFile!,
                              height: 200,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox.shrink(),
                ),
              ),

            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : ElevatedButton(
                    onPressed: _addDiaryEntry,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
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