import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'google_sign_in_stub.dart' if (dart.library.js_interop) 'google_sign_in_web.dart' as web_btn;

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final idController = TextEditingController();
  final passController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSubscription;
  
  // Client ID for Web and identifying the server for Android/iOS
  static const String _webClientId = '737200464124-pd1jrj61c96rp36vughpmtstv5chkjm7.apps.googleusercontent.com';
  
  // GoogleSignIn configuration
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingSession();
    });
    _setupAuthListener();
    _initGoogleSignIn();
  }
  
  Future<void> _initGoogleSignIn() async {
    // Initialize GoogleSignIn
    unawaited(_googleSignIn.initialize(
      clientId: kIsWeb ? _webClientId : null, 
      serverClientId: kIsWeb ? null : _webClientId, // Native uses webClientId as serverClientId
      // No scopes param in initialize for v7? Let me double-check.
    ).then((_) {
      _setupGoogleSignInListener();
      _googleSignIn.attemptLightweightAuthentication();
    }));
  }

  void _setupAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      // If we just signed in, and have an email, verify it.
      if (event == AuthChangeEvent.signedIn && session != null && session.user.email != null) {
        _verifyStudentEmail(session.user.email!);
      }
    });
  }
  
  void _setupGoogleSignInListener() {
    _googleAuthSubscription = _googleSignIn.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
           _handleGoogleSignInAuth(event.user);
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
           // Handle sign out if needed
        }
    });
  }

  Future<void> _checkExistingSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && session.user.email != null) {
      // Auto verify if session exists
      await _verifyStudentEmail(session.user.email!);
    }
  }

  Future<void> _handleGoogleSignInAuth(GoogleSignInAccount googleUser) async {
    // Only set loading if needed, avoid setting it false if verify clears it
    if (!_isLoading) {
      if (mounted) setState(() => _isLoading = true);
    }
    
    try {
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      // Fix for "requestedScopes cannot be null or empty" on Android
      // We must explicitly request at least one scope when asking for authorization tokens 
      // even if we only need the ID Token.
      final accessToken = (await googleUser.authorizationClient.authorizationForScopes(['email']))?.accessToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid Google Sign-In:'),
            backgroundColor: const Color.fromARGB(255, 19, 127, 236),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyStudentEmail(String email) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dynamic studentData = await Supabase.instance.client
          .from('students')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      if (!mounted) return;

      if (studentData != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Not registered
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          await Supabase.instance.client.auth.signOut();
          await _googleSignIn.signOut();
          
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Access Denied'),
                content: const Text('This Google account is not registered as a student.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void login() {
    // implementation for manual login if needed
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await _googleSignIn.authenticate();
    } catch (error) {
       debugPrint('Google Sign In Error: $error');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _googleAuthSubscription?.cancel();
    idController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tailwind Colors
    final bgColor = isDark ? const Color(0xFF101922) : const Color(0xFFF6F6F8);
    final cardColor = isDark ? const Color(0xFF192633) : Colors.white;
    final primaryColor = const Color(0xFF137FEC);
    final borderColor = isDark ? const Color(0xFF324D67) : const Color(0xFFE2E8F0);
    final iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final placeholderColor = isDark ? const Color(0xFF92ADC9) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 430),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: primaryColor,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Header
                  Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: textColor,
                      height: 1.1,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your credentials to access your student bus pass.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: subtitleColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Login Form
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username Input
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          "Username or Student ID",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Icon(Icons.person_outline, color: iconColor, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: idController,
                                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "e.g. 202400123",
                                  hintStyle: TextStyle(color: placeholderColor),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password Input
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          "Password",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Icon(Icons.lock_outline, color: iconColor, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: passController,
                                obscureText: !_isPasswordVisible,
                                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "••••••••",
                                  hintStyle: TextStyle(color: placeholderColor),
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: iconColor,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: borderColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "OR",
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Expanded(child: Container(height: 1, color: borderColor)),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Social Auth
                  kIsWeb
                  ? Center(
                      child: web_btn.renderGoogleButton(isDark: isDark),
                    )
                  : Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                "Continue with Google",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF334155),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Forgot Password
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),

                  // Home Indicator spacer if needed
                  const SizedBox(height: 16),
                  Container(
                    width: 128,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
