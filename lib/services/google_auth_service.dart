import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';
import 'linkedin_popup_stub.dart'
    if (dart.library.html) 'linkedin_popup_web.dart';

class GoogleRegistrationPrefill {
  const GoogleRegistrationPrefill({
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.googleSub,
    this.emailVerified = true,
    this.source = 'google',
  });

  final String fullName;
  final String firstName;
  final String lastName;
  final String email;
  final String googleSub;
  final bool emailVerified;
  final String source;

  bool get hasImportedName =>
      fullName.trim().isNotEmpty ||
      firstName.trim().isNotEmpty ||
      lastName.trim().isNotEmpty;
}

class GoogleAuthResult {
  const GoogleAuthResult({
    required this.authFlow,
    required this.provider,
    required this.message,
    required this.error,
    required this.email,
    required this.prefill,
    required this.user,
  });

  final String authFlow;
  final String provider;
  final String message;
  final String error;
  final String email;
  final GoogleRegistrationPrefill? prefill;
  final Map<String, dynamic>? user;

  bool get isGoogleFlow =>
      provider == 'google' || authFlow.startsWith('google_');
  bool get isRegistrationPrefill =>
      authFlow == 'google_register' && prefill != null;
  bool get isLoginSuccess => authFlow == 'google_login_success' && user != null;
  bool get shouldOpenLoginPage =>
      isGoogleFlow && !isRegistrationPrefill && !isLoginSuccess;

  static GoogleAuthResult? fromUri(Uri uri) {
    final query = uri.queryParameters;
    final authFlow = (query['auth_flow'] ?? '').trim();
    final provider = (query['provider'] ?? '').trim();
    final hasGoogleSignal =
        authFlow.startsWith('google_') ||
        provider == 'google' ||
        query.containsKey('google_name') ||
        query.containsKey('google_first_name') ||
        query.containsKey('google_last_name') ||
        query.containsKey('google_sub') ||
        query.containsKey('google_error');

    if (!hasGoogleSignal) return null;

    var fullName = (query['google_name'] ?? query['name'] ?? '').trim();
    var firstName = (query['google_first_name'] ?? query['first_name'] ?? '')
        .trim();
    var lastName = (query['google_last_name'] ?? query['last_name'] ?? '')
        .trim();
    final email = (query['google_email'] ?? query['email'] ?? '').trim();
    final googleSub = (query['google_sub'] ?? query['sub'] ?? '').trim();
    final emailVerified =
        (query['google_email_verified'] ?? '1').trim().toLowerCase() != '0';

    if (fullName.isEmpty) {
      fullName = [
        firstName,
        lastName,
      ].where((part) => part.trim().isNotEmpty).join(' ').trim();
    }

    if (firstName.isEmpty && lastName.isEmpty && fullName.isNotEmpty) {
      final parts = fullName.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        firstName = parts.first;
        if (parts.length > 1) {
          lastName = parts.sublist(1).join(' ');
        }
      }
    }

    final prefill = authFlow == 'google_register'
        ? GoogleRegistrationPrefill(
            fullName: fullName,
            firstName: firstName,
            lastName: lastName,
            email: email,
            googleSub: googleSub,
            emailVerified: emailVerified,
          )
        : null;

    final user = authFlow == 'google_login_success'
        ? _buildUserSession(query)
        : null;

