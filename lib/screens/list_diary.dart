// lib/screens/list_diary.dart

import 'package:flutter/material.dart';
import 'package:momento/screens/diary_entry_details_page.dart';
import 'package:momento/screens/settings_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:momento/screens/add_new_entry.dart';
import 'package:momento/models/diary_entry.dart'; // Import DiaryEntry model

import '../widgets/liquid_background.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => DiaryListScreenState();
}

class DiaryContentPage extends StatefulWidget {
  const DiaryContentPage({super.key});

  @override
  State<DiaryContentPage> createState() => _DiaryContentPageState();
}

class _DiaryContentPageState extends State<DiaryContentPage> {
  late final Stream<List<Map<String, dynamic>>> _diaryEntriesStream;
  List<DiaryEntry> _currentEntries = []; // To hold and modify local list

  @override
  void initState() {
    super.initState();
    _diaryEntriesStream = Supabase.instance.client
        .from('new_diary')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    // Listen to the stream and update _currentEntries
    _diaryEntriesStream.listen((data) {
      setState(() {
        _currentEntries = data.map((map) => DiaryEntry.fromMap(map)).toList();
      });
    });
  }

  Future<void> _deleteEntryPermanently(String entryId) async {
    try {
      await Supabase.instance.client.from('new_diary').delete().eq('id', entryId);
      if (mounted) {
        // No need for a snackbar here, as the dismissible/undo flow handles feedback
        debugPrint('Entry $entryId permanently deleted from Supabase.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete entry: ${e.toString()}')),
        );
      }
      debugPrint('Error permanently deleting entry $entryId: $e');
    }
  }

  void _onDismissed(int index, DismissDirection direction) {
    final DiaryEntry dismissedEntry = _currentEntries[index];
    final int dismissedIndex = index; // Store original index

    // Optimistically remove from the local list
    setState(() {
      _currentEntries.removeAt(dismissedIndex);
    });

    ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remove any previous snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${dismissedEntry.content.length > 20 ? dismissedEntry.content.substring(0, 20) + '...' : dismissedEntry.content}" deleted.'),
        duration: const Duration(seconds: 5), // SnackBar visible for 5 seconds
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.blueAccent, // Customize undo button color
          onPressed: () {
            // Re-insert the item back into the list at its original position
            setState(() {
              _currentEntries.insert(dismissedIndex, dismissedEntry);
            });
            ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide the undo snackbar
          },
        ),
      ),
    ).closed.then((reason) {
      // This callback is called when the SnackBar is closed (either by user, timeout, or action)
      if (reason != SnackBarClosedReason.action) {
        // If the snackbar was not dismissed by the "Undo" action,
        // then permanently delete the entry from Supabase.
        _deleteEntryPermanently(dismissedEntry.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LiquidBackground( // LiquidBackground covers the whole content area
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _diaryEntriesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading entries: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No entries yet. Start writing!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(fontSize: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AddEntryPage()),
                      );
                    },
                    icon: const Icon(Icons.add_box, color: Colors.white),
                    label: Text(
                      'Add Your First Entry',
                      style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Use _currentEntries directly which is updated by the stream listener
          if (_currentEntries.isEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No entries yet. Start writing!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(fontSize: 24, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AddEntryPage()),
                      );
                    },
                    icon: const Icon(Icons.add_box, color: Colors.white),
                    label: Text(
                      'Add Your First Entry',
                      style: GoogleFonts.roboto(fontSize: 16, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }


          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _currentEntries.length,
            itemBuilder: (context, index) {
              final DiaryEntry entry = _currentEntries[index];

              return Dismissible(
                key: ValueKey<String>(entry.id), // Unique key for each Dismissible
                direction: DismissDirection.endToStart, // Only allow swipe from right to left
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  color: Colors.red, // Background color when swiping
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) => _onDismissed(index, direction),
                child: Card(
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white30),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    title: Text(
                      entry.content.length > 50 ? '${entry.content.substring(0, 50)}...' : entry.content,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              entry.imageUrl!,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 100,
                                color: Colors.grey.withOpacity(0.2),
                                child: const Center(
                                  child: Icon(Icons.broken_image, color: Colors.white70),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${entry.date.day}/${entry.date.month}/${entry.date.year} ${entry.date.hour}:${entry.date.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DiaryEntryDetailsPage(
                            entryId: entry.id, // <--- NEW: Pass the entry ID
                            initialContent: entry.content, // <--- CHANGED: Renamed to initialContent
                            initialImageUrl: entry.imageUrl,
                            initialCreatedAt: entry.date, // <--- CHANGED: Renamed to initialCreatedAt (if that's what you decided, check your DiaryEntryDetailsPage)
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DiaryListScreenState extends State<DiaryListScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    Navigator(
      key: const PageStorageKey('DiaryTabNavigator'),
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const DiaryContentPage(),
        );
      },
    ),
    Navigator(
      key: const PageStorageKey('AddTabNavigator'),
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const AddEntryPage(),
        );
      },
    ),
    Navigator(
      key: const PageStorageKey('SettingsTabNavigator'),
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const SettingsPage(),
        );
      },
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('momento', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Supabase.instance.client.auth.signOut();
              // After logout, navigate to the authentication wrapper
              Navigator.of(context).pushNamedAndRemoveUntil('/wrapper', (route) => false);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: LiquidBackground(
        child: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      bottomNavigationBar: Stack(
        children: [
          Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xAA1A2A6C),
                  Color(0xAA7B0000),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.book),
                label: 'Diary',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_box),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            onTap: _onItemTapped,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
          ),
        ],
      ),
    );
  }
}