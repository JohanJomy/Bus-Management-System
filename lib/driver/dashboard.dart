import 'package:flutter/material.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool isLiveSharing = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme Colors
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textPrim = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSec = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryColor = const Color(0xFF137FEC);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCircleButton(Icons.person, isDark),
                      Column(
                        children: [
                          Text('ROUTE 42-B', style: TextStyle(color: textSec, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          Text('Driver Dashboard', style: TextStyle(color: textPrim, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      _buildCircleButton(Icons.notifications, isDark),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100), // Space for nav bar
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        
                        // System Ready Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPulsingDot(),
                              const SizedBox(width: 8),
                              const Text('System Ready', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Text('Ready to Start?', style: TextStyle(color: textPrim, fontSize: 30, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Broadcasting live to 48 students', style: TextStyle(color: textSec, fontSize: 14)),
                        
                        const SizedBox(height: 32),

                        // Map Card
                        _buildMapCard(isDark, primaryColor, textPrim, textSec),
                        
                        const SizedBox(height: 32),

                        // Live Sharing Switch
                        SizedBox(
                          width: 280,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Live Sharing', style: TextStyle(color: textSec, fontSize: 14, fontWeight: FontWeight.w500)),
                              Switch(
                                value: isLiveSharing, 
                                onChanged: (v) => setState(() => isLiveSharing = v),
                                activeColor: primaryColor,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Start Trip Button
                        SizedBox(
                          width: 280,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 8,
                              shadowColor: primaryColor.withOpacity(0.3),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_bus, color: Colors.white),
                                SizedBox(width: 12),
                                Text('START TRIP', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Stats Grid
                        Row(
                          children: [
                            Expanded(child: _buildStatCard(isDark, cardColor, Icons.group, "TOTAL STUDENTS", "48", textSec, textPrim)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildStatCard(isDark, cardColor, Icons.payments, "PENDING FEES", "2", Colors.orange, textPrim)),
                          ],
                        ),
                        
                        const SizedBox(height: 120), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Navigation
          _buildBottomNavBar(isDark, textSec, primaryColor),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black87),
    );
  }

  Widget _buildPulsingDot() {
    return SizedBox(
      width: 8,
      height: 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(bool isDark, Color primary, Color textPrim, Color textSec) {
    return Container(
      width: double.infinity,
      height: 340, // Aspect Ratio approx 1:1
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
           BoxShadow(color: primary.withOpacity(0.05), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Map Image Placeholder
          Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCuaeFDU5bDXl3z2FoAgbM8mV5tiN494vZgXyUOowXVJKJECcsBixPUWJ2h0Ei1drEhmt7fVCFveY8ZrCXWPONg_EqaI0sl2k8Vgap3Y43q8Vf43W7smAPFsKv2xp6udgGbQwQ6F02J9VzmoAWqyFrc6CSRe8gCWcIbtg_SkvKXpNwcqdsXPiFHwT90dVeij48QR6hd2RGX7YcMIcDyHlmEQzc266JDNycrSqjd_B81jTRNv_mxlA7ScKkiLKf_wogqAFd57au47vzm',
            fit: BoxFit.cover,
          ),
          
          // Overlay Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
              ),
            ),
          ),

          // Map Control Buttons
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              children: [
                _buildMapBtn(Icons.my_location, primary, isDark),
                const SizedBox(height: 8),
                _buildMapBtn(Icons.layers, isDark ? Colors.white : Colors.black87, isDark),
              ],
            ),
          ),

          // Top Info Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0F172A) : Colors.white).withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.location_on, color: primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UPCOMING', style: TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('Oakridge School', style: TextStyle(color: textPrim, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('0.5 miles • 3 mins', style: TextStyle(color: textSec, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('8:45', style: TextStyle(color: textPrim, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('ETA', style: TextStyle(color: textSec, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMapBtn(IconData icon, Color color, bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildStatCard(bool isDark, Color cardColor, IconData icon, String label, String value, Color iconColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: TextStyle(color: iconColor, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(bool isDark, Color textSec, Color primary) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)).withOpacity(0.9),
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.dashboard, "Home", true, primary, textSec),
            _buildNavItem(Icons.alt_route, "Routes", false, primary, textSec),
            _buildNavItem(Icons.badge, "Students", false, primary, textSec),
            _buildNavItem(Icons.settings, "Settings", false, primary, textSec),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, Color primary, Color textSec) {
    final color = isActive ? primary : textSec;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}
