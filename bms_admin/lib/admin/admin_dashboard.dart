import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fleet_management_screen.dart';
import 'fee_management_screen.dart';
import 'settings_screen.dart';
import 'bus_wise_student_screen.dart';
import 'student_management_screen.dart';
import 'boarding_list_screen.dart';
import 'route_mapping_screen.dart';
import 'app_theme.dart';
import '../services/fee_metrics_service.dart';

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
    const BusWiseStudentListScreen(),
    const StudentManagementScreen(),
    const BoardingListScreen(),
    const RouteMappingScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appIsDark,
      builder: (context, dark, _) {
        return Theme(
          data: dark ? darkTheme() : lightTheme(),
          child: Builder(
            builder: (context) => Scaffold(
              backgroundColor: bgColor(context),
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
                          child: IndexedStack(
                            index: _selectedIndex,
                            children: _pages,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        children: [
          const WelcomeSection(),
          const SizedBox(height: 32),
          const MetricsGrid(),
          const SizedBox(height: 32),
          const MiddleLayout(),
          const SizedBox(height: 32),
          const FleetTrackingOverview(),
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
    final dark = isDark(context);
    return Container(
      height: 64,
      color: surfaceColor(context),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: inputFillColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                style: TextStyle(color: onSurface(context)),
                decoration: InputDecoration(
                  hintText: "Search students, routes, or drivers...",
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: onSurfaceVariant(context),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: onSurfaceVariant(context),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.notifications_none, color: onSurfaceVariant(context)),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.person, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            "Admin",
            style: TextStyle(
              color: onSurface(context),
              fontWeight: FontWeight.w600,
            ),
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
        Text(
          "Welcome back, Admin",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: onSurface(context),
          ),
        ),
        Text(
          "Monday, 30 October 2023 | System overview is looking good.",
          style: TextStyle(color: onSurfaceVariant(context), fontSize: 14),
        ),
      ],
    );
  }
}

// --- RESTORED: Metrics Grid ---
class MetricsGrid extends StatelessWidget {
  const MetricsGrid({super.key});

  double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  String _formatCount(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      if (i != 0 && (raw.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }

  String _formatInrShort(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    }
    if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 3
        : screenWidth > 768
        ? 2
        : 1;
    final client = Supabase.instance.client;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: client.from('buses').stream(primaryKey: ['id']),
      builder: (context, busesSnapshot) {
        if (!busesSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: client.from('students').stream(primaryKey: ['id']),
          builder: (context, studentsSnapshot) {
            if (!studentsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: client.from('stops').stream(primaryKey: ['id']),
              builder: (context, stopsSnapshot) {
                if (!stopsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: client.from('payments').stream(primaryKey: ['id']),
                  builder: (context, paymentsSnapshot) {
                    if (!paymentsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final buses = busesSnapshot.data!;
                    final students = studentsSnapshot.data!;
                    final stops = stopsSnapshot.data!;
                    final payments = paymentsSnapshot.data!;
                    final feeMetrics = FeeMetricsService.compute(
                      stops: stops,
                      students: students,
                      payments: payments,
                    );

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final maxGridWidth = screenWidth > 1400
                            ? 1120.0
                            : constraints.maxWidth;
                        return Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxGridWidth),
                            child: GridView.count(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 18,
                              childAspectRatio: 2.35,
                              children: [
                                MetricCard(
                                  title: "ACTIVE BUSES",
                                  value: _formatCount(buses.length),
                                  icon: Icons.directions_bus,
                                ),
                                MetricCard(
                                  title: "TOTAL STUDENTS",
                                  value: _formatCount(students.length),
                                  icon: Icons.group,
                                ),
                                MetricCard(
                                  title: "PENDING FEES",
                                  value: _formatInrShort(
                                    feeMetrics.pendingAmount,
                                  ),
                                  icon: Icons.warning,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Theme.of(context).primaryColor, size: 30),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: onSurfaceVariant(context),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: onSurface(context),
                ),
              ),
            ],
          ),
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
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Live Fleet Status",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: onSurface(context),
            ),
          ),
          const SizedBox(height: 16),
          _statusRow(context, "Route 01: Downtown Express", 0.78),
          _statusRow(context, "Route 12: West Side Residential", 0.92),
        ],
      ),
    );
  }

  Widget _statusRow(BuildContext context, String label, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: onSurface(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: TextStyle(
                  color: onSurface(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            color: Theme.of(context).primaryColor,
            backgroundColor: inputFillColor(context),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = (screenHeight * 0.35).clamp(250.0, 400.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: mapHeight,
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(9.5107, 76.5511),
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: const LatLng(9.5107, 76.5511),
                  child: Icon(
                    Icons.directions_bus,
                    color: Theme.of(context).primaryColor,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth > 1024
        ? 260.0
        : screenWidth > 768
        ? 200.0
        : 70.0;
    final dark = isDark(context);
    return Container(
      width: sidebarWidth,
      color: surfaceColor(context),
      padding: EdgeInsets.symmetric(
        vertical: 24,
        horizontal: screenWidth > 768 ? 12 : 0,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _logoHeader(context),
            const SizedBox(height: 32),
            _navItem(context, Icons.dashboard, "Dashboard", 0),
            _navItem(context, Icons.payments_outlined, "Fees & Payments", 1),
            _navItem(context, Icons.commute_outlined, "Fleet Management", 2),
            _navItem(context, Icons.groups_outlined, "Bus-wise Students", 3),
            _navItem(context, Icons.person_outline, "Student Management", 4),
            _navItem(
              context,
              Icons.location_city_outlined,
              "Boarding Stops",
              5,
            ),
            _navItem(context, Icons.map_outlined, "Route Mapping", 6),
            const SizedBox(height: 16),
            _navItem(context, Icons.settings_outlined, "Settings", 7),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _logoHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCollapsed = screenWidth <= 768;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 24),
      child: isCollapsed
          ? Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 20,
              ),
            )
          : Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "BusAdmin Pro",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: onSurface(context),
                      ),
                    ),
                    Text(
                      "MANAGEMENT SUITE",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: onSurfaceVariant(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    bool isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isActive ? Colors.white : onSurfaceVariant(context),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : onSurface(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
