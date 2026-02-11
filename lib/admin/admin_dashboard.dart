import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart'; // Added as per your pubspec
import 'package:latlong2/latlong.dart';      // Added as per your pubspec

void main() {
  runApp(const BusAdminApp());
}

class BusAdminApp extends StatelessWidget {
  const BusAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF6F6F8),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Row(
        children: [
          Sidebar(),
          Expanded(
            child: Column(
              children: [
                Header(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WelcomeSection(),
                        SizedBox(height: 32),
                        MetricsGrid(),
                        SizedBox(height: 32),
                        MiddleLayout(),
                        SizedBox(height: 32),
                        FleetTrackingOverview(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF195DE6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_bus, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("BusAdmin Pro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,color: Colors.black)),
                    Text("MANAGEMENT", style: TextStyle(fontSize: 10, color: Color.fromARGB(255, 6, 0, 0), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 32),
          _navItem(Icons.dashboard, "Dashboard", isActive: true),
          _navItem(Icons.payments_outlined, "Fees & Payments"),
          _navItem(Icons.commute_outlined, "Fleet Management"),
          _navItem(Icons.map_outlined, "Route Planning"),
          _navItem(Icons.notifications_none, "Notifications", badge: "12"),
          _navItem(Icons.analytics_outlined, "Reports"),
          const Spacer(),
          const Divider(height: 1),
          _navItem(Icons.settings_outlined, "Settings"),
          const SizedBox(height: 8),
          const ListTile(
            leading: CircleAvatar(backgroundColor: Color(0xFFFEE2E2), child: Icon(Icons.person, color: Colors.orange)),
            title: Text("Sejith R Nath", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,color: Colors.black,)),
            subtitle: Text("System Admin", style: TextStyle(fontSize: 12,color: Colors.black,)),
          )
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {bool isActive = false, String? badge}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF195DE6) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: isActive ? Colors.white : const Color.fromARGB(255, 0, 0, 0)),
        title: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
        trailing: badge != null 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF195DE6).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(badge, style: const TextStyle(color: Color(0xFF195DE6), fontSize: 10, fontWeight: FontWeight.bold)),
            ) 
          : null,
      ),
    );
  }
}

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
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Search students, routes, or drivers...",
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF195DE6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {},
            label: const Icon(Icons.keyboard_arrow_down, size: 16),
            icon: const Text("Quick Actions"),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.notifications_none, color: Colors.grey),
          const SizedBox(width: 16),
          const Icon(Icons.help_outline, color: Colors.grey),
        ],
      ),
    );
  }
}

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Welcome back, Admin", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
            const SizedBox(width: 8),
            Text("Monday, 30 October 2023 | System overview is looking good today.", 
                 style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255), fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class MetricsGrid extends StatelessWidget {
  const MetricsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 5,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: const [
        MetricCard(title: "ACTIVE BUSES", value: "42", subtitle: "Operational today", icon: Icons.directions_bus, trend: "+95%"),
        MetricCard(title: "TOTAL STUDENTS", value: "1,250", subtitle: "Enrolled members", icon: Icons.group),
        MetricCard(title: "PENDING FEES", value: "\$12,400", subtitle: "High priority alert", icon: Icons.error, color: Colors.red, isUrgent: true),
        MetricCard(title: "ACTIVE DRIVERS", value: "38", subtitle: "Currently on duty", icon: Icons.badge),
        MetricCard(title: "TODAY'S TRIPS", value: "84", subtitle: "32 Completed", icon: Icons.route),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final String? trend;
  final Color? color;
  final bool isUrgent;

  const MetricCard({super.key, required this.title, required this.value, required this.subtitle, required this.icon, this.trend, this.color, this.isUrgent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUrgent ? Colors.red.shade100 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color ?? const Color(0xFF195DE6)),
              if (trend != null) Text(trend!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              if (isUrgent) const Text("URGENT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87)),
              Text(subtitle, style: TextStyle(fontSize: 10, color: isUrgent ? Colors.red : Colors.black87)),
            ],
          )
        ],
      ),
    );
  }
}

class MiddleLayout extends StatelessWidget {
  const MiddleLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Live Fleet Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.black,)),
                const Text("Occupancy % by Main Routes", style: TextStyle(fontSize: 14, color: Color.fromARGB(255, 0, 0, 0))),
                const SizedBox(height: 24),
                _statusRow("Route 01: Downtown Express", 0.78, const Color(0xFF195DE6)),
                _statusRow("Route 12: West Side Residential", 0.92, Colors.red),
                _statusRow("Route 05: University Link", 0.45, const Color(0xFF195DE6)),
                _statusRow("Route 08: South Tech Park", 0.62, const Color(0xFF195DE6)),
                _statusRow("Route 21: Harbor Loop", 0.84, Colors.orange),
              ],
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    _quickButton("Send Notification", Icons.send, isPrimary: true),
                    const SizedBox(height: 12),
                    _quickButton("Generate Daily Report", Icons.summarize, isPrimary: false),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const AlertBox(),
            ],
          ),
        )
      ],
    );
  }

  Widget _statusRow(String label, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text("${(progress * 100).toInt()}%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, color: color, backgroundColor: const Color.fromARGB(255, 0, 0, 0), minHeight: 8, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }

  Widget _quickButton(String label, IconData icon, {required bool isPrimary}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF195DE6) : const Color(0xFFF8FAFC),
          foregroundColor: isPrimary ? Colors.white : Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {},
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class AlertBox extends StatelessWidget {
  const AlertBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                  Text("SYSTEM ALERTS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text("LIVE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 16),
          _alertItem("Bus 04: Maintenance Due", "Oil change & brake inspection req.", Colors.orange),
          _alertItem("Route 12: High Occupancy", "Approaching capacity limit (92%).", Colors.red),
          _alertItem("Driver Shift Update", "M. Jordan completed Morning Shift.", Colors.blue),
        ],
      ),
    );
  }

  Widget _alertItem(String title, String sub, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(width: 3, height: 40, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              Text(sub, style: const TextStyle(fontSize: 11, color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }
}

class FleetTrackingOverview extends StatelessWidget {
  const FleetTrackingOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 400,
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(40.7128, -74.0060),
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.bus',
            ),
            const MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(40.7128, -74.0060),
                  child: Icon(Icons.directions_bus, color: Color(0xFF195DE6), size: 30),
                ),
                Marker(
                  point: LatLng(40.7228, -74.0160),
                  child: Icon(Icons.directions_bus, color: Color(0xFF195DE6), size: 30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}