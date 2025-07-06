import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/liquid_background.dart'; // Your custom background widget
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts here

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true; // True for login, false for register
  String? _errorMessage; // To display login/registration errors

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuthForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop if form is not valid
    }

    setState(() {
      _errorMessage = null; // Clear previous errors
    });

    try {
      if (_isLoginMode) {
        // Login
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // On successful login, the StreamBuilder in Wrapper will automatically navigate
      } else {
        // Register
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          // You might add user metadata here:
          // options: AuthOptions(data: {'full_name': 'New User'}),
        );
        // After registration, typically you'd prompt for email verification
        // The StreamBuilder will pick up the new auth state (unverified user)
        if (context.mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please check your email for verification if required.')),
          );
          setState(() {
            _isLoginMode = true; // Switch back to login mode after registration
            _emailController.clear();
            _passwordController.clear();
          });
        }
      }
    } on AuthException catch (e) {
      debugPrint('Auth Error: ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      debugPrint('General Error: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allow background to go under app bar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make app bar transparent
        elevation: 0, // Remove shadow
      ),
      // Use the LiquidBackground as the body
      body: LiquidBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // --- "Momento" Text Title with Google Fonts ---
                  Text( // Removed 'const' because GoogleFonts.xxx() is not a const constructor
                    'momento',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rowdies( // <<< CHANGED TO GoogleFonts.rowdies
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2.0,
                      shadows: const [ // Shadows themselves can still be const
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black45,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40), // Space between title and input fields

                  // --- Email Input Field ---
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: GoogleFonts.roboto(color: Colors.white70), // Google Font for label
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      prefixIcon: const Icon(Icons.email, color: Colors.white70),
                      // ignore: deprecated_member_use
                      fillColor: Colors.white.withOpacity(0.1),
                      filled: true,
                    ),
                    style: GoogleFonts.roboto(color: Colors.white, fontSize: 16), // Google Font for input text
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- Password Input Field ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: GoogleFonts.roboto(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      // ignore: deprecated_member_use
                      fillColor: Colors.white.withOpacity(0.1),
                      filled: true,
                    ),
                    style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 6) {
                        return 'Password must be at least 6 characters long.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ... (Your existing code in lib/screens/login.dart)

                // --- Error Message Display ---
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      _errorMessage!,
                      // CORRECTED LINE BELOW:
                      style: GoogleFonts.roboto(
                        color: Colors.orangeAccent, // This is a NAMED argument
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // --- Submit Button (Login/Register) ---
                  ElevatedButton(
                    onPressed: _submitAuthForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      // ignore: deprecated_member_use
                      backgroundColor: Colors.white.withOpacity(0.3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.white70),
                      ),
                      textStyle: GoogleFonts.roboto( // Google Font for button text
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Text(_isLoginMode ? 'Login' : 'Register'),
                  ),
                  const SizedBox(height: 10),

                  // --- Toggle Login/Register Mode ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        _isLoginMode ? 'First time user?' : 'Already have an account?',
                        style: GoogleFonts.roboto(
                          color: Colors.white70,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLoginMode = !_isLoginMode;
                            _formKey.currentState?.reset();
                            _emailController.clear();
                            _passwordController.clear();
                            _errorMessage = null;
                          });
                        },
                        child: Text(
                          _isLoginMode ? 'Register now' : 'Login now',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}