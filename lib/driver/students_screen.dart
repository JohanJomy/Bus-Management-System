import 'package:flutter/material.dart';

class DriverStudentsScreen extends StatelessWidget {
  const DriverStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
      ),
      body: const Center(
        child: Text(
          'Students screen (to be implemented)',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