    return GoogleAuthResult(
      authFlow: authFlow,
      provider: provider,
      message: (query['google_message'] ?? '').trim(),
      error: (query['google_error'] ?? '').trim(),
      email: email,
      prefill: prefill,
      user: user,
    );
  }

  static Map<String, dynamic>? _buildUserSession(Map<String, String> query) {
    final id = int.tryParse((query['google_user_id'] ?? '').trim());
    final role = (query['google_role'] ?? '').trim();
    final name = (query['google_user_name'] ?? query['google_name'] ?? '')
        .trim();
    final email = (query['google_user_email'] ?? query['google_email'] ?? '')
        .trim();

    if (id == null || role.isEmpty || name.isEmpty || email.isEmpty) {
      return null;
    }

    bool parseBool(String key, {bool fallback = false}) {
      final value = (query[key] ?? '').trim().toLowerCase();
      if (value == '1' || value == 'true') return true;
      if (value == '0' || value == 'false') return false;
      return fallback;
    }

    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'accountStatus': (query['google_status'] ?? '').trim(),
      'program': (query['google_program'] ?? '').trim(),
      'year_graduated': (query['google_year_graduated'] ?? '').trim(),
      'graduation_year': (query['google_year_graduated'] ?? '').trim(),
      'gradYear': (query['google_year_graduated'] ?? '').trim(),
      'firstName': (query['google_first_name'] ?? '').trim(),
      'first_name': (query['google_first_name'] ?? '').trim(),
      'lastName': (query['google_last_name'] ?? '').trim(),
      'last_name': (query['google_last_name'] ?? '').trim(),
      'phone': (query['google_phone'] ?? '').trim(),
      'address': (query['google_address'] ?? '').trim(),
      'civilStatus': (query['google_civil_status'] ?? '').trim(),
      'civil_status': (query['google_civil_status'] ?? '').trim(),
      'alumniNumber': (query['google_alumni_number'] ?? '').trim(),
      'alumni_number': (query['google_alumni_number'] ?? '').trim(),
      'studentNumber': (query['google_student_number'] ?? '').trim(),
      'student_number': (query['google_student_number'] ?? '').trim(),
      'degree': (query['google_degree'] ?? '').trim(),
      'major': (query['google_major'] ?? '').trim(),
      'emailAnnouncements': parseBool(
        'google_email_announcements',
        fallback: true,
      ),
      'email_announcements': parseBool(
        'google_email_announcements',
        fallback: true,
      ),
      'emailReminders': parseBool('google_email_reminders', fallback: true),
      'email_reminders': parseBool('google_email_reminders', fallback: true),
      'jobEmailUpdates': parseBool('google_job_email_updates', fallback: true),
      'job_email_updates': parseBool(
        'google_job_email_updates',
        fallback: true,
      ),
      'eventInvitations': parseBool('google_event_invitations'),
      'event_invitations': parseBool('google_event_invitations'),
      'google_sub': (query['google_sub'] ?? '').trim(),
      'google_email': (query['google_email'] ?? '').trim(),
      'google_email_verified': parseBool(
        'google_email_verified',
        fallback: true,
      ),
      'auth_provider': 'google',
      'access_token': (query['google_access_token'] ?? '').trim(),
      'expires_at': (query['google_expires_at'] ?? '').trim(),
      'last_login_at': (query['google_last_login_at'] ?? '').trim(),
    };
  }
}

class GoogleAuthService {
  static GoogleAuthResult? currentResult() {
    return GoogleAuthResult.fromUri(Uri.base);
  }

  static String appRedirectBase() {
    return Uri.base.origin.endsWith('/')
        ? Uri.base.origin
        : '${Uri.base.origin}/';
  }

  static Uri registrationStartUri() {
    return ApiService.uri(
      'google_start.php',
      queryParameters: {
        'flow': 'register',
        'provider': 'google',
        'app_redirect': appRedirectBase(),
        if (kIsWeb) 'popup': '1',
      },
    );
  }

  static Uri linkAccountStartUri({required int userId}) {
    return ApiService.uri(
      'google_start.php',
      queryParameters: {
        'flow': 'link',
        'provider': 'google',
        'user_id': '$userId',
        'app_redirect': appRedirectBase(),
        if (kIsWeb) 'popup': '1',
      },
    );
  }

  static Future<bool> startRegistration() {
    return _launchGoogleUri(registrationStartUri());
  }

  static Future<bool> startAccountLink({required int userId}) {
    return _launchGoogleUri(linkAccountStartUri(userId: userId));
  }

  static Future<bool> _launchGoogleUri(Uri uri) async {
    if (kIsWeb) {
      final opened = await openLinkedInPopup(uri.toString());
      if (opened) return true;
    }
    return launchUrl(uri);
  }
}
