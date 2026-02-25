import 'package:flutter/material.dart';
import 'admin/admin_login.dart';

void main() {
  runApp(const BusAdminApp());
}

class BusAdminApp extends StatelessWidget {
  const BusAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bus Admin',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF195DE6),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F6F8),
      ),
      home: const AdminLoginScreen(),
    );
  }
}
