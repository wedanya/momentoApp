// lib/screens/edit_diary_entry.dart

import 'dart:io';
import 'dart:typed_data'; // For Uint8List

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // <--- NEW: For kIsWeb
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Make sure uuid is in your pubspec.yaml

import '../widgets/liquid_background.dart';

class EditEntryPage extends StatefulWidget {
  final String entryId;
  final String initialContent;
  final String? initialImageUrl;

  const EditEntryPage({
    super.key,
    required this.entryId,
    required this.initialContent,
    this.initialImageUrl,
  });

  @override
  State<EditEntryPage> createState() => _EditEntryPageState();
}

class _EditEntryPageState extends State<EditEntryPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _contentController;
  File? _imageFile; // For mobile/desktop
  Uint8List? _imageBytes; // <--- NEW: For web image data
  String? _currentImageUrl;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.initialContent);
    _currentImageUrl = widget.initialImageUrl;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        if (kIsWeb) {
          // For web, read as bytes
          pickedFile.readAsBytes().then((bytes) {
            setState(() {
              _imageBytes = bytes;
              _imageFile = null; // Clear file for web
              _currentImageUrl = null; // Clear existing image
            });
          });
        } else {
          // For mobile/desktop, use File
          _imageFile = File(pickedFile.path);
          _imageBytes = null; // Clear bytes for mobile/desktop
          _currentImageUrl = null; // Clear existing image
        }
      }
    });
  }

  Future<void> _removeImage() async {
    setState(() {
      _imageFile = null;
      _imageBytes = null; // Clear image bytes too
      _currentImageUrl = null; // Also clear the URL
    });
  }

  Future<String?> _uploadImage() async {
    // If no new image picked and no current image exists, nothing to upload/keep
    if (_imageFile == null && _imageBytes == null && _currentImageUrl == null) {
      return null; // Explicitly return null if no image should be associated
    }

    // If no new image picked but a current image exists, keep the current URL
    if (_imageFile == null && _imageBytes == null && _currentImageUrl != null) {
      return _currentImageUrl;
    }

    try {
      final String fileName = '${const Uuid().v4()}.jpg';
      final String publicUrl;

      if (kIsWeb && _imageBytes != null) {
        // For web, upload Uint8List (bytes)
        await supabase.storage
            .from('images') // <--- Corrected: Using 'images' as per recent discussion/screenshots
            .uploadBinary(fileName, _imageBytes!, fileOptions: const FileOptions(cacheControl: '3600', upsert: false));
        publicUrl = supabase.storage.from('images').getPublicUrl(fileName); // <--- Corrected: Using 'images'
      } else if (_imageFile != null) {
        // For mobile/desktop, upload File
        await supabase.storage
            .from('images') // <--- Corrected: Using 'images' as per recent discussion/screenshots
            .upload(fileName, _imageFile!, fileOptions: const FileOptions(cacheControl: '3600', upsert: false));
        publicUrl = supabase.storage.from('images').getPublicUrl(fileName); // <--- Corrected: Using 'images'
      } else {
        // Should ideally not be reached if previous checks are correct
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No image data to upload.')),
          );
        }
        return null;
      }

      return publicUrl;
    } on StorageException catch (e) {
      if (e.statusCode == '409') {
        // Conflict, file might already exist, get its public URL
        // This part needs careful thought if the filename logic is based on local path or uuid
        // For UUID, 409 should be rare unless same UUID is generated (highly unlikely)
        // If you were reusing filenames, this would be more relevant.
        // For now, assuming new UUID for each upload, 409 indicates a real issue or very rare collision.
        // Re-attempting to get public URL for a UUID-based file if 409 means it was uploaded by another process
        // or a previous attempt succeeded without returning URL. For simplicity, just error out.
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: ${e.message}')),
        );
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: ${e.toString()}')),
        );
      }
      return null;
    }
  }

  Future<void> _updateEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? finalImageUrl;
    // Handle image upload or retention
    finalImageUrl = await _uploadImage();
    if (finalImageUrl == null && (_imageFile != null || _imageBytes != null)) {
      // If upload was attempted (new image was picked) but failed, stop here.
      // If no new image was picked, but there was an old URL which became null
      // (meaning _removeImage was pressed), that's fine.
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in to update an entry.')),
          );
          Navigator.of(context).pop(false); // <--- Added: Pop with false if user is not logged in
        }
        return;
      }

      final DateTime now = DateTime.now();

      await supabase.from('new_diary').update({
        'content': _contentController.text,
        'image_url': finalImageUrl, // This will be null if image was removed or upload failed
        'created_at': now.toIso8601String(), // Update timestamp to now (or keep original if preferred)
      }).eq('id', widget.entryId); // <--- Use the entry ID for WHERE clause

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry updated successfully!')),
        );
        Navigator.of(context).pop(true); // <--- Corrected: Pop with true on success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update entry: ${e.toString()}')),
        );
      }
      Navigator.of(context).pop(false); // <--- Corrected: Pop with false on error
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Edit Entry', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: LiquidBackground(
        child: Stack( // Use Stack to put an overlay
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _contentController,
                      maxLines: 10,
                      minLines: 5,
                      style: GoogleFonts.roboto(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Your thoughts...',
                        labelStyle: GoogleFonts.roboto(color: Colors.white70),
                        hintStyle: GoogleFonts.roboto(color: Colors.white54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter some content';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Conditional display for images (newly picked or existing)
                    if (_imageFile != null) // For mobile/desktop picked image
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _imageFile!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                            label: Text('Remove new image', style: GoogleFonts.roboto(color: Colors.redAccent)),
                          ),
                        ],
                      )
                    else if (_imageBytes != null) // <--- NEW: For web picked image
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _imageBytes!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                            label: Text('Remove new image', style: GoogleFonts.roboto(color: Colors.redAccent)),
                          ),
                        ],
                      )
                    else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) // Existing image from network
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _currentImageUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 200,
                                color: Colors.grey.withOpacity(0.2),
                                child: const Center(
                                  child: Icon(Icons.broken_image, color: Colors.white70, size: 50),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                            label: Text('Remove current image', style: GoogleFonts.roboto(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library, color: Colors.white),
                      label: Text(
                        _imageFile != null || _imageBytes != null || (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                            ? 'Change Image'
                            : 'Add Image',
                        style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _updateEntry,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Updating...' : 'Save Changes',
                        style: GoogleFonts.roboto(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withOpacity(0.7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
             // Overlay for darker background (as requested previously)
            Positioned.fill(
              child: IgnorePointer( // This makes the overlay non-interactive
                child: Container(
                  color: Colors.black.withOpacity(0.1), // Adjust this opacity for desired darkness
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}