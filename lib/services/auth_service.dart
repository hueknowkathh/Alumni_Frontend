import 'package:flutter/material.dart';
import '../screens/landing_page.dart';
import '../screens/ADMIN/admin_main_layout.dart';
import '../screens/ALUMNI/alumni_main_layout.dart';
import '../screens/DEAN/dean_main_layout.dart';
import 'activity_service.dart';
import '../state/user_store.dart';

class AuthService {
  static Future<Map<String, dynamic>?> restoreSession() {
    return UserStore.restorePersisted();
  }

  static Future<void> storeSession(Map<String, dynamic> user) {
    return UserStore.setAndPersist(user);
  }

  static Widget homeForUser(Map<String, dynamic> user) {
    final role = (user['role'] ?? 'alumni').toString().toLowerCase();
    if (role == 'admin') {
      return AdminMainLayout(user: user);
    }
    if (role == 'dean') {
      return DeanMainLayout(user: user);
    }
    return AlumniMainLayout(user: user);
  }

  /// Centralized logout function that all user roles use
  static Future<void> logout(BuildContext context) async {
    if (!context.mounted) return;

    bool? confirmLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (dialogContext) {
        final width = MediaQuery.of(dialogContext).size.width;
        final isCompact = width < 520;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 18 : 28,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFFBF7),
                    Color(0xFFF7EFF2),
                    Color(0xFFFFFCFA),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFF4A152C).withValues(alpha: 0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A152C).withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 18 : 22,
                      isCompact ? 18 : 22,
                      isCompact ? 18 : 22,
                      isCompact ? 16 : 18,
                    ),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF5A1832),
                          Color(0xFF6A2A43),
                          Color(0xFF35101E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.14),
                                Colors.white.withValues(alpha: 0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: const Color(0xFFC5A046).withValues(
                                alpha: 0.34,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFC5A046),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: const Text(
                                  'SESSION EXIT',
                                  style: TextStyle(
                                    color: Color(0xFFF4D88A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Logout from portal?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  height: 1.05,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 18 : 22,
                      16,
                      isCompact ? 18 : 22,
                      isCompact ? 18 : 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCompact)
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF4A152C),
                                    side: const BorderSide(
                                      color: Color(0xFFD8C2CA),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Stay Logged In',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A152C),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: const Icon(Icons.logout_rounded, size: 18),
                                  label: const Text(
                                    'Logout Now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF4A152C),
                                  side: const BorderSide(
                                    color: Color(0xFFD8C2CA),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Stay Logged In',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A152C),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.logout_rounded, size: 18),
                                label: const Text(
                                  'Logout Now',
                                  style: TextStyle(fontWeight: FontWeight.w700),
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
        );
      },
    );

    if (!context.mounted) return;

    if (confirmLogout ?? false) {
      final currentUser = UserStore.value;
      await ActivityService.logImportantFlow(
        action: 'logout',
        title: '${currentUser?['name'] ?? 'A user'} logged out of the portal',
        type: 'Authentication',
        userId: int.tryParse(
          (currentUser?['id'] ?? currentUser?['user_id'] ?? '').toString(),
        ),
        userName: currentUser?['name']?.toString(),
        userEmail: currentUser?['email']?.toString(),
        role: currentUser?['role']?.toString(),
      );
      if (!context.mounted) return;
      await UserStore.clearPersisted();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingPage()),
        (route) => false,
      );
    }
  }
}
