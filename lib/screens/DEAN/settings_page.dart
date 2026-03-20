import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Form and Controller state
  final _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Notification Toggles
  bool _emailAnnouncements = true;
  bool _emailReminders = true;
  bool _eventInvitations = false;

  static const Color primaryMaroon = Color(0xFF4A152C);
  static const Color lightBackground = Color(0xFFF7F8FA);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: lightBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            const Text(
              "Settings",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Manage your account settings and preferences",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 32),

            /// 1. CHANGE PASSWORD SECTION
            _buildSectionCard(
              title: "Change Password",
              icon: Icons.lock_outline,
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPasswordField("Current Password", _currentPasswordController),
                    const SizedBox(height: 20),
                    _buildPasswordField("New Password", _newPasswordController),
                    const SizedBox(height: 20),
                    _buildPasswordField("Confirm New Password", _confirmPasswordController, isConfirm: true),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handlePasswordUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Dark button as per design
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Update Password"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// 2. NOTIFICATION PREFERENCES
            _buildSectionCard(
              title: "Notification Preferences",
              icon: Icons.notifications_none_outlined,
              child: Column(
                children: [
                  _buildSwitchRow(
                    "Email Announcements", 
                    "Receive emails about new announcements", 
                    _emailAnnouncements, 
                    (v) => setState(() => _emailAnnouncements = v)
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow(
                    "Email Reminders", 
                    "Receive reminders about tracer form and updates", 
                    _emailReminders, 
                    (v) => setState(() => _emailReminders = v)
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow(
                    "Event Invitations", 
                    "Receive invitations to alumni events", 
                    _eventInvitations, 
                    (v) => setState(() => _eventInvitations = v)
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// 3. PRIVACY & SECURITY
            _buildSectionCard(
              title: "Privacy & Security",
              icon: Icons.verified_user_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Account Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  const Text(
                    "Your account is active and secure. Last login: March 16, 2026 at 9:30 AM",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  const Text("Data Privacy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Wrap(
                    children: [
                      const Text("Your personal information is protected and only used for alumni engagement purposes. Review our ", 
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                      InkWell(
                        onTap: () {},
                        child: const Text("Privacy Policy.", style: TextStyle(color: Colors.blue, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F), // Red deletion button
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Request Account Deletion"),
                  ),
                  const SizedBox(height: 8),
                  const Text("This will permanently delete your account and all associated data.", 
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// HELPER: UI Section Card
  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black87),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  /// HELPER: Password Field with Placeholder Styling
  Widget _buildPasswordField(String label, TextEditingController controller, {bool isConfirm = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1F3F4), // Light gray background per design
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return "This field is required";
            if (isConfirm && value != _newPasswordController.text) return "Passwords do not match";
            return null;
          },
        ),
      ],
    );
  }

  /// HELPER: Toggle Switch Row
  Widget _buildSwitchRow(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.black, // Dark switch per design
        ),
      ],
    );
  }

  /// LOGIC: Handle Password Submission
  void _handlePasswordUpdate() {
    if (_passwordFormKey.currentState!.validate()) {
      // Simulate API call
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password successfully updated!")),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }
}