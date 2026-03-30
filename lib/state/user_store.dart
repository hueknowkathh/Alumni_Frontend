import 'dart:collection';

import 'package:flutter/foundation.dart';

/// In-memory user state for the currently logged-in session.
///
/// This is intentionally lightweight (no extra deps like Provider) and helps
/// the UI reflect profile changes immediately without requiring a full re-login.
class UserStore {
  UserStore._();

  static final ValueNotifier<Map<String, dynamic>?> currentUser =
      ValueNotifier<Map<String, dynamic>?>(null);

  static Map<String, dynamic>? get value => currentUser.value;

  static void set(Map<String, dynamic>? user) {
    if (user == null) {
      currentUser.value = null;
      return;
    }

    // Defensive copy to avoid accidental external mutation.
    currentUser.value = UnmodifiableMapView(Map<String, dynamic>.from(user));
  }

  static void patch(Map<String, dynamic> fields) {
    final existing = currentUser.value;
    if (existing == null) {
      set(fields);
      return;
    }

    final merged = Map<String, dynamic>.from(existing)..addAll(fields);
    currentUser.value = UnmodifiableMapView(merged);
  }

  static void clear() => set(null);
}

