import 'dart:ui';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 1024;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          if (isDesktop) const Sidebar(),
          Expanded(
            child: Column(
              children: [
                const Header(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: const DashboardContent(),
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
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF137FEC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text("BusAdmin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SidebarItem(icon: Icons.home, label: "Home"),
          const SidebarItem(icon: Icons.map, label: "Tracking"),
          const SidebarItem(icon: Icons.admin_panel_settings, label: "Admin", isActive: true),
          const SidebarItem(icon: Icons.analytics, label: "Reports"),
          const SidebarItem(icon: Icons.settings, label: "Settings"),
          const Spacer(),
          const SystemStatusCard(),
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Dashboard", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Row(
            children: [
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Deepthi C. Nair", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text("Admin", style: TextStyle(fontSize: 10, color: Color(0xFF137FEC), fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF137FEC).withOpacity(0.3),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDvgaG7ptJsmcPxpohjxYRsGWe453trjYoO3wFETgO3FUBzT52glGmZAze1qvVTPlg_IsaYyx_YZIBt0t7Crhxx6_7h3ODJNAZ7d1Eruht6kATLLQxmwU6EDR1782WhnWDZ5P0_ZSC8h9IAnqZEs37EUpZwO-spI3B1wd1j0GbYXaNxsZgUMhdB8lkFwRwH6K1CE4CC_lktjWurVwGN1XjF_azAZnOEX1dWtE3Pb6HsWTbfwmJh_T6jD3xGPrOuTe27ApDjUEHy_vYE'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GlassCard(
          child: FleetOverview(),
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : (MediaQuery.of(context).size.width > 700 ? 2 : 1),
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.4,
          children: const [
            ActionCard(
              title: "Driver Management",
              subtitle: "42 Drivers Online • 5 Pending Approvals",
              icon: Icons.account_circle,
              color: Color(0xFF708238),
              badgeIcon: Icons.settings,
            ),
            ActionCard(
              title: "Route Planning",
              subtitle: "12 Active Routes • 3 Scheduled Updates",
              icon: Icons.alt_route,
              color: Color(0xFF137FEC),
              badgeIcon: Icons.edit_location_alt,
            ),
            ActionCard(
              title: "Bus Status",
              subtitle: "3 Maintenance Alerts Needs Urgent Action",
              icon: Icons.directions_bus,
              color: Color(0xFFF5F5DC),
              badgeIcon: Icons.bolt,
              isAlert: true,
            ),
          ],
        ),
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class FleetOverview extends StatelessWidget {
  const FleetOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ACTIVE FLEET OVERVIEW", style: TextStyle(fontSize: 10, color: Colors.grey[400], letterSpacing: 1.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text("24", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            SizedBox(width: 16),
            Text("Buses active now", style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatBadge({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class ActionCard extends StatefulWidget {
  final String title, subtitle;
  final IconData icon;
  final IconData badgeIcon;
  final Color color;
  final bool isAlert;
  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeIcon,
    required this.color,
    this.isAlert = false,
  });

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {},
        child: GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: widget.color.withOpacity(0.2)),
                        ),
                        child: Icon(widget.icon, color: widget.color, size: 32),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: widget.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0F172A), width: 2),
                          ),
                          child: Icon(widget.badgeIcon, color: widget.color == const Color(0xFFF5F5DC) ? const Color(0xFF708238) : Colors.white, size: 12),
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward, color: _isHovered ? Colors.white : Colors.white24, size: 20),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isAlert) ...[
                        const SizedBox(width: 8),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      ]
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(widget.subtitle, style: const TextStyle(fontSize: 13, color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  const SidebarItem({super.key, required this.icon, required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: isActive ? const Color(0xFF137FEC) : Colors.transparent, width: 3)),
        color: isActive ? const Color(0xFF137FEC).withOpacity(0.1) : Colors.transparent,
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? const Color(0xFF137FEC) : Colors.white38, size: 24),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(color: isActive ? const Color(0xFF137FEC) : Colors.white38, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class SystemStatusCard extends StatelessWidget {
  const SystemStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("SYSTEM STATUS", style: TextStyle(fontSize: 9, color: Colors.white38, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Text("All systems normal", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
