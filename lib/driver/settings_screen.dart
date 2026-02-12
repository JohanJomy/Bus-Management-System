import 'package:flutter/material.dart';

class DriverSettingsScreen extends StatelessWidget {
  const DriverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Text(
          'Settings screen (to be implemented)',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
