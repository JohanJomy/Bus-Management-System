import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme Colors
    final bgColor = isDark ? const Color(0xFF101922) : const Color(0xFFF6F6F8);
    final cardColor = isDark ? const Color(0xFF192633) : Colors.white;
    final primaryColor = const Color(0xFF137FEC);
    final borderColor = isDark ? const Color(0xFF324D67) : const Color(0xFFE2E8F0);
    final textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 430),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- LOGO SECTION ---
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: primaryColor,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- HEADER SECTION ---
                  Text(
                    "BUSCONNECT",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: textColor,
                      height: 1.1,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select your role to continue",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: subtitleColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 48),

                  // --- ROLE BUTTONS ---

                  // 1. STUDENT BUTTON
                  _buildRoleButton(
                    context,
                    label: "Student",
                    icon: Icons.person_outline,
                    onTap: () => Navigator.pushNamed(context, '/student/login'),
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    iconColor: iconColor,
                  ),
                  
                  const SizedBox(height: 16),

                  // 2. DRIVER BUTTON (Restored)
                  _buildRoleButton(
                    context,
                    label: "Driver",
                    icon: Icons.airline_seat_recline_normal_outlined,
                    onTap: () => Navigator.pushNamed(context, '/driver/login'),
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    iconColor: iconColor,
                  ),
                  
                  const SizedBox(height: 16),

                  // 3. ADMIN BUTTON (Now leads to the Login Screen)
                  _buildRoleButton(
                    context,
                    label: "Admin",
                    icon: Icons.admin_panel_settings_outlined,
                    onTap: () => Navigator.pushNamed(context, '/admin/login'),
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textColor: textColor,
                    iconColor: iconColor,
                  ),
                  
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build the consistent button style
  Widget _buildRoleButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(icon, size: 28, color: iconColor),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16, color: iconColor.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}