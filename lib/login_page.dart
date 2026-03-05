import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sign_up_page.dart'; 
import 'admin_main.dart'; 
import 'dean_main.dart'; 
import 'main.dart'; // Import to access MainShell (Alumni)

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String? errorMessage; 
  String? successMessage; 
  bool _isLoading = false;

  Future<void> _handleLogin() async {
  setState(() {
    errorMessage = null;
    successMessage = null;
  });

  String email = _emailController.text.trim();
  String password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    setState(() => errorMessage = "Please enter your email and password");
    return;
  }

  setState(() => _isLoading = true);

  try {
    final url = Uri.parse('http://localhost:8080/alumni_api/login.php');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    // Check if server returned success HTTP status
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        setState(() => successMessage = "Login Successful! Redirecting...");

        String dbRole = result['role'].toString().toLowerCase();
        String fullName = result['full_name'] ?? "User";
        String roleDisplay = result['role_display'] ?? "Alumni Member";
        String userEmail = result['email'] ?? email;

        await Future.delayed(const Duration(milliseconds: 1200));

        if (!mounted) return;

        if (email == "superuser@jmc.edu.ph" ||
            dbRole == "admin" ||
            dbRole == "superuser") {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminMainShell(
                adminName: fullName,
                adminRole: roleDisplay,
              ),
            ),
          );

        } else if (dbRole == "dean") {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DeanMainShell(
                deanName: fullName,
                deanRole: roleDisplay,
              ),
            ),
          );

        } else {

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainShell(
                userName: fullName,
                userRole: roleDisplay,
                userEmail: userEmail,
              ),
            ),
          );
        }

      } else {
        setState(() => errorMessage = result['message'] ?? "Login failed.");
      }

    } else {
      setState(() => errorMessage = "Server error: ${response.statusCode}");
    }

  } catch (e) {
    setState(() => errorMessage = "Connection failed. Check if XAMPP is running.");
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      setState(() => errorMessage = "Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color themeColor = Color(0xFF420031);

    return Scaffold(
      backgroundColor: themeColor,
      body: Stack(
        children: [
          ClipPath(
            clipper: BackgroundClipper(),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                image: DecorationImage(
                  image: AssetImage('assets/jmc.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          Positioned(
            left: 60,
            top: 40,
            child: Image.asset(
              'assets/logo.png',
              height: 150,
              width: 150,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
            ),
          ),
          Positioned(
            left: 60,
            top: 0,
            bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 180),
                _buildLargeText("HELLO", color: themeColor),
                _buildLargeText("WELCOME!", color: themeColor),
                _buildLargeText("USER", color: Colors.black), 
              ],
            ),
          ),
          Align(
            alignment: const Alignment(0.92, 0.0),
            child: Container(
              width: 550,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -70),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        shape: BoxShape.circle,
                        border: Border.all(color: themeColor, width: 5), 
                      ),
                      child: const CircleAvatar(
                        radius: 80, 
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 100, color: Color(0xFF4285F4)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (successMessage != null) _buildBanner(successMessage!, Colors.green),
                        if (errorMessage != null) _buildBanner(errorMessage!, Colors.red),
                        const Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.black)),
                        const SizedBox(height: 25),
                        _buildField(Icons.email_outlined, "Email Address", themeColor, controller: _emailController),
                        const SizedBox(height: 20),
                        _buildField(Icons.lock_outline, "Password", themeColor, isPass: true, controller: _passwordController),
                        const SizedBox(height: 15),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text("Forgot Password?", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        const SizedBox(height: 35),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: _isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("LOGIN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account? ", style: TextStyle(fontSize: 15)),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                                  );
                                },
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    color: themeColor, 
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 15,
                                    decoration: TextDecoration.underline
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 50),
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 245, 245, 245),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                    ),
                    child: Row(
                      children: [
                        const Text("Or login with", style: TextStyle(color: Colors.black54, fontSize: 16)),
                        const Spacer(),
                        _socialButton(FontAwesomeIcons.linkedin, "LinkedIn", themeColor, () => _launchURL('https://linkedin.com')),
                        const SizedBox(width: 20),
                        _socialButton(FontAwesomeIcons.google, "Google", themeColor, () => _launchURL('https://google.com')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPER METHODS ---
  Widget _buildBanner(String msg, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(color == Colors.green ? Icons.check_circle : Icons.error, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildLargeText(String text, {Color color = Colors.white}) {
    return Text(
      text,
      style: TextStyle(fontSize: 100, fontWeight: FontWeight.w900, color: color, height: 0.85, letterSpacing: -5),
    );
  }

  Widget _buildField(IconData icon, String hint, Color themeColor, {bool isPass = false, TextEditingController? controller}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        style: const TextStyle(fontSize: 18),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Icon(icon, color: themeColor, size: 24),
          ),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, String label, Color themeColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          FaIcon(icon, color: themeColor, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

class BackgroundClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.7, size.height);
    path.quadraticBezierTo(size.width * 0.9, size.height * 0.5, size.width * 0.6, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}