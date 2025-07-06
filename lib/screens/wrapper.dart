import 'package:flutter/material.dart';
import 'package:momento/screens/list_diary.dart';
import 'package:momento/screens/login.dart'; // AuthScreen lives here
import 'package:supabase_flutter/supabase_flutter.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Auth Stream Error: ${snapshot.error}');
          return const Scaffold(
            body: Center(child: Text('Error connecting to authentication service.')),
          );
        }

        final session = snapshot.data?.session;
        return session != null ? const DiaryListScreen() : const AuthScreen();
      },
    );
  }
}