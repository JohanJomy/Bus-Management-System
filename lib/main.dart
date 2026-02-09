import 'package:flutter/material.dart';

// Import all your screen files here
// Make sure these filenames match what you saved in your lib folder
import 'student/home_screen.dart';
import 'login.dart';
import 'student/student_login.dart';
import 'student/live_tracking_screen.dart';
import 'student/fee_payment_screen.dart';
import 'student/restricted_screen.dart';
import 'student/profile_screen.dart';
import 'driver/dashboard.dart';
import 'driver/driver_login.dart';

void main() {
  runApp(const BusApp());
}

class BusApp extends StatelessWidget {
  const BusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stitch Bus App',
      debugShowCheckedModeBanner: false,
      
      // 1. Theme Configuration
      themeMode: ThemeMode.system, // Automatically switches based on phone settings

      // Light Theme
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate-50
        primaryColor: const Color(0xFF137FEC), // Your Primary Blue
        fontFamily: 'Inter', // Ensure you have added this font to pubspec.yaml
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF137FEC),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate-900
        primaryColor: const Color(0xFF137FEC),
        fontFamily: 'Inter',
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF137FEC),
          surface: const Color(0xFF1E293B), // Slate-800
          brightness: Brightness.dark,
        ),
      ),

      // 2. Navigation Routes
      initialRoute: '/',
      routes: {
        '/': (context) => const RoleSelectionScreen(),
        '/student/login': (context) => const StudentLoginScreen(),
        '/home': (context) => const StudentHomeScreen(),
        '/tracking': (context) => const LiveTrackingScreen(),
        '/fees': (context) => const FeePaymentScreen(),
        '/restricted': (context) => const RestrictedScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/driver': (context) => const DriverDashboard(),
        '/driver/login': (context) => const DriverLoginScreen(),
      },
    );
  }
}