import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import your AuthScreen (login page)
import 'package:momento/screens/login.dart'; // Assuming this is where AuthScreen is defined

// Import your DiaryListScreen (the main app content after login)
// IMPORTANT: Adjust this path and filename if your DiaryListScreen is in a different file.
// For example, if it's in a file called 'diary_list.dart', the import would be:
// import 'package:momento/screens/diary_list.dart';
import 'package:momento/screens/list_diary.dart'; // Assuming DiaryListScreen is in list_diary.dart

// No need for GoogleFonts here, as it's typically used in the widget it modifies.
// But you can import it if you plan to use it for widgets within this file.

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder listens to authentication state changes from Supabase
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show a loading indicator while we wait for the initial auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Handle potential errors from the authentication stream
        if (snapshot.hasError) {
          debugPrint('Auth Stream Error: ${snapshot.error}');
          return const Scaffold(
            body: Center(child: Text('Error connecting to authentication service.')),
          );
        }

        // Get the current session. A non-null session means a user is logged in.
        final Session? session = snapshot.data?.session;

        if (session != null) {
          // User is authenticated, show the main application screen
          return const DiaryListScreen();
        } else {
          // User is not authenticated, show the login/registration screen
          return const AuthScreen();
        }
      },
    );
  }
}