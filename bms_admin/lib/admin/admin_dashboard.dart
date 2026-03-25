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
import 'bus_allocation_screen.dart';
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
    const BusAllocationScreen(),
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
                        Header(
                          onProfileTap: () {
                            setState(() {
                              _selectedIndex = 8;
                            });
                          },
                        ),
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
          const FleetTrackingOverview(),
        ],
      ),
    );
  }
}

// --- RESTORED: Header with Search Bar ---
class Header extends StatelessWidget {
  final VoidCallback onProfileTap;

  const Header({super.key, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: surfaceColor(context),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person, size: 20, color: Colors.white),
            ),
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

  String _todayLabel() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back, DEEPTHI C NAIR",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: onSurface(context),
          ),
        ),
        Text(
          "${_todayLabel()} | System overview is looking good.",
          style: TextStyle(color: onSurfaceVariant(context), fontSize: 14),
        ),
      ],
    );
  }
}

// --- RESTORED: Metrics Grid ---
class MetricsGrid extends StatelessWidget {
  const MetricsGrid({super.key});

  Future<int> _countTableRows({
    required SupabaseClient client,
    required String table,
  }) async {
    const pageSize = 1000;
    var total = 0;
    var from = 0;

    while (true) {
      final page =
          await client
                  .from(table)
                  .select('id')
                  .order('id')
                  .range(from, from + pageSize - 1)
              as List<dynamic>;

      final count = page.length;
      if (count == 0) {
        break;
      }

      total += count;
      if (count < pageSize) {
        break;
      }
      from += pageSize;
    }

    return total;
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
                                FutureBuilder<int>(
                                  future: _countTableRows(
                                    client: client,
                                    table: 'students',
                                  ),
                                  builder: (context, countSnapshot) {
                                    final studentCount = countSnapshot.data;
                                    return MetricCard(
                                      title: "TOTAL STUDENTS",
                                      value: studentCount == null
                                          ? '...'
                                          : _formatCount(studentCount),
                                      icon: Icons.group,
                                    );
                                  },
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

// --- RESTORED: Map Overview ---
class FleetTrackingOverview extends StatelessWidget {
  const FleetTrackingOverview({super.key});
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = (screenHeight * 0.58).clamp(420.0, 760.0);
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
    return Container(
      height: double.infinity,
      width: sidebarWidth,
      color: surfaceColor(context),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: screenWidth > 768 ? 12 : 0,
          ),
          child: Column(
            children: [
              _logoHeader(context),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _navItem(context, Icons.dashboard, "Dashboard", 0),
                      _navItem(
                        context,
                        Icons.payments_outlined,
                        "Fees & Payments",
                        1,
                      ),
                      _navItem(
                        context,
                        Icons.commute_outlined,
                        "Fleet Management",
                        2,
                      ),
                      _navItem(
                        context,
                        Icons.groups_outlined,
                        "Bus-wise Students",
                        3,
                      ),
                      _navItem(
                        context,
                        Icons.person_outline,
                        "Student Management",
                        4,
                      ),
                      _navItem(
                        context,
                        Icons.location_city_outlined,
                        "Boarding Stops",
                        5,
                      ),
                      _navItem(context, Icons.map_outlined, "Route Mapping", 6),
                      _navItem(
                        context,
                        Icons.alt_route_outlined,
                        "Bus Allocation",
                        7,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _navItem(context, Icons.settings_outlined, "Settings", 8),
            ],
          ),
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
