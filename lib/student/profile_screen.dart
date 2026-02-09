import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Accept student data from Navigator arguments; fall back to mock data
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic>? args;
    if (routeArgs is Map) {
      args = Map<String, dynamic>.from(routeArgs);
    }

    final student = {
      "name": args?['name'] ?? "Johan Jomy Kuruvilla",
      "branch": args?['branch'] ?? "Computer Science & Engineering",
      "college": args?['college'] ?? "Saintgits College of Engineering",
      "busNumber": args?['busNumber'] ?? "13",
      "busStop": args?['busStop'] ?? "Alumthuruty Market",
      "feeStatus": args?['feeStatus'] ?? "Paid",
      "imageUrl": args?['imageUrl'] ?? "https://i.pravatar.cc/300?u=alex",
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.grey[400] : Colors.grey[500];
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('Student Profile', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 1. Profile Image & Name
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF137FEC), width: 3),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF137FEC).withOpacity(0.3), blurRadius: 15)
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(student["imageUrl"]!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    student["name"]!,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text(
                    student["college"]!,
                    style: TextStyle(fontSize: 14, color: subColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Info Cards
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _buildRow(context, Icons.account_tree, "Branch", student["branch"]!, false),
                  _buildDivider(isDark),
                  _buildRow(context, Icons.directions_bus, "Bus Number", student["busNumber"]!, false),
                  _buildDivider(isDark),
                  _buildRow(context, Icons.place, "Bus Stop", student["busStop"]!, false),
                  _buildDivider(isDark),
                  _buildFeeRow(context, student["feeStatus"]!),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, IconData icon, String label, String value, bool isLast) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF137FEC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF137FEC), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  value, 
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A), 
                    fontSize: 15, 
                    fontWeight: FontWeight.bold
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(BuildContext context, String status) {
    final isPaid = status.toLowerCase() == "paid";
    final color = isPaid ? Colors.green : Colors.red;
    final icon = isPaid ? Icons.check_circle : Icons.warning;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.payments, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Fee Payment Status", style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  status, 
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A), 
                    fontSize: 15, 
                    fontWeight: FontWeight.bold
                  )
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1, 
      thickness: 1, 
      color: isDark ? Colors.grey[800] : Colors.grey[100], 
      indent: 60, // Align with text, skipping icon
    );
  }
}