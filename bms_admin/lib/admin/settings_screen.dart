import 'package:flutter/material.dart';
import 'app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController(
    text: "Alex Johnson",
  );
  final TextEditingController _emailController = TextEditingController(
    text: "alex.j@busadminpro.com",
  );

  String _selectedTheme = "Light Mode";
  String _selectedTimezone = "(GMT-05:00) Eastern Time";

  bool _emailAlerts = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;

  void _handleThemeChange(String? value) {
    if (value == null) return;
    setState(() => _selectedTheme = value);
    appIsDark.value = (value == "Dark Mode");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page title ──────────────────────────────────────────────
          Text(
            "Settings",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: onSurface(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Configure system preferences and admin account details.",
            style: TextStyle(fontSize: 14, color: onSurfaceVariant(context)),
          ),
          const SizedBox(height: 28),

          // ── Profile Settings ────────────────────────────────────────
          _sectionCard(
            context: context,
            icon: Icons.person_outline,
            title: "Profile Settings",
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB2C9A5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFF195DE6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 28),
                // Fields
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _labeledField(
                              context: context,
                              label: "Full Name",
                              controller: _nameController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _labeledField(
                              context: context,
                              label: "Email Address",
                              controller: _emailController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _labeledReadOnly(
                              context: context,
                              label: "Admin Role",
                              value: "Super Admin",
                            ),
                          ),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── System Preferences ──────────────────────────────────────
          _sectionCard(
            context: context,
            icon: Icons.tune,
            title: "System Preferences",
            child: Row(
              children: [
                Expanded(
                  child: _dropdownField(
                    context: context,
                    label: "Theme Mode",
                    value: _selectedTheme,
                    items: ["Light Mode", "Dark Mode", "System Default"],
                    onChanged: _handleThemeChange,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _dropdownField(
                    context: context,
                    label: "Timezone",
                    value: _selectedTimezone,
                    items: [
                      "(GMT-05:00) Eastern Time",
                      "(GMT-06:00) Central Time",
                      "(GMT-07:00) Mountain Time",
                      "(GMT-08:00) Pacific Time",
                      "(GMT+00:00) UTC",
                      "(GMT+05:30) India Standard Time",
                    ],
                    onChanged: (v) => setState(() => _selectedTimezone = v!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Security + Notifications (side-by-side) ─────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _sectionCard(
                  context: context,
                  icon: Icons.shield_outlined,
                  title: "Security",
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Change Password",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: onSurface(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Last changed 3 months ago",
                            style: TextStyle(
                              fontSize: 12,
                              color: onSurfaceVariant(context),
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor(context)),
                          foregroundColor: onSurface(context),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Update"),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _sectionCard(
                  context: context,
                  icon: Icons.notifications_active_outlined,
                  title: "Notifications",
                  child: Column(
                    children: [
                      _toggleRow(
                        context: context,
                        label: "Email Alerts",
                        icon: Icons.email_outlined,
                        value: _emailAlerts,
                        onChanged: (v) => setState(() => _emailAlerts = v),
                      ),
                      const SizedBox(height: 16),
                      _toggleRow(
                        context: context,
                        label: "SMS Notifications",
                        icon: Icons.sms_outlined,
                        value: _smsNotifications,
                        onChanged: (v) => setState(() => _smsNotifications = v),
                      ),
                      const SizedBox(height: 16),
                      _toggleRow(
                        context: context,
                        label: "Push Notifications",
                        icon: Icons.campaign_outlined,
                        value: _pushNotifications,
                        onChanged: (v) =>
                            setState(() => _pushNotifications = v),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Action buttons ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: onSurfaceVariant(context),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                child: const Text("Discard Changes"),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text("Save All Changes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF195DE6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Footer ──────────────────────────────────────────────────
          Divider(color: borderColor(context)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "© 2024 BusAdmin Pro. All rights reserved.",
                style: TextStyle(
                  fontSize: 12,
                  color: onSurfaceVariant(context),
                ),
              ),
              Wrap(
                spacing: 16,
                children: [
                  Text(
                    "Privacy Policy",
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurfaceVariant(context),
                    ),
                  ),
                  Text(
                    "Terms of Service",
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurfaceVariant(context),
                    ),
                  ),
                  Text(
                    "Support",
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurfaceVariant(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────

  Widget _sectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
              Icon(icon, color: const Color(0xFF195DE6), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: onSurface(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _labeledField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: onSurfaceVariant(context)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: TextStyle(fontSize: 14, color: onSurface(context)),
          decoration: InputDecoration(
            filled: true,
            fillColor: inputFillColor(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF195DE6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _labeledReadOnly({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: onSurfaceVariant(context)),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: inputFillColor(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor(context)),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: onSurfaceVariant(context)),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required BuildContext context,
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: onSurfaceVariant(context)),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: surfaceColor(context),
          style: TextStyle(fontSize: 14, color: onSurface(context)),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: TextStyle(fontSize: 14, color: onSurface(context)),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: inputFillColor(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF195DE6)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleRow({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: onSurfaceVariant(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: onSurface(context)),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF195DE6),
        ),
      ],
    );
  }
}
