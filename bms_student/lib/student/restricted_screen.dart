import 'package:flutter/material.dart';

class RestrictedScreen extends StatelessWidget {
  const RestrictedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: isDark ? Colors.white10 : Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: isDark ? Colors.white : Colors.black,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    'Tracking Restricted',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            const Spacer(),

            // Lock Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151D27) : Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 10,
                  )
                ],
              ),
              child: Icon(Icons.lock, size: 60, color: primaryColor),
            ),
            const SizedBox(height: 40),

            // Text Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    'Payment Required',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Live bus tracking is currently locked. Please pay your outstanding fees to view the real-time location.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], height: 1.5),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/fees'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: primaryColor.withOpacity(0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Pay Fees', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'View Details',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Nav Placeholder
            Container(
              height: 80,
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey[100]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNav(Icons.map, 'Tracking', true, primaryColor),
                  _buildNav(Icons.account_balance_wallet, 'Payments', false, Colors.grey),
                  _buildNav(Icons.notifications, 'Alerts', false, Colors.grey),
                  _buildNav(Icons.person, 'Profile', false, Colors.grey),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNav(IconData icon, String label, bool active, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
