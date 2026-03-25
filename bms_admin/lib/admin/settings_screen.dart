import 'package:flutter/material.dart';
import 'app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController(
    text: "DEEPTHI C NAIR",
  );
  final TextEditingController _emailController = TextEditingController(
    text: "deepthi.c@saintgits.org",
  );

  String _selectedTheme = "Light Mode";
  String _selectedTimezone = "(GMT+05:30) India Standard Time";

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;

                if (isSmallScreen) {
                  // Mobile: Stack vertically
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                      const SizedBox(height: 16),
                      // Fields
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _labeledField(
                            context: context,
                            label: "Full Name",
                            controller: _nameController,
                          ),
                          const SizedBox(height: 16),
                          _labeledField(
                            context: context,
                            label: "Email Address",
                            controller: _emailController,
                          ),
                          const SizedBox(height: 16),
                          _labeledReadOnly(
                            context: context,
                            label: "Admin Role",
                            value: "Super Admin",
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Desktop: Side by side
                  return Row(
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
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── System Preferences ──────────────────────────────────────
          _sectionCard(
            context: context,
            icon: Icons.tune,
            title: "System Preferences",
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;

                if (isSmallScreen) {
                  // Mobile: Stack vertically
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _dropdownField(
                        context: context,
                        label: "Theme Mode",
                        value: _selectedTheme,
                        items: ["Light Mode", "Dark Mode", "System Default"],
                        onChanged: _handleThemeChange,
                      ),
                      const SizedBox(height: 16),
                      _dropdownField(
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
                        onChanged: (v) =>
                            setState(() => _selectedTimezone = v!),
                      ),
                    ],
                  );
                } else {
                  // Desktop: Side by side
                  return Row(
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
                          onChanged: (v) =>
                              setState(() => _selectedTimezone = v!),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
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

}
