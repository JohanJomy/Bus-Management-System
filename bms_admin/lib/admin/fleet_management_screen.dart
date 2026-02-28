import 'package:flutter/material.dart';
import 'app_theme.dart';

class FleetManagementScreen extends StatelessWidget {
  const FleetManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Bus & Fleet Management",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: onSurface(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Manage your active fleet and monitor performance metrics.",
                    style: TextStyle(
                      color: onSurfaceVariant(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _actionButton(
                    context,
                    "Export Fleet Data",
                    Icons.download,
                    isPrimary: false,
                  ),
                  const SizedBox(width: 12),
                  _actionButton(
                    context,
                    "Add New Bus",
                    Icons.add,
                    isPrimary: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Summary Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _summaryCard(
                    context,
                    "Total Buses",
                    "42",
                    Icons.directions_bus,
                    Colors.blue,
                    subtitle: "+2 from last month",
                    isTrendUp: true,
                  ),
                  _summaryCard(
                    context,
                    "In Operation",
                    "35",
                    Icons.check_circle,
                    Colors.green,
                    subtitle: "Active on 12 routes",
                  ),
                  _summaryCard(
                    context,
                    "Maintenance Req.",
                    "4",
                    Icons.build,
                    Colors.orange,
                    subtitle: "Immediate action needed",
                    isWarning: true,
                  ),
                  _summaryCard(
                    context,
                    "Avg. Occupancy",
                    "68%",
                    Icons.group,
                    Colors.blueAccent,
                    subtitle: "Optimized fleet usage",
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Main Content: Table and Maintenance
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Inventory Table
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor(context)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Vehicle Inventory",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: onSurface(context),
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                "View All",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF195DE6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildInventoryTable(context),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 32),

              // Upcoming Maintenance
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          "Upcoming Maintenance",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: onSurface(context),
                          ),
                        ),
                      ),
                      _maintenanceItem(
                        context,
                        "BUS-089 - Oil Change",
                        "Scheduled: Oct 24, 2023",
                        Icons.oil_barrel,
                        Colors.orange,
                      ),
                      _maintenanceItem(
                        context,
                        "BUS-112 - Brake Inspection",
                        "Scheduled: Oct 26, 2023",
                        Icons.settings_input_component,
                        Colors.blue,
                      ),
                      _maintenanceItem(
                        context,
                        "BUS-045 - Tire Rotation",
                        "Scheduled: Oct 29, 2023",
                        Icons.tire_repair,
                        Colors.purple,
                      ),
                      _maintenanceItem(
                        context,
                        "BUS-099 - Yearly Permit",
                        "Due: Nov 02, 2023",
                        Icons.verified,
                        Colors.green,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: inputFillColor(context),
                            foregroundColor: onSurface(context),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: borderColor(context)),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            "Manage Schedule",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: onSurface(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _actionButton(
    BuildContext context,
    String label,
    IconData icon, {
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF195DE6) : surfaceColor(context),
        borderRadius: BorderRadius.circular(8),
        border: isPrimary ? null : Border.all(color: borderColor(context)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isPrimary ? Colors.white : onSurface(context),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : onSurface(context),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    required String subtitle,
    bool isTrendUp = false,
    bool isWarning = false,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning ? Colors.orange[200]! : borderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: onSurfaceVariant(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: onSurface(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: isTrendUp
                  ? Colors.green
                  : (isWarning
                        ? Colors.orange[700]
                        : onSurfaceVariant(context)),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  TableRow _tableRow(
    BuildContext context,
    String id,
    String plate,
    String seats,
    double occupancy,
    String route,
    String status,
    Color statusColor,
  ) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor(context), width: 0.5),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            id,
            style: const TextStyle(
              color: Color(0xFF195DE6),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plate,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: onSurface(context),
                ),
              ),
              Text(
                seats,
                style: TextStyle(
                  fontSize: 12,
                  color: onSurfaceVariant(context),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: occupancy,
                  backgroundColor: borderColor(context),
                  color: const Color(0xFF195DE6),
                  minHeight: 6,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${(occupancy * 100).toInt()}%",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: onSurface(context),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            route,
            style: TextStyle(color: onSurfaceVariant(context), fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryTable(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: inputFillColor(context)),
          children:
              ["BUS ID", "PLATE &\nCAPACITY", "OCCUPANCY", "ROUTE", "STATUS"]
                  .map(
                    (text) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: onSurfaceVariant(context),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        _tableRow(
          context,
          "BUS-102",
          "ABC-1234",
          "52 Seats",
          0.85,
          "Downtown - Route A",
          "ON ROUTE",
          Colors.green,
        ),
        _tableRow(
          context,
          "BUS-089",
          "XYZ-9876",
          "40 Seats",
          0.42,
          "Suburban - Line 4",
          "ON ROUTE",
          Colors.green,
        ),
        _tableRow(
          context,
          "BUS-115",
          "KLY-4421",
          "52 Seats",
          0.0,
          "Not Assigned",
          "IN MAINTENANCE",
          Colors.orange,
        ),
        _tableRow(
          context,
          "BUS-077",
          "ERT-5562",
          "32 Seats",
          0.60,
          "Campus - Loop B",
          "ON ROUTE",
          Colors.green,
        ),
      ],
    );
  }

  Widget _maintenanceItem(
    BuildContext context,
    String title,
    String date,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: onSurface(context),
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: onSurfaceVariant(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: onSurfaceVariant(context), size: 18),
        ],
      ),
    );
  }
}
