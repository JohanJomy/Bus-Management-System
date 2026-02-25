import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'routes_screen.dart';
import 'students_screen.dart';
import 'settings_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _currentIndex = 0;

  late final List<Widget> _pages = <Widget>[
    const DriverHomeScreen(),
    const DriverRoutesScreen(),
    const DriverStudentsScreen(),
    const DriverSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F6F8);
    final Color textSec =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: bgColor,
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSec,
        showUnselectedLabels: true,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alt_route),
            label: 'Routes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
