import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin/admin_login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lnssskyfwshwextaecdx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxuc3Nza3lmd3Nod2V4dGFlY2R4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2MDkwNTksImV4cCI6MjA4ODE4NTA1OX0.80dphTCVyBmPCQW-taGVfXuERaOu06R1mlFMZ80FjeM',
  );

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
