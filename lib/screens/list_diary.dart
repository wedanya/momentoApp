import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// You might also want to import GoogleFonts here if you use them in this screen
// import 'package:google_fonts/google_fonts.dart';

// Import your LiquidBackground if you want it on this screen too
import 'package:momento/widgets/liquid_background.dart';

// --- Placeholder Widgets for Navigation Tabs ---
// In a real app, these would be separate, more complex screens/widgets.
class DiaryContentPage extends StatelessWidget {
  const DiaryContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Your Diary Entries Here!',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}

class AddEntryPage extends StatelessWidget {
  const AddEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Add New Diary Entry Form',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'App Settings and Options',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}
// --- End Placeholder Widgets ---


class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  // Current selected index for the bottom navigation bar
  int _selectedIndex = 0;

  // List of widgets (pages) to display for each tab
  // You would replace these placeholder widgets with your actual screens.
  static const List<Widget> _widgetOptions = <Widget>[
    DiaryContentPage(), // Your main diary list content
    AddEntryPage(),     // A page to add new entries
    SettingsPage(),     // A settings page
  ];

  // Function to handle tab taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to handle logout
  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      // Supabase's onAuthStateChange stream in Wrapper will handle navigation
      // back to AuthScreen automatically after sign out.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully!')),
        );
      }
    } on AuthException catch (e) {
      debugPrint('Logout Error: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.message}')),
        );
      }
    } catch (e) {
      debugPrint('General Logout Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred during logout.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allow background to go under app bar
      appBar: AppBar(
        title: const Text('Momento Diary', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent, // Make app bar transparent
        elevation: 0, // Remove shadow
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      // Wrap the body content with LiquidBackground if you want the animation here too
      body: LiquidBackground( // Apply the liquid background
        child: Center(
          child: _widgetOptions.elementAt(_selectedIndex), // Display the selected tab's content
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Diary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box), // Or Icons.add_circle, Icons.create
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex, // The currently selected tab
        selectedItemColor: Colors.blueAccent, // Color for the selected icon/label
        unselectedItemColor: Colors.grey,     // Color for unselected icons/labels
        onTap: _onItemTapped, // Callback when a tab is tapped
        backgroundColor: Colors.black.withOpacity(0.5), // Transparent background for navigation bar
        type: BottomNavigationBarType.fixed, // Use fixed type for more than 3 items
      ),
    );
  }
}