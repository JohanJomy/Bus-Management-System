import 'package:flutter/material.dart';

class DriverRoutesScreen extends StatelessWidget {
  const DriverRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes'),
      ),
      body: const Center(
        child: Text(
          'Routes screen (to be implemented)',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
