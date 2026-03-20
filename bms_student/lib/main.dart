import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'student/student_login.dart';
import 'student/home_screen.dart';
import 'student/live_tracking_screen.dart';
import 'student/fee_payment_screen.dart';
import 'student/restricted_screen.dart';
import 'student/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      // Continue anyway as Firebase might already be initialized natively
    }
  }
  
  await Supabase.initialize(
    url: 'https://lnssskyfwshwextaecdx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxuc3Nza3lmd3Nod2V4dGFlY2R4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MDkwNTksImV4cCI6MjA4ODE4NTA1OX0.80dphTCVyBmPCQW-taGVfXuERaOu06R1mlFMZ80FjeM',
  );

  runApp(const StudentApp());
}

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus Student',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F6F8),
        primaryColor: const Color(0xFF137FEC),
        fontFamily: 'Inter',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF137FEC),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF137FEC),
        fontFamily: 'Inter',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF137FEC),
          surface: const Color(0xFF1E293B),
          brightness: Brightness.dark,
        ),
      ),
      initialRoute: '/student/login',
      routes: {
        '/student/login': (context) => const StudentLoginScreen(),
        '/home': (context) => const StudentHomeScreen(),
        '/tracking': (context) => const LiveTrackingScreen(),
        '/fees': (context) => const FeePaymentScreen(),
        '/restricted': (context) => const RestrictedScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
