import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'fleet_management_screen.dart';
import 'fee_management_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // This list manages which screen is shown
  late final List<Widget> _pages = [
    const MainDashboardView(),
    const FeeManagementScreen(),
    const FleetManagementScreen(),
    const Center(
      child: Text(
        "Route Planning Page",
        style: TextStyle(fontSize: 24, color: Colors.black),
      ),
    ),
    const Center(
      child: Text(
        "Notifications Page",
        style: TextStyle(fontSize: 24, color: Colors.black),
      ),
    ),
    const Center(
      child: Text(
        "Reports Page",
        style: TextStyle(fontSize: 24, color: Colors.black),
      ),
    ),
    const Center(
      child: Text(
        "Settings Page",
        style: TextStyle(fontSize: 24, color: Colors.black),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F6F8),
        primaryColor: const Color(0xFF195DE6),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF195DE6),
          brightness: Brightness.light,
        ),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F8),
        body: Row(
          children: [
            Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
            Expanded(
              child: Column(
                children: [
                  const Header(),
                  Expanded(
                    child: _pages[_selectedIndex],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- RESTORED: Main Dashboard Content ---
class MainDashboardView extends StatelessWidget {
  const MainDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          WelcomeSection(),
          SizedBox(height: 32),
          MetricsGrid(),
          SizedBox(height: 32),
          MiddleLayout(),
          SizedBox(height: 32),
          FleetTrackingOverview(),
        ],
      ),
    );
  }
}

// --- RESTORED: Header with Search Bar ---
class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                style: TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Search students, routes, or drivers...",
                  hintStyle: TextStyle(fontSize: 14, color: Colors.black54),
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.black),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.notifications_none, color: Colors.grey),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, size: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// --- RESTORED: Welcome Section ---
class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Welcome back, Admin",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          "Monday, 30 October 2023 | System overview is looking good.",
          style: TextStyle(color: const Color(0xFF64748B), fontSize: 14),
        ),
      ],
    );
  }
}

// --- RESTORED: Metrics Grid ---
class MetricsGrid extends StatelessWidget {
  const MetricsGrid({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2,
      children: const [
        MetricCard(
          title: "ACTIVE BUSES",
          value: "42",
          icon: Icons.directions_bus,
        ),
        MetricCard(
          title: "TOTAL STUDENTS",
          value: "1,250",
          icon: Icons.group,
        ),
        MetricCard(
          title: "PENDING FEES",
          value: "\$12k",
          icon: Icons.warning,
          color: Colors.red,
        ),
        MetricCard(
          title: "TRIPS TODAY",
          value: "84",
          icon: Icons.route,
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color? color;
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? const Color(0xFF195DE6), size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// --- RESTORED: Middle Layout (Routes) ---
class MiddleLayout extends StatelessWidget {
  const MiddleLayout({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Live Fleet Status",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _statusRow("Route 01: Downtown Express", 0.78),
          _statusRow("Route 12: West Side Residential", 0.92),
        ],
      ),
    );
  }

  Widget _statusRow(String label, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            color: const Color(0xFF195DE6),
            backgroundColor: const Color(0xFFF1F5F9),
          ),
        ],
      ),
    );
  }
}

// --- RESTORED: Map Overview ---
class FleetTrackingOverview extends StatelessWidget {
  const FleetTrackingOverview({super.key});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 300,
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(9.5107, 76.5511),
            initialZoom: 15,
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            const MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(9.5107, 76.5511),
                  child: Icon(
                    Icons.directions_bus,
                    color: Color(0xFF195DE6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Sidebar Navigation ---
class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          _logoHeader(),
          const SizedBox(height: 32),
          _navItem(Icons.dashboard, "Dashboard", 0),
          _navItem(Icons.payments_outlined, "Fees & Payments", 1),
          _navItem(Icons.commute_outlined, "Fleet Management", 2),
          _navItem(Icons.map_outlined, "Route Planning", 3),
          _navItem(Icons.notifications_none, "Notifications", 4),
          _navItem(Icons.analytics_outlined, "Reports", 5),
          const Spacer(),
          _navItem(Icons.settings_outlined, "Settings", 6),
        ],
      ),
    );
  }

  Widget _logoHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Icon(Icons.directions_bus, color: Color(0xFF195DE6), size: 32),
          const SizedBox(width: 12),
          const Text(
            "BusAdmin Pro",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF195DE6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(icon, color: isActive ? Colors.white : Colors.black87),
          title: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
