import 'package:flutter/material.dart';
import 'app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildTopSection(context),
            const SizedBox(height: 24),
            _buildRecentNotifications(context),
            const SizedBox(height: 40),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: onSurface(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage system alerts and student communication.',
                style: TextStyle(
                  fontSize: 14,
                  color: onSurfaceVariant(context),
                ),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: borderColor(context)),
            foregroundColor: onSurface(context),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Notification History',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
          label: const Text(
            'Send New Alert',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF195DE6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ── Top section: channels + daily volume ─────────────────────────────────
  Widget _buildTopSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _buildChannelsCard(context)),
        const SizedBox(width: 20),
        SizedBox(width: 220, child: _buildAlertVolumeCard(context)),
      ],
    );
  }

  Widget _buildChannelsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Communication Channels',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: onSurface(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark(context)
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: borderColor(context)),
                ),
                child: Text(
                  'LIVE STATUS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: onSurfaceVariant(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _channelItem(
                  context,
                  icon: Icons.sms_outlined,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF6366F1),
                  label: 'SMS Gateway',
                  status: 'Operational',
                  statusColor: const Color(0xFF22C55E),
                  darkIconBg: const Color(0xFF1E293B),
                ),
              ),
              Expanded(
                child: _channelItem(
                  context,
                  icon: Icons.email_outlined,
                  iconBg: const Color(0xFFFAF5FF),
                  iconColor: const Color(0xFFA855F7),
                  label: 'Email Service',
                  status: 'Operational',
                  statusColor: const Color(0xFF22C55E),
                  darkIconBg: const Color(0xFF1E293B),
                ),
              ),
              Expanded(
                child: _channelItem(
                  context,
                  icon: Icons.notifications_active_outlined,
                  iconBg: const Color(0xFFFFFBEB),
                  iconColor: const Color(0xFFF59E0B),
                  label: 'Push Notifications',
                  status: 'Standby',
                  statusColor: const Color(0xFFF59E0B),
                  darkIconBg: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _channelItem(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color darkIconBg,
    required String label,
    required String status,
    required Color statusColor,
  }) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isDark(context) ? darkIconBg : iconBg,
            borderRadius: BorderRadius.circular(12),
            border: isDark(context)
                ? Border.all(color: borderColor(context))
                : null,
          ),
          child: Icon(icon, color: iconColor, size: 26),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: onSurface(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertVolumeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF195DE6)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Daily Alert Volume',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '1,284',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              const Text(
                '+12% from yesterday',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Recent Notifications ──────────────────────────────────────────────────
  Widget _buildRecentNotifications(BuildContext context) {
    final notifications = [
      _NotificationItem(
        category: 'DELAY ALERT',
        categoryColor: const Color(0xFFF59E0B),
        categoryBg: const Color(0xFFFFFBEB),
        categoryBgDark: const Color(0xFF292524),
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFF59E0B),
        iconBg: const Color(0xFFFFFBEB),
        iconBgDark: const Color(0xFF292524),
        time: '2 mins ago',
        title: 'Route B-12: Traffic Congestion at Main St.',
        description:
            'Expected delay of 15 minutes for all stops after Lincoln Square. SMS sent to 45 parents.',
      ),
      _NotificationItem(
        category: 'MAINTENANCE',
        categoryColor: const Color(0xFF3B82F6),
        categoryBg: const Color(0xFFEFF6FF),
        categoryBgDark: const Color(0xFF1E3A5F),
        icon: Icons.build_outlined,
        iconColor: const Color(0xFF3B82F6),
        iconBg: const Color(0xFFEFF6FF),
        iconBgDark: const Color(0xFF1E3A5F),
        time: '45 mins ago',
        title: 'Bus #402: Scheduled Oil Change & Inspection',
        description:
            'Fleet vehicle #402 is due for routine maintenance in 24 hours. Replacement bus #501 assigned.',
      ),
      _NotificationItem(
        category: 'FEE REMINDER',
        categoryColor: const Color(0xFF22C55E),
        categoryBg: const Color(0xFFF0FDF4),
        categoryBgDark: const Color(0xFF14532D),
        icon: Icons.receipt_long_outlined,
        iconColor: const Color(0xFF22C55E),
        iconBg: const Color(0xFFF0FDF4),
        iconBgDark: const Color(0xFF14532D),
        time: '3 hours ago',
        title: 'Automated Monthly Fee Reminder Sent',
        description:
            'Notifications dispatched to 212 accounts with outstanding balances for the current month.',
      ),
      _NotificationItem(
        category: 'EMERGENCY',
        categoryColor: const Color(0xFFEF4444),
        categoryBg: const Color(0xFFFEF2F2),
        categoryBgDark: const Color(0xFF3B0000),
        icon: Icons.emergency_outlined,
        iconColor: const Color(0xFFEF4444),
        iconBg: const Color(0xFFFEF2F2),
        iconBgDark: const Color(0xFF3B0000),
        time: '6 hours ago',
        title: 'Weather Alert: Early Dismissal Tomorrow',
        description:
            'Broadcast sent via all channels. Buses will depart 2 hours early due to predicted snow storm.',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor(context)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Text(
                  'Recent Notifications',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onSurface(context),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.filter_list_rounded,
                  color: onSurfaceVariant(context),
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Notification rows
          ...notifications.map((n) => _buildNotificationRow(context, n)),
          // Load older
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: TextButton(
              onPressed: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Load older notifications',
                    style: TextStyle(
                      color: Color(0xFF195DE6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF195DE6),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationRow(BuildContext context, _NotificationItem item) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor(context))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark(context) ? item.iconBgDark : item.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark(context)
                            ? item.categoryBgDark
                            : item.categoryBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.categoryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '· ${item.time}',
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurfaceVariant(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: onSurface(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurfaceVariant(context),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // View Details button
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: borderColor(context)),
              foregroundColor: onSurface(context),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Text(
        '© 2024 BusAdmin Pro - Advanced Fleet Logistics & Communication',
        style: TextStyle(fontSize: 12, color: onSurfaceVariant(context)),
      ),
    );
  }
}

// ── Data model ───────────────────────────────────────────────────────────────
class _NotificationItem {
  final String category;
  final Color categoryColor;
  final Color categoryBg;
  final Color categoryBgDark;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color iconBgDark;
  final String time;
  final String title;
  final String description;

  const _NotificationItem({
    required this.category,
    required this.categoryColor,
    required this.categoryBg,
    required this.categoryBgDark,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.iconBgDark,
    required this.time,
    required this.title,
    required this.description,
  });
}
