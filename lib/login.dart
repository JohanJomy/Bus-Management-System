import 'package:flutter/material.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors from tailwind config
    const navyDeep = Color(0xFF04070D); // navy-deep
    const primaryBlue = Color(0xFF3B82F6); // primary

    return Scaffold(
      backgroundColor: navyDeep,
      body: Stack(
        children: [
          // Background Blurs
          Positioned(
            top: -100,
            left: -100,
            child: _buildBlurCircle(const Color(0xFF2563EB), 400),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: _buildBlurCircle(const Color(0xFF3B82F6), 400),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40), // px-10
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80), // Header spacing
                  
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Opacity(
                          opacity: 0.9,
                          child: Icon(
                            Icons.directions_bus,
                            size: 48,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                           "BUSCONNECT",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 20, // text-xl
                            fontWeight: FontWeight.w300, // font-light
                            letterSpacing: 3.0, // tracking-ultra-wide
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // Buttons
                  // Student Button
                  _buildGlassButton(
                    context,
                    icon: Icons.person,
                    label: "STUDENT",
                    onTap: () => Navigator.pushNamed(context, '/student/login'),
                    primaryBlue: primaryBlue,
                  ),
                  
                  const SizedBox(height: 16), // gap-4

                  // Driver Button
                  _buildGlassButton(
                    context,
                    icon: Icons.airline_seat_recline_normal,
                    label: "DRIVER",
                    onTap: () => Navigator.pushNamed(context, '/driver/login'),
                    primaryBlue: primaryBlue,
                  ),

                  const Spacer(flex: 2),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFooterLink("HELP"),
                      const SizedBox(width: 32),
                      _buildFooterLink("PRIVACY"),
                      const SizedBox(width: 32),
                      _buildFooterLink("LEGAL"),
                    ],
                  ),
                  const SizedBox(height: 40),
                  
                  // Home Indicator
                  Center(
                    child: Container(
                      width: 128,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 0)],
        ),
      ),
    );
  }

  Widget _buildGlassButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap, required Color primaryBlue}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        color: Colors.white.withOpacity(0.02),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withOpacity(0.05),
          highlightColor: Colors.white.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 20),
                  child: Icon(icon, color: primaryBlue, size: 24),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5, // tracking-button
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.2),
        fontSize: 9,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5, // tracking-widest
      ),
    );
  }
}
