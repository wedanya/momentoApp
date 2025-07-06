import 'package:flutter/material.dart';
import 'screens/wrapper.dart'; // Our Wrapper screen
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; // Used for custom fonts

void main() async {
  // Ensure Flutter widgets are initialized before Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase. Replace with your actual project URL and Anon Key.
  // DO NOT HARDCODE production keys in a real app, use environment variables.
  await Supabase.initialize(
    url: 'https://hcpkoadllzdwsfovivkz.supabase.co', // <<< Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjcGtvYWRsbHpkd3Nmb3Zpdmt6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2OTUwNTksImV4cCI6MjA2NzI3MTA1OX0.3HJO6J_Qew2i4FeBdRYpDnVAykx1vD0x3JUQnzhSxa4', // <<< Replace with your Supabase Anon Key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'momento',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Optional: Apply GoogleFonts as a default for the entire app's text theme
        // If you want all your text to default to Roboto from GoogleFonts, uncomment this:
        textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: Colors.white, // Default text color for body
              displayColor: Colors.white, // Default text color for headings
            ),
      ),
      home: const Wrapper(), // The Wrapper widget will handle authentication routing
      // You can define named routes here if you plan to use them for navigation
      // routes: {
      //   '/home': (context) => const DiaryListScreen(), // Define if you navigate directly
      //   '/auth': (context) => const AuthScreen(), // Define if you navigate directly
      // },
      debugShowCheckedModeBanner: false, // Set to false in production
    );
  }
}