import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color accentGold = const Color(0xFFC5A046);

  final _formKey = GlobalKey<FormState>();
  
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  String? selectedProgram;
  String? selectedYear;
  bool isLoading = false;

  final List<String> programs = ['BSIT', 'BSSW',];
  final List<String> years = List.generate(10, (index) => (2026 - index).toString());

  Future<void> _handleRegister() async {

  if (_formKey.currentState!.validate()) {

    // ✅ ADD THIS (password check)
    if (passwordController.text != confirmPasswordController.text) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => isLoading = true);

    final url = Uri.parse("http://localhost/alumni_php/register.php");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text,
          "email": emailController.text,
          "password": passwordController.text,
          "program": selectedProgram,
          "year_graduated": selectedYear,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        _showSuccess();
      } else {
        // ✅ OPTIONAL IMPROVEMENT (shows backend message)
        _showError(data['message'] ?? "Registration failed");
      }
    } catch (e) {
      _showError("Connection error");
    }

    setState(() => isLoading = false);
  }
}

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Account created. Wait for admin approval."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // go back to login
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/download.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.4)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Container(
                width: 500,
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: primaryMaroon.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 15)],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Icon(Icons.person_add, color: Colors.white, size: 50),
                      const SizedBox(height: 10),
                      const Text(
                        "Alumni Registration",
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "Enter your details to join the Tracer System",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 30),
                      _buildLabel("Account Information"),
                      _buildTextField(nameController, "Full Name", Icons.person),
                      const SizedBox(height: 15),
                      _buildTextField(emailController, "Email", Icons.email),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(passwordController, "Password", Icons.lock, isPass: true)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(confirmPasswordController, "Confirm", Icons.lock_clock, isPass: true)),
                        ],
                      ),
                      const SizedBox(height: 25),
                      _buildLabel("Academic Background"),
                      _buildDropdown("Select Program", programs, (val) => setState(() => selectedProgram = val)),
                      const SizedBox(height: 15),
                      _buildDropdown("Year Graduated", years, (val) => setState(() => selectedYear = val)),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentGold,
                            foregroundColor: primaryMaroon,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : const Text("REGISTER", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Already have an account? Login", style: TextStyle(color: accentGold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: TextStyle(color: accentGold, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPass = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white70, size: 18),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: accentGold)),
        filled: true,
        fillColor: Colors.white10,
      ),
      validator: (val) => val!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildDropdown(String hint, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      dropdownColor: primaryMaroon,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        filled: true,
        fillColor: Colors.white10,
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? "Required" : null,
    );
  }
}