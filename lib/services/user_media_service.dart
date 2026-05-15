import 'package:flutter/material.dart';

import 'api_service.dart';

class UserMediaService {
  UserMediaService._();

  static const String profilePhotoBucket = 'profile-photos';
  static const String alumniIdBucket = 'alumni-ids';

  static ImageProvider? profilePhotoProvider(Map<String, dynamic>? user) {
    final url = profilePhotoUrl(user);
    if (url == null) return null;
    return NetworkImage(url);
  }

  static String? profilePhotoUrl(Map<String, dynamic>? user) {
    final path = _firstValue(user, const [
      'profilePhotoPath',
      'profile_photo_path',
      'profilePhotoUrl',
      'profile_photo_url',
    ]);
    if (path.isEmpty) return null;
    if (_isAbsoluteUrl(path)) return path;
    return storageRedirectUrl(bucket: profilePhotoBucket, path: path);
  }

  static String? alumniIdUrl(Map<String, dynamic>? user) {
    final path = _firstValue(user, const [
      'alumniIdPath',
      'alumni_id_path',
      'alumniIdUrl',
      'alumni_id_url',
    ]);
    if (path.isEmpty) return null;
    if (_isAbsoluteUrl(path)) return path;
    return storageRedirectUrl(bucket: alumniIdBucket, path: path);
  }

  static String storageRedirectUrl({
    required String bucket,
    required String path,
  }) {
    return ApiService.uri('storage_redirect.php', queryParameters: {
      'bucket': bucket,
      'path': path,
    }).toString();
  }

  static String _firstValue(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return '';
    for (final key in keys) {
      final value = source[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static bool _isAbsoluteUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }
}
