// lib/screens/diary_entry_details_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <--- NEW: Import Supabase
import 'package:momento/models/diary_entry.dart'; // <--- Make sure you have this model
import '../widgets/liquid_background.dart';
import 'package:momento/screens/edit_diary_entry.dart';

class DiaryEntryDetailsPage extends StatefulWidget {
  final String entryId; // We now only strictly need the ID to refetch
  final String initialContent; // Kept for initial display
  final String? initialImageUrl; // Kept for initial display
  final DateTime? initialCreatedAt; // Kept for initial display

  const DiaryEntryDetailsPage({
    super.key,
    required this.entryId,
    required this.initialContent,
    this.initialImageUrl,
    this.initialCreatedAt,
  });

  @override
  State<DiaryEntryDetailsPage> createState() => _DiaryEntryDetailsPageState();
}

class _DiaryEntryDetailsPageState extends State<DiaryEntryDetailsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  DiaryEntry? _currentEntry; // <--- Store the current entry data

  @override
  void initState() {
    super.initState();
    // Initialize with passed data, then try to fetch for freshness
    _currentEntry = DiaryEntry(
      id: widget.entryId,
      content: widget.initialContent,
      imageUrl: widget.initialImageUrl,
      date: widget.initialCreatedAt ?? DateTime.now(), // Use initial or default
      userId: supabase.auth.currentUser?.id ?? '', // Assuming userId is part of your model
    );
    _fetchEntryDetails(); // Fetch the latest details on init
  }

  Future<void> _fetchEntryDetails() async {
    try {
      final response = await supabase
          .from('new_diary')
          .select()
          .eq('id', widget.entryId)
          .single(); // Use single() to get a single row

      if (response != null) {
        setState(() {
          _currentEntry = DiaryEntry.fromMap(response); // Assuming fromMap constructor
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load entry details: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator or initial content if data is not yet loaded
    if (_currentEntry == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: const LiquidBackground(
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Diary Entry', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              // Push the EditEntryPage and wait for a result
              final bool? updated = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EditEntryPage(
                    entryId: _currentEntry!.id,
                    initialContent: _currentEntry!.content,
                    initialImageUrl: _currentEntry!.imageUrl,
                  ),
                ),
              );

              // If an update occurred, refetch the details
              if (updated == true) {
                _fetchEntryDetails();
              }
            },
            tooltip: 'Edit Entry',
          ),
        ],
      ),
      body: LiquidBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Entry Details',
                style: GoogleFonts.roboto(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              if (_currentEntry!.date != null) ...[
                Text(
                  'Date: ${_currentEntry!.date.day}/${_currentEntry!.date.month}/${_currentEntry!.date.year} ${_currentEntry!.date.hour}:${_currentEntry!.date.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
              ],

              if (_currentEntry!.imageUrl != null && _currentEntry!.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _currentEntry!.imageUrl!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 250,
                      color: Colors.grey.withOpacity(0.2),
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.white70),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Container(
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white54),
                ),
                child: Text(
                  _currentEntry!.content,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    color: Colors.white,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}