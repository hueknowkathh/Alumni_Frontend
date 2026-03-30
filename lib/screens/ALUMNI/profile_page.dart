import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';
import '../../state/user_store.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  static const Color primaryMaroon = Color(0xFF4A152C);
  static const Color lightBackground = Color(0xFFF7F8FA);

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _statusController;
  late final TextEditingController _studentNumController;
  late final TextEditingController _gradYearController;
  late final TextEditingController _degreeController;
  late final TextEditingController _majorController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user['firstName'] ?? '');
    _lastNameController = TextEditingController(text: widget.user['lastName'] ?? '');
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
    _phoneController = TextEditingController(text: widget.user['phone'] ?? '');
    _addressController = TextEditingController(text: widget.user['address'] ?? '');
    _statusController = TextEditingController(text: widget.user['status'] ?? '');
    _studentNumController = TextEditingController(text: widget.user['studentNumber'] ?? '');
    _gradYearController = TextEditingController(text: widget.user['gradYear'] ?? '');
    _degreeController = TextEditingController(text: widget.user['degree'] ?? '');
    _majorController = TextEditingController(text: widget.user['major'] ?? '');
  }

  @override
  void dispose() {
    for (var controller in [
      _firstNameController,
      _lastNameController,
      _emailController,
      _phoneController,
      _addressController,
      _statusController,
      _studentNumController,
      _gradYearController,
      _degreeController,
      _majorController
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: lightBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "My Profile",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEditing
                            ? "Update your personal and academic details"
                            : "View and manage your personal information",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                  _buildHeaderButton(),
                ],
              ),
              const SizedBox(height: 32),
              if (!_isEditing)
                Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Profile Complete",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          Text("All required information has been provided",
                              style: TextStyle(fontSize: 13, color: Colors.green.shade700)),
                        ],
                      ),
                    ],
                  ),
                ),
              _buildProfileSection(
                title: "Personal Information",
                icon: Icons.person_outline,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildField("First Name", _firstNameController)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildField("Last Name", _lastNameController)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildField("Email Address", _emailController, icon: Icons.email_outlined),
                  const SizedBox(height: 20),
                  _buildField("Contact Number", _phoneController, icon: Icons.phone_outlined),
                  const SizedBox(height: 20),
                  _buildField("Address", _addressController, icon: Icons.location_on_outlined),
                  const SizedBox(height: 20),
                  _buildField("Civil Status", _statusController),
                ],
              ),
              const SizedBox(height: 32),
              _buildProfileSection(
                title: "Academic Information",
                icon: Icons.school_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _buildField("Student Number", _studentNumController, enabled: false)),
                      const SizedBox(width: 24),
                      Expanded(
                          child: _buildField("Graduation Year", _gradYearController,
                              icon: Icons.calendar_today_outlined)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildField("Degree", _degreeController),
                  const SizedBox(height: 20),
                  _buildField("Major/Program", _majorController),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton() {
    if (_isEditing) {
      return Row(
        children: [
          TextButton(
            onPressed: () => setState(() => _isEditing = false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryMaroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text("Save Changes"),
          ),
        ],
      );
    }

    return ElevatedButton.icon(
      onPressed: () => setState(() => _isEditing = true),
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: const Text("Edit Profile"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);
    String? feedbackMessage;
    bool saveSucceeded = true;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    final localPatch = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'name': fullName.isEmpty ? (widget.user['name'] ?? '') : fullName,
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'status': _statusController.text.trim(),
      'studentNumber': _studentNumController.text.trim(),
      'gradYear': _gradYearController.text.trim(),
      'degree': _degreeController.text.trim(),
      'major': _majorController.text.trim(),
    };

    // Update local state immediately so other screens update without a restart.
    UserStore.patch(localPatch);

    // Best-effort persist to backend (requires `update_profile.php` on your server).
    try {
      final rawUserId = UserStore.value?['id'] ?? widget.user['id'];
      final userId = int.tryParse('$rawUserId') ?? 0;

      if (userId > 0) {
        final response = await http.post(
          ApiService.uri('update_profile.php'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "userId": userId,
            ...localPatch,
          }),
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final status = decoded['status']?.toString().toLowerCase();
            if (status == 'success' && decoded['user'] is Map) {
              UserStore.patch(Map<String, dynamic>.from(decoded['user'] as Map));
            } else if (status != null && status != 'success') {
              saveSucceeded = false;
              feedbackMessage =
                  decoded['message']?.toString().trim().isNotEmpty == true
                  ? decoded['message']?.toString().trim()
                  : "Failed to update profile.";
            }
          } else {
            saveSucceeded = false;
            feedbackMessage = "Unexpected response while updating profile.";
          }
        } else {
          saveSucceeded = false;
          feedbackMessage = "Failed to update profile (${response.statusCode}).";
        }
      }
    } catch (e) {
      saveSucceeded = false;
      feedbackMessage = "Error saving profile. Please try again.";
      debugPrint("Profile update error: $e");
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isEditing = !saveSucceeded;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            feedbackMessage ??
                (saveSucceeded
                    ? "Profile Updated Successfully"
                    : "Failed to update profile."),
          ),
        ),
      );
    }
  }

  Widget _buildProfileSection(
      {required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryMaroon, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {IconData? icon, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.grey.shade700),
              const SizedBox(width: 6)
            ],
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2D2D2D))),
          ],
        ),
        const SizedBox(height: 8),
        _isEditing && enabled
            ? TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: lightBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(controller.text,
                    style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ),
      ],
    );
  }
}
