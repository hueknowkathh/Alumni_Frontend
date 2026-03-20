import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // State control
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Colors based on your theme
  static const Color primaryMaroon = Color(0xFF4A152C);
  static const Color lightBackground = Color(0xFFF7F8FA);

  // Controllers for all profile fields
  final TextEditingController _firstNameController = TextEditingController(text: "Maria");
  final TextEditingController _lastNameController = TextEditingController(text: "Santos");
  final TextEditingController _emailController = TextEditingController(text: "maria.santos@email.com");
  final TextEditingController _phoneController = TextEditingController(text: "+63 912 345 6789");
  final TextEditingController _addressController = TextEditingController(text: "123 Main Street, Quezon City, Metro Manila");
  final TextEditingController _statusController = TextEditingController(text: "Single");
  final TextEditingController _studentNumController = TextEditingController(text: "2017-00123");
  final TextEditingController _gradYearController = TextEditingController(text: "2021");
  final TextEditingController _degreeController = TextEditingController(text: "Bachelor of Science");
  final TextEditingController _majorController = TextEditingController(text: "Computer Science");

  @override
  void dispose() {
    // Clean up controllers
    for (var controller in [
      _firstNameController, _lastNameController, _emailController, 
      _phoneController, _addressController, _statusController,
      _studentNumController, _gradYearController, _degreeController, _majorController
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
              /// HEADER SECTION
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
                        _isEditing ? "Update your personal and academic details" : "View and manage your personal information",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                  _buildHeaderButton(),
                ],
              ),

              const SizedBox(height: 32),

              /// STATUS BANNER (Only visible in view mode)
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
                          const Text("Profile Complete", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          Text("All required information has been provided", style: TextStyle(fontSize: 13, color: Colors.green.shade700)),
                        ],
                      ),
                    ],
                  ),
                ),

              /// PERSONAL INFORMATION CARD
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

              /// ACADEMIC INFORMATION CARD
              _buildProfileSection(
                title: "Academic Information",
                icon: Icons.school_outlined,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildField("Student Number", _studentNumController, enabled: false)), // Usually read-only
                      const SizedBox(width: 24),
                      Expanded(child: _buildField("Graduation Year", _gradYearController, icon: Icons.calendar_today_outlined)),
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

  /// Toggle Button Logic
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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Perform save logic here
                setState(() => _isEditing = false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated Successfully")));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryMaroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Save Changes"),
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

  /// Section Card Wrapper
  Widget _buildProfileSection({required String title, required IconData icon, required List<Widget> children}) {
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

  /// Universal Field (Switches between Text and TextFormField)
  Widget _buildField(String label, TextEditingController controller, {IconData? icon, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: Colors.grey.shade700), const SizedBox(width: 6)],
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF2D2D2D))),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
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
                child: Text(controller.text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ),
      ],
    );
  }
}