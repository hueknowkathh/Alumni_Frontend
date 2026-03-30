import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic> user; // Per-user settings
  const SettingsPage({super.key, required this.user});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Form and Controller state
  final _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Notification Toggles (loaded from backend/user)
  bool _emailAnnouncements = true;
  bool _emailReminders = true;
  bool _eventInvitations = false;

  static const Color lightBackground = Color(0xFFF7F8FA);

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  void _loadUserSettings() {
    // Initialize toggles from user data (if available)
    setState(() {
      _emailAnnouncements =
          widget.user['emailAnnouncements'] ?? true; // default true
      _emailReminders = widget.user['emailReminders'] ?? true;
      _eventInvitations = widget.user['eventInvitations'] ?? false;
    });
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ----------------- BACKEND UPDATE FUNCTIONS -----------------
  Future<void> _updateToggle(String key, bool value) async {
    try {
      final response = await http.post(
        ApiService.uri('update_settings.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": widget.user['id'],
          "setting": key,
          "value": value ? 1 : 0,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Settings updated!")));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'] ?? 'Error')));
      }
    } catch (e) {
      debugPrint("Settings update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update settings")),
      );
    }
  }

  Future<void> _updatePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    try {
      final response = await http.post(
        ApiService.uri('change_password.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": widget.user['id'],
          "currentPassword": _currentPasswordController.text,
          "newPassword": _newPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Password updated!")));
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to update password")),
        );
      }
    } catch (e) {
      debugPrint("Password update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error updating password")),
      );
    }
  }

  // ----------------- UI HELPERS -----------------
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller, {
    bool isConfirm = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1F3F4),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return "This field is required";
            if (isConfirm && value != _newPasswordController.text) {
              return "Passwords do not match";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSwitchRow(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (v) {
            onChanged(v);
            _updateToggle(title, v); // Update backend immediately
          },
          activeThumbColor: Colors.black,
        ),
      ],
    );
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

            // Change Password
            _buildSectionCard(
              title: "Change Password",
              icon: Icons.lock_outline,
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPasswordField(
                        "Current Password", _currentPasswordController),
                    const SizedBox(height: 20),
                    _buildPasswordField("New Password", _newPasswordController),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      "Confirm New Password",
                      _confirmPasswordController,
                      isConfirm: true,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _updatePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Update Password"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notification Preferences
            _buildSectionCard(
              title: "Notification Preferences",
              icon: Icons.notifications_none_outlined,
              child: Column(
                children: [
                  _buildSwitchRow(
                    "emailAnnouncements",
                    "Receive emails about new announcements",
                    _emailAnnouncements,
                    (v) => setState(() => _emailAnnouncements = v),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow(
                    "emailReminders",
                    "Receive reminders about tracer form and updates",
                    _emailReminders,
                    (v) => setState(() => _emailReminders = v),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow(
                    "eventInvitations",
                    "Receive invitations to alumni events",
                    _eventInvitations,
                    (v) => setState(() => _eventInvitations = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
