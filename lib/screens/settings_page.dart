// lib/screens/settings_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
//import 'package:package_info_plus/package_info_plus.dart'; // For app version <--- ADDED THIS LINE
import 'package:url_launcher/url_launcher.dart'; // For opening URLs

// Ensure this import path is correct for your LiquidBackground widget
import '../widgets/liquid_background.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true; // Default value for notifications
  //String _appVersion = 'Loading...'; // Default for app version

  @override
  void initState() {
    super.initState();
    _loadSettings();
    //_getAppVersion();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = value;
      prefs.setBool('notificationsEnabled', value);
    });
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notifications ${value ? 'enabled' : 'disabled'}')),
    );
  }

  //Future<void> _getAppVersion() async {
    // This line caused the error without the import
    //final packageInfo = await PackageInfoPlus.fromPlatform();
    //setState(() {
      //_appVersion = packageInfo.version;
    //});
  //}

  // --- Account Actions ---

  void _navigateToChangePassword() {
    // In a real app, you would navigate to a dedicated page:
    // Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChangePasswordPage()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change password feature coming soon!')),
    );
  }

  void _navigateToUpdateProfile() {
    // In a real app, you would navigate to a dedicated page:
    // Navigator.of(context).push(MaterialPageRoute(builder: (_) => UpdateProfilePage()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile update feature coming soon!')),
    );
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      // Navigate to the authentication wrapper after logout
      Navigator.of(context).pushNamedAndRemoveUntil('/wrapper', (route) => false);
    }
  }

  // --- About Actions ---

  Future<void> _launchURL(String urlString, String featureName) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $featureName.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Application Settings',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              // Account Section
              Text(
                'Account',
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Divider(color: Colors.white30),
              ListTile(
                title: Text(
                  'Change Password',
                  style: GoogleFonts.roboto(fontSize: 18, color: Colors.white),
                ),
                trailing: const Icon(Icons.lock, color: Colors.white),
                onTap: _navigateToChangePassword,
              ),
              const Divider(color: Colors.white30),
              ListTile(
                title: Text(
                  'Update Profile',
                  style: GoogleFonts.roboto(fontSize: 18, color: Colors.white),
                ),
                trailing: const Icon(Icons.person, color: Colors.white),
                onTap: _navigateToUpdateProfile,
              ),
              const Divider(color: Colors.white30),
              ListTile(
                title: Text(
                  'Logout',
                  style: GoogleFonts.roboto(fontSize: 18, color: Colors.white),
                ),
                trailing: const Icon(Icons.logout, color: Colors.white),
                onTap: _logout,
              ),
              const SizedBox(height: 30),

              // General Settings Section
              Text(
                'General',
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Divider(color: Colors.white30),
              ListTile(
                title: Text(
                  'Notifications',
                  style: GoogleFonts.roboto(fontSize: 18, color: Colors.white),
                ),
                trailing: Switch(
                  value: _notificationsEnabled, // Use the state variable
                  onChanged: _toggleNotifications, // Use the new function
                  activeColor: Colors.white,
                ),
                onTap: () {
                  // Tapping the list tile toggles the switch
                  _toggleNotifications(!_notificationsEnabled);
                },
              ),
              const Divider(color: Colors.white30),
              ListTile(
                title: Text(
                  'App Language',
                  style: GoogleFonts.roboto(fontSize: 18, color: Colors.white),
                ),
                trailing: const Icon(Icons.language, color: Colors.white),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language settings coming soon!')),
                  );
                  
                },
              ),
              const SizedBox(height: 30),

              // About Section
              Text(
                'About',
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Divider(color: Colors.white30),
              ListTile(
                title: Text(
                  'Privacy Policy',
                  style: GoogleFonts.roboto(fontSize: 18, color: Colors.white),
                ),
                trailing: const Icon(Icons.privacy_tip, color: Colors.white),
                onTap: () => _launchURL('https://your_website.com/privacy_policy', 'Privacy Policy'),
                // Replace 'https://your_website.com/privacy_policy' with your actual URL
              ),
              const Divider(color: Colors.white30),
              ListTile(
                title: Text(
                  'Terms of Service',
                  style: GoogleFonts.roboto(fontSize: 18, color: Colors.white),
                ),
                trailing: const Icon(Icons.description, color: Colors.white),
                onTap: () => _launchURL('https://your_website.com/terms_of_service', 'Terms of Service'),
                // Replace 'https://your_website.com/terms_of_service' with your actual URL
              ),
              const Divider(color: Colors.white30),
              //ListTile(
                //title: Text(
                  //'App Version',
                  //style: GoogleFonts.roboto(fontSize: 18, color: Colors.white),
                //),
                //trailing: Text(
                  //_appVersion, // Display the fetched app version
                  //style: GoogleFonts.roboto(fontSize: 16, color: Colors.white70),
                //),
                //onTap: () {
                  // No action needed for app version, or show a dialog with more info
                //},
              //),
              //const Divider(color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }
}