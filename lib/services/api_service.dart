import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Centralized API URL builder for the PHP backend.
///
/// Default base URL behavior:
/// - Web: `http://localhost/alumni_php`
/// - Android emulator: `http://10.0.2.2/alumni_php`
/// - Everything else (iOS simulator, desktop): `http://localhost/alumni_php`
///
/// Override at build/run time with:
/// `--dart-define=API_BASE_URL=http://<host>/alumni_php`
class ApiService {
  static const String _apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final defined = _apiBaseUrlDefine.trim();
    if (defined.isNotEmpty) return _normalizeBaseUrl(defined);

    if (kIsWeb) return 'http://localhost/alumni_php';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/alumni_php';
    }
    return 'http://localhost/alumni_php';
  }

  static Uri uri(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) {
    final base = baseUrl;
    final normalizedEndpoint = endpoint.replaceFirst(RegExp(r'^/+'), '');
    final url = '$base/$normalizedEndpoint';
    return Uri.parse(url).replace(
      queryParameters: queryParameters?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed.replaceAll(RegExp(r'/+$'), '');
  }
}
