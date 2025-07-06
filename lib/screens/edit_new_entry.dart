// lib/screens/edit_entry_screen.dart
import 'dart:io';
import 'dart:typed_data'; // ⬅️ Import for Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/diary_entry.dart';
import '../services/diary_service_supabase.dart';
import '../services/image_storage_service.dart';

class EditNewEntry extends StatefulWidget {
  final DiaryEntry entry;

  const EditNewEntry({super.key, required this.entry});

  @override
  // ignore: library_private_types_in_public_api
  _EditNewEntryState createState() => _EditNewEntryState();
}

class _EditNewEntryState extends State<EditNewEntry> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  final DiaryServiceSupabase _diaryService = DiaryServiceSupabase();
  final ImageStorageService _imageStorageService = ImageStorageService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile; // Still used for uploading (File expected by storage service)
  Uint8List? _newPickedImageBytes; // ⬅️ NEW: To store bytes for web preview
  String? _currentImageUrl;

  bool _isImageChanged = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _contentController = TextEditingController(text: widget.entry.content);
    _currentImageUrl = widget.entry.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (kIsWeb) {
      _newPickedImageBytes = await picked.readAsBytes();
      _imageFile = null; // ✅ don’t use File on web
    } else {
      _imageFile = File(picked.path);
      _newPickedImageBytes = null;
    }
    _isImageChanged = true;
    _currentImageUrl = null;
    setState(() {});
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _newPickedImageBytes = null; // ⬅️ Clear bytes too
      _currentImageUrl = null;
      _isImageChanged = true;
    });
  }

  void _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not authenticated. Cannot save entry.')),
      );
      return;
    }

    String? finalImageUrl = _currentImageUrl;

    if (_isImageChanged) {
      if (widget.entry.imageUrl != null && widget.entry.imageUrl!.isNotEmpty) {
        try {
          await _imageStorageService.deleteImageByUrl(widget.entry.imageUrl!);
          if (!mounted) return;
        } catch (e) {
          debugPrint('Error deleting old image: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Warning: Failed to delete old image. ${e.toString()}')),
          );
        }
      }

      if (_imageFile != null) {
        try {
          finalImageUrl = await _imageStorageService.uploadDiaryImage(_imageFile!, currentUserId);
          if (!mounted) return;
        } catch (e) {
          debugPrint('Error uploading new image: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload new image: ${e.toString()}')),
          );
          return;
        }
      } else {
        finalImageUrl = null;
      }
    }

    DiaryEntry updatedEntry = DiaryEntry(
      id: widget.entry.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      date: widget.entry.date,
      imageUrl: finalImageUrl,
    );

    try {
      await _diaryService.updateEntry(updatedEntry);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error updating entry in Supabase: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update entry: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Entry"),
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
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: _newPickedImageBytes != null // ⬅️ Check for bytes first
                      ? Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.memory( // ⬅️ Use Image.memory for newly picked images
                              _newPickedImageBytes!,
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
                      : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                          ? Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Image.network(
                                  _currentImageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
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
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value!.isEmpty ? 'Title cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
                maxLines: null,
                minLines: 5,
                keyboardType: TextInputType.multiline,
                validator: (value) => value!.isEmpty ? 'Content cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveEntry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}