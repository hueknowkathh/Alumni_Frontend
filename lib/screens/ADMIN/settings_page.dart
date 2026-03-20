import 'package:flutter/material.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  // Color Palette
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE0E0E0);
  final Color fieldFillColor = const Color(0xFFF1F3F4); // Distinct grey for inputs
  final Color darkButtonColor = const Color(0xFF0D0D1D); // Solid Black for buttons

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgLight,
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              "Settings",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Manage your account and system configuration",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // 1. Profile Information Card
            _buildSectionCard(
              title: "Profile Information",
              icon: Icons.person_outline,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTextField("Full Name", "Admin User")),
                      const SizedBox(width: 24),
                      Expanded(child: _buildTextField("Email Address", "admin@university.edu")),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField("Role", "System Administrator", enabled: false),
                  const SizedBox(height: 24),
                  _buildSolidButton("Save Changes", Icons.save_outlined, () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Security Card
            _buildSectionCard(
              title: "Security",
              icon: Icons.lock_outline,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField("Current Password", "••••••••••••••••", isPassword: true),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField("New Password", "••••••••••••", isPassword: true)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildTextField("Confirm New Password", "••••••••••••", isPassword: true)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Password must be at least 8 characters long",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  _buildSolidButton("Update Password", Icons.key_outlined, () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. System Information Card
            _buildSectionCard(
              title: "System Information",
              icon: Icons.settings_outlined,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTextField("University Name", "ABC University")),
                      const SizedBox(width: 24),
                      Expanded(child: _buildTextField("System Name", "Alumni Tracer System")),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          "Contact Email", 
                          "alumni@abc.edu", 
                          prefixIcon: Icons.email_outlined
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTextField(
                          "Contact Number", 
                          "+63 123 456 7890", 
                          prefixIcon: Icons.phone_outlined
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSolidButton("Update System Info", Icons.save_outlined, () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card Container
  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black87),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  // Text Field with Grey Fill
  Widget _buildTextField(String label, String initialValue, {bool enabled = true, bool isPassword = false, IconData? prefixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          enabled: enabled,
          obscureText: isPassword,
          style: TextStyle(color: enabled ? Colors.black87 : Colors.grey),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: Colors.grey) : null,
            filled: true,
            fillColor: fieldFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // CUSTOM SOLID BLACK BUTTON
  // This solves the color visibility issue by avoiding default button themes
  Widget _buildSolidButton(String label, IconData icon, VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: darkButtonColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}