import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import '../services/activity_service.dart';
import '../services/api_service.dart';
import '../services/linkedin_auth_service.dart';
import '../utils/email_validator.dart';
import '../utils/password_policy.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.linkedInPrefill});

  final LinkedInRegistrationPrefill? linkedInPrefill;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color accentGold = const Color(0xFFC5A046);

  final _formKey = GlobalKey<FormState>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? selectedProgram;
  bool isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  final List<String> programs = ['BSIT', 'BSSW'];

  bool get _hasLinkedInPrefill =>
      widget.linkedInPrefill != null && widget.linkedInPrefill!.hasImportedName;

  @override
  void initState() {
    super.initState();
    final prefill = widget.linkedInPrefill;
    if (prefill != null) {
      firstNameController.text = prefill.firstName;
      lastNameController.text = prefill.lastName;
      if (prefill.email.isNotEmpty) {
        emailController.text = prefill.email;
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (passwordController.text != confirmPasswordController.text) {
        _showError("Passwords do not match.");
        return;
      }

      setState(() => isLoading = true);

      final url = ApiService.uri('register.php');

      try {
        final firstName = firstNameController.text.trim();
        final lastName = lastNameController.text.trim();
        final fullName = [
          firstName,
          lastName,
        ].where((part) => part.isNotEmpty).join(' ');

        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "name": fullName,
            "first_name": firstName,
            "last_name": lastName,
            "email": emailController.text,
            "password": passwordController.text,
            "program": selectedProgram,
            if (widget.linkedInPrefill != null) ...{
              "linkedin_sub": widget.linkedInPrefill!.linkedInSub,
              "linkedin_email": widget.linkedInPrefill!.email,
              "auth_provider": widget.linkedInPrefill!.source,
            },
          }),
        );

        Map<String, dynamic> data = <String, dynamic>{};
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) data = decoded;
        } catch (_) {
          _showError(
            "Server returned an invalid response (${response.statusCode}).",
          );
          return;
        }

        if (response.statusCode == 200 && data['status'] == 'success') {
          await ActivityService.logImportantFlow(
            action: 'register',
            title: '$fullName submitted a registration request',
            type: 'Registration',
            userName: fullName,
            userEmail: emailController.text.trim(),
            role: 'alumni',
            description: 'New alumni registration awaiting admin approval.',
            metadata: {'program': selectedProgram},
          );
          _showSuccess();
        } else {
          _showError(
            data['message']?.toString() ??
                (response.statusCode == 200
                    ? "Registration failed"
                    : "Server Error: ${response.statusCode}"),
          );
        }
      } catch (e) {
        _showError("Check your internet or server connection.");
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: const Text(
          "Account created. Wait for admin approval. Your alumni number will be assigned automatically.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isCompact = screenWidth < 420;
    final isSmallScreen = screenWidth < 560 || screenHeight < 760;
    final cardWidth = screenWidth < 560 ? screenWidth - 28 : 500.0;
    final stackPasswords = screenWidth < 560;
    final logoSize = screenHeight < 760
        ? (isCompact ? 78.0 : 90.0)
        : screenHeight < 900
        ? (isCompact ? 88.0 : 102.0)
        : (isCompact ? 98.0 : 116.0);
    final logoOverlap = logoSize * 0.44;
    final cardTopPadding = logoSize * 0.54 + (isCompact ? 18.0 : 22.0);
    final titleFontSize = screenHeight < 760
        ? (isCompact ? 28.0 : 35.0)
        : screenHeight < 900
        ? (isCompact ? 31.0 : 38.0)
        : (isCompact ? 34.0 : 42.0);
    final pageTopPadding = screenHeight < 760
        ? 26.0
        : screenHeight < 900
        ? (isCompact ? 32.0 : 44.0)
        : (isCompact ? 38.0 : 56.0);
    final pageBottomPadding = screenHeight < 760 ? 24.0 : 32.0;
    final horizontalPadding = isCompact ? 18.0 : 28.0;
    final cardRadius = isSmallScreen ? 28.0 : 32.0;
    final bodyTextFontSize = isCompact ? 13.0 : 14.5;
    final bodyTextHeight = isCompact ? 1.35 : 1.45;
    final noteFontSize = isCompact ? 10.5 : 11.5;
    final sectionGap = isSmallScreen ? 18.0 : 22.0;
    final fieldGap = isSmallScreen ? 12.0 : 16.0;
    final actionGap = isSmallScreen ? 22.0 : 28.0;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/loginpage_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryMaroon.withValues(alpha: 0.34),
                  Colors.black.withValues(alpha: 0.22),
                  primaryMaroon.withValues(alpha: 0.44),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentGold.withValues(alpha: 0.20),
                    accentGold.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -70,
            bottom: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                pageTopPadding,
                16,
                pageBottomPadding,
              ),
              child: SizedBox(
                width: cardWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(cardRadius),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            cardTopPadding,
                            horizontalPadding,
                            isSmallScreen ? 22.0 : 28.0,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(cardRadius),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.16),
                                primaryMaroon.withValues(alpha: 0.84),
                                primaryMaroon.withValues(alpha: 0.94),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.28),
                                blurRadius: 34,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(height: isSmallScreen ? 2.0 : 8.0),
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.98),
                                      const Color(0xFFF5DFA9),
                                      Colors.white.withValues(alpha: 0.96),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ).createShader(bounds),
                                  child: Text(
                                    "Join the Alumni Network",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: titleFontSize,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 0.6,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 8.0 : 10.0),
                                Container(
                                  width: isSmallScreen ? 72.0 : 96.0,
                                  height: 1.2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        accentGold.withValues(alpha: 0.88),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 10.0 : 14.0),
                                Text(
                                  "Create your alumni access and let the system complete your official batch details after approval.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: bodyTextFontSize,
                                    height: bodyTextHeight,
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 12.0 : 8.0),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 12.0 : 14.0,
                                    vertical: isSmallScreen ? 10.0 : 12.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentGold.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(
                                      isSmallScreen ? 16.0 : 18.0,
                                    ),
                                    border: Border.all(
                                      color: accentGold.withValues(alpha: 0.22),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.school_outlined,
                                        size: isSmallScreen ? 16.0 : 18.0,
                                        color: accentGold,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Your graduation year will be assigned from the official graduate list after admin approval.",
                                          style: TextStyle(
                                            color: accentGold,
                                            fontSize: noteFontSize,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_hasLinkedInPrefill) ...[
                                  SizedBox(height: isSmallScreen ? 14.0 : 18.0),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(
                                      isSmallScreen ? 12.0 : 14.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        isSmallScreen ? 16.0 : 18.0,
                                      ),
                                      border: Border.all(
                                        color: accentGold.withValues(
                                          alpha: 0.28,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.verified_outlined,
                                          color: accentGold,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Your name was imported from LinkedIn. Complete the remaining fields below to finish your alumni registration.",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize:
                                                  isSmallScreen ? 12.0 : 12.5,
                                              height: 1.45,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: sectionGap),
                                _buildLabel(
                                  "Account Information",
                                  isSmallScreen: isSmallScreen,
                                ),
                                if (stackPasswords) ...[
                                  _buildTextField(
                                    firstNameController,
                                    "First Name",
                                    Icons.person_outline,
                                    readOnly: _hasLinkedInPrefill,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: fieldGap),
                                  _buildTextField(
                                    lastNameController,
                                    "Last Name",
                                    Icons.badge_outlined,
                                    readOnly: _hasLinkedInPrefill,
                                    isSmallScreen: isSmallScreen,
                                  ),
                                ] else
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          firstNameController,
                                          "First Name",
                                          Icons.person_outline,
                                          readOnly: _hasLinkedInPrefill,
                                          isSmallScreen: isSmallScreen,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildTextField(
                                          lastNameController,
                                          "Last Name",
                                          Icons.badge_outlined,
                                          readOnly: _hasLinkedInPrefill,
                                          isSmallScreen: isSmallScreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                SizedBox(height: fieldGap),
                                _buildTextField(
                                  emailController,
                                  "Email",
                                  Icons.email_outlined,
                                  isSmallScreen: isSmallScreen,
                                ),
                                SizedBox(height: fieldGap),
                                if (stackPasswords) ...[
                                  _buildTextField(
                                    passwordController,
                                    "Password",
                                    Icons.lock_rounded,
                                    isPass: true,
                                    passwordVisible: _isPasswordVisible,
                                    onTogglePassword: () => setState(
                                      () => _isPasswordVisible =
                                          !_isPasswordVisible,
                                    ),
                                    isSmallScreen: isSmallScreen,
                                  ),
                                  SizedBox(height: fieldGap),
                                  _buildTextField(
                                    confirmPasswordController,
                                    "Confirm Password",
                                    Icons.lock_clock_rounded,
                                    isPass: true,
                                    passwordVisible: _isConfirmPasswordVisible,
                                    onTogglePassword: () => setState(
                                      () => _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible,
                                    ),
                                    isSmallScreen: isSmallScreen,
                                  ),
                                ] else
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          passwordController,
                                          "Password",
                                          Icons.lock_rounded,
                                          isPass: true,
                                          passwordVisible: _isPasswordVisible,
                                          onTogglePassword: () => setState(
                                            () => _isPasswordVisible =
                                                !_isPasswordVisible,
                                          ),
                                          isSmallScreen: isSmallScreen,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildTextField(
                                          confirmPasswordController,
                                          "Confirm Password",
                                          Icons.lock_clock_rounded,
                                          isPass: true,
                                          passwordVisible:
                                              _isConfirmPasswordVisible,
                                          onTogglePassword: () => setState(
                                            () => _isConfirmPasswordVisible =
                                                !_isConfirmPasswordVisible,
                                          ),
                                          isSmallScreen: isSmallScreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                SizedBox(height: sectionGap),
                                _buildLabel(
                                  "Academic Background",
                                  isSmallScreen: isSmallScreen,
                                ),
                                _buildDropdown(
                                  "Select Program",
                                  programs,
                                  (val) =>
                                      setState(() => selectedProgram = val),
                                  isSmallScreen: isSmallScreen,
                                ),
                                SizedBox(height: actionGap),
                                SizedBox(
                                  width: double.infinity,
                                  height: isSmallScreen ? 56.0 : 60.0,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentGold.withValues(
                                            alpha: 0.16,
                                          ),
                                          blurRadius: 22,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                      gradient: LinearGradient(
                                        colors: [
                                          accentGold.withValues(alpha: 0.98),
                                          const Color(0xFFD5B46B),
                                          const Color(0xFF8B6C2B),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : _handleRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: primaryMaroon,
                                        disabledBackgroundColor:
                                            Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _hasLinkedInPrefill
                                                  ? "COMPLETE REGISTRATION"
                                                  : "REGISTER",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize:
                                                    isSmallScreen ? 15.0 : 16.0,
                                                letterSpacing:
                                                    isSmallScreen ? 1.2 : 1.6,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 14.0 : 20.0),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    "Already have an account? Login",
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.76,
                                      ),
                                      fontSize: isSmallScreen ? 13.0 : 14.0,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -logoOverlap,
                      child: _buildShieldLogo(size: logoSize),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isSmallScreen = false}) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(bottom: isSmallScreen ? 8.0 : 10.0),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 8.0 : 10.0,
            height: isSmallScreen ? 8.0 : 10.0,
            decoration: BoxDecoration(
              color: accentGold,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentGold.withValues(alpha: 0.34),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 8.0 : 10.0),
          Text(
            text,
            style: TextStyle(
              color: accentGold,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 13.0 : 14.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPass = false,
    bool readOnly = false,
    bool isSmallScreen = false,
    bool passwordVisible = false,
    VoidCallback? onTogglePassword,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPass && !passwordVisible,
      readOnly: readOnly,
      style: TextStyle(
        color: Colors.white,
        fontSize: isSmallScreen ? 13.5 : 14.0,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.72),
          fontSize: isSmallScreen ? 12.5 : 13.0,
        ),
        prefixIcon: Container(
          margin: EdgeInsets.only(
            left: isSmallScreen ? 8.0 : 10.0,
            right: isSmallScreen ? 4.0 : 6.0,
          ),
          child: Icon(
            icon,
            color: accentGold.withValues(alpha: 0.92),
            size: isSmallScreen ? 19.0 : 21.0,
          ),
        ),
        suffixIcon: readOnly
            ? Icon(Icons.lock_outline, color: accentGold.withValues(alpha: 0.9))
            : isPass
                ? IconButton(
                    icon: Icon(
                      passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20.0 : 24.0),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20.0 : 24.0),
          borderSide: BorderSide(
            color: accentGold.withValues(alpha: 0.92),
            width: 1.6,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20.0 : 24.0),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        filled: true,
        fillColor: readOnly
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.10),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 18.0 : 22.0,
          vertical: isSmallScreen ? 18.0 : 22.0,
        ),
        errorMaxLines: 3,
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          height: 1.3,
        ),
      ),
      validator: (val) {
        final value = val ?? '';
        if (label == "Email") {
          return EmailValidator.validate(value);
        }
        if (label == "Password") {
          return PasswordPolicy.validate(value);
        }
        if (label == "Confirm Password") {
          if (value.trim().isEmpty) {
            return "Confirm password is required.";
          }
          if (value != passwordController.text) {
            return "Passwords do not match.";
          }
          return null;
        }
        if (value.trim().isEmpty) {
          return "$label is required.";
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(
    String hint,
    List<String> items,
    Function(String?) onChanged,
    {bool isSmallScreen = false,}
  ) {
    return DropdownButtonFormField<String>(
      dropdownColor: primaryMaroon,
      style: TextStyle(
        color: Colors.white,
        fontSize: isSmallScreen ? 13.5 : 14.0,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.60),
          fontSize: isSmallScreen ? 13.0 : 14.0,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20.0 : 24.0),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 20.0 : 24.0),
          borderSide: BorderSide(
            color: accentGold.withValues(alpha: 0.92),
            width: 1.6,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.10),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 18.0 : 22.0,
          vertical: isSmallScreen ? 18.0 : 22.0,
        ),
        errorMaxLines: 3,
        errorStyle: const TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          height: 1.3,
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? "$hint is required." : null,
    );
  }

  Widget _buildShieldLogo({required double size}) {
    final image = SizedBox(
      width: size,
      height: size,
      child: Image.asset('assets/jmclogo.png', fit: BoxFit.contain),
    );

    Widget outlinedLayer({
      required double dx,
      required double dy,
      required Color color,
      required double opacity,
      double scale = 1.0,
    }) {
      return Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcATop),
              child: image,
            ),
          ),
        ),
      );
    }

    final outerEdge = size * 0.02;
    final innerEdge = size * 0.009;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          outlinedLayer(
            dx: 0,
            dy: size * 0.05,
            color: Colors.black,
            opacity: 0.22,
            scale: 1.03,
          ),
          outlinedLayer(
            dx: -outerEdge,
            dy: 0,
            color: const Color(0xFFFFF4D7),
            opacity: 0.92,
            scale: 1.028,
          ),
          outlinedLayer(
            dx: outerEdge,
            dy: 0,
            color: const Color(0xFFFFF4D7),
            opacity: 0.92,
            scale: 1.028,
          ),
          outlinedLayer(
            dx: 0,
            dy: -outerEdge,
            color: const Color(0xFFFFF4D7),
            opacity: 0.92,
            scale: 1.028,
          ),
          outlinedLayer(
            dx: 0,
            dy: outerEdge,
            color: const Color(0xFFFFF4D7),
            opacity: 0.92,
            scale: 1.028,
          ),
          outlinedLayer(
            dx: -innerEdge,
            dy: -innerEdge,
            color: accentGold,
            opacity: 0.96,
            scale: 1.015,
          ),
          outlinedLayer(
            dx: innerEdge,
            dy: innerEdge,
            color: accentGold,
            opacity: 0.96,
            scale: 1.015,
          ),
          image,
        ],
      ),
    );
  }
}
