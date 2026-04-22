import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_screen.dart';
import '../services/activity_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/linkedin_auth_service.dart';
import '../utils/email_validator.dart';
import '../utils/password_policy.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.linkedInResult});

  final LinkedInAuthResult? linkedInResult;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color accentGold = const Color(0xFFC5A046);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isLinkedInLoading = false;

  @override
  void initState() {
    super.initState();
    final linkedInEmail = widget.linkedInResult?.email.trim() ?? '';
    if (linkedInEmail.isNotEmpty) {
      _emailController.text = linkedInEmail;
    }
  }

  Future<void> _handleLogin() async {
    final emailError = EmailValidator.validate(_emailController.text);
    if (emailError != null) {
      _showError(emailError);
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showError("Password is required.");
      return;
    }

    setState(() => _isLoading = true);
    final url = ApiService.uri('login.php');

    try {
      final response = await http.post(
        url,
        headers: ApiService.jsonHeaders(),
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(response.body);
        data = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      } catch (_) {
        final snippet = response.body.trim();
        _showError(
          "Server returned an invalid response (${response.statusCode})."
          "${snippet.isNotEmpty ? "\n\n$snippet" : ""}",
        );
        return;
      }

      if (response.statusCode == 200 &&
          data['status'] == 'success' &&
          data['user'] != null) {
        final user = Map<String, dynamic>.from(data['user']);
        final accessToken = (data['access_token'] ?? data['token'] ?? '')
            .toString()
            .trim();
        final expiresAt = (data['expires_at'] ?? '').toString().trim();
        if (accessToken.isNotEmpty) {
          user['access_token'] = accessToken;
        }
        if (expiresAt.isNotEmpty) {
          user['expires_at'] = expiresAt;
        }
        final role = (user['role'] ?? 'alumni').toString().toLowerCase();
        await AuthService.storeSession(user);
        await ActivityService.logImportantFlow(
          action: 'login',
          title: '${user['name'] ?? 'A user'} logged in',
          type: 'Authentication',
          userId: int.tryParse(
            (user['id'] ?? user['user_id'] ?? '').toString(),
          ),
          userName: user['name']?.toString(),
          userEmail: user['email']?.toString(),
          role: role,
        );
        _navigateTo(role, user);
      } else {
        _showError(
          data['message']?.toString() ??
              (response.statusCode == 200
                  ? "Unable to sign in with the provided credentials."
                  : "Server Error: ${response.statusCode}"),
        );
      }
    } catch (e) {
      _showError("Check your internet or server connection.");
      debugPrint("Login error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateTo(String role, Map<String, dynamic> user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AuthService.homeForUser(user)),
    );
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

  Future<Map<String, dynamic>> _requestForgotPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        ApiService.uri('forgot_password.php'),
        headers: ApiService.jsonHeaders(),
        body: jsonEncode({"email": email.trim(), "newPassword": newPassword}),
      );

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
      return {
        'ok': response.statusCode == 200,
        'message':
            data['message']?.toString() ??
            (response.statusCode == 200
                ? "Password reset successful."
                : "Unable to reset password."),
      };
    } catch (e) {
      debugPrint("Forgot password error: $e");
      return {'ok': false, 'message': 'Unable to reset password right now.'};
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isPasswordVisible = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogInnerContext, setDialogState) => AlertDialog(
          title: const Text("Forgot Password"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (value) => EmailValidator.validate(value ?? ''),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () => setDialogState(
                        () => isPasswordVisible = !isPasswordVisible,
                      ),
                    ),
                  ),
                  validator: (value) => PasswordPolicy.validate(
                    value ?? '',
                    fieldLabel: 'New password',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: !isPasswordVisible,
                  decoration: const InputDecoration(
                    labelText: "Confirm New Password",
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Confirm password is required.';
                    }
                    if (value != newPasswordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isSubmitting = true);
                      final result = await _requestForgotPassword(
                        email: emailController.text,
                        newPassword: newPasswordController.text,
                      );
                      if (!mounted) return;
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(
                            result['ok'] == true
                                ? "Password Reset"
                                : "Reset Failed",
                          ),
                          content: Text(
                            result['message']?.toString() ??
                                'Unable to reset password.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Reset Password"),
            ),
          ],
        ),
      ),
    ).then((_) {
      emailController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  Future<void> _startLinkedInSignUp() async {
    setState(() => _isLinkedInLoading = true);
    try {
      final launched = await LinkedInAuthService.startRegistration();
      if (!launched && mounted) {
        _showError(
          "LinkedIn sign-up could not be started. Please verify your backend LinkedIn endpoint first.",
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(
          "LinkedIn sign-up is not ready yet. Please configure the LinkedIn developer app and backend callback first.",
        );
      }
      debugPrint("LinkedIn sign-up error: $e");
    } finally {
      if (mounted) setState(() => _isLinkedInLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isCompact = screenWidth < 420;
    final cardWidth = screenWidth < 480 ? screenWidth - 28 : 430.0;
    final logoSize = screenHeight < 700
        ? (isCompact ? 82.0 : 94.0)
        : screenHeight < 820
        ? (isCompact ? 92.0 : 108.0)
        : (isCompact ? 104.0 : 124.0);
    final logoOverlap = logoSize * 0.46;
    final cardTopPadding = logoSize * 0.56 + (isCompact ? 20.0 : 24.0);
    final titleFontSize = screenHeight < 700
        ? (isCompact ? 31.0 : 38.0)
        : screenHeight < 820
        ? (isCompact ? 34.0 : 42.0)
        : (isCompact ? 38.0 : 48.0);
    final pageTopPadding = screenHeight < 700
        ? 28.0
        : screenHeight < 820
        ? (isCompact ? 34.0 : 46.0)
        : (isCompact ? 40.0 : 58.0);
    final pageBottomPadding = screenHeight < 700 ? 24.0 : 32.0;
    final linkedInMessage = widget.linkedInResult?.message.trim() ?? '';
    final linkedInError = widget.linkedInResult?.error.trim() ?? '';
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
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: EdgeInsets.fromLTRB(
                            isCompact ? 22 : 28,
                            cardTopPadding,
                            isCompact ? 22 : 28,
                            28,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 8),
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
                                  "Welcome Back",
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
                              const SizedBox(height: 10),
                              Container(
                                width: 88,
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
                              const SizedBox(height: 14),
                              Text(
                                "Sign in to access your alumni dashboard",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: isCompact ? 14 : 14.5,
                                  height: 1.45,
                                ),
                              ),
                              if (linkedInMessage.isNotEmpty ||
                                  linkedInError.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: linkedInError.isNotEmpty
                                          ? Colors.orangeAccent.withValues(
                                              alpha: 0.42,
                                            )
                                          : accentGold.withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Text(
                                    linkedInMessage.isNotEmpty
                                        ? linkedInMessage
                                        : "LinkedIn sign-in could not be completed. Please try again.",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              _buildTextField(
                                controller: _emailController,
                                label: "Email",
                                icon: Icons.person_rounded,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _passwordController,
                                label: "Password",
                                icon: Icons.lock_rounded,
                                isPassword: true,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _showForgotPasswordDialog,
                                  child: Text(
                                    "Forgot password?",
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 60,
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
                                    onPressed: _isLoading ? null : _handleLogin,
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
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            "SIGN IN",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.white.withValues(
                                              alpha: 0.18,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            "ALUMNI SIGN-UP",
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.72,
                                              ),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.white.withValues(
                                              alpha: 0.18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: OutlinedButton(
                                        onPressed: _isLinkedInLoading
                                            ? null
                                            : _startLinkedInSignUp,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: BorderSide(
                                            color: Colors.white.withValues(
                                              alpha: 0.24,
                                            ),
                                          ),
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.08),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (_isLinkedInLoading)
                                              const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            else
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF0A66C2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                alignment: Alignment.center,
                                                child: const Text(
                                                  "in",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 12),
                                            Flexible(
                                              child: Text(
                                                _isLinkedInLoading
                                                    ? "Starting LinkedIn..."
                                                    : "Continue with LinkedIn",
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          "New Alumni User?",
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.72,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const RegisterPage(),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            "Register here",
                                            style: TextStyle(
                                              color: accentGold,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.72),
          fontSize: 13,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 10, right: 6),
          child: Icon(
            icon,
            color: accentGold.withValues(alpha: 0.92),
            size: 21,
          ),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: accentGold.withValues(alpha: 0.92),
            width: 1.6,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.10),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 22,
        ),
      ),
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
