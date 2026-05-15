import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'admin_dashboard.dart';
import 'alumni_list.dart';
import 'graduate_registry_page.dart';
import 'tracer_data.dart';
import 'pending_users.dart';
import 'announcements_page.dart';
import 'jobs_page.dart';
import 'programs_page.dart';
import 'settings_page.dart';
import 'latest_registrations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import '../../services/user_media_service.dart';
import '../../state/user_store.dart';

class AdminMainLayout extends StatefulWidget {
  final Map<String, dynamic> user;
  const AdminMainLayout({super.key, required this.user});

  @override
  State<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends State<AdminMainLayout> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  bool _hasInitializedLayout = false;

  List<dynamic> _allActivities = [];
  bool _isLoadingActivity = false;
  List<dynamic> _allUsers = [];
  bool _isLoadingUsers = false;

  final GlobalKey _notificationKey = GlobalKey();
  Timer? _notificationTimer;
  Timer? _dashboardRealtimeTimer;

  static const int dashboard = 0;

  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color accentGold = const Color(0xFFC5A046);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE0E0E0);
  late final List<Widget?> _pageCache;

  List<dynamic> get _adminNotifications {
    return _allActivities.where((activity) {
      final type = (activity['type'] ?? '').toString().toLowerCase();
      final action = (activity['action'] ?? '').toString().toLowerCase();
      final title = (activity['title'] ?? '').toString().toLowerCase();

      return type == 'registration' ||
          type == 'verification' ||
          type == 'tracer' ||
          action == 'tracer_submit' ||
          action == 'approve_user' ||
          action == 'reject_user' ||
          title.contains('submitted a registration request') ||
          title.contains('registered a new account') ||
          title.contains('submitted a tracer form');
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (UserStore.value == null) UserStore.set(widget.user);
    UserStore.currentUser.addListener(_handleUserChanged);
    _pageCache = List<Widget?>.filled(11, null);
    fetchFullActivity();
    fetchAllUsers();
    _dashboardRealtimeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchFullActivity(showLoader: false);
      fetchAllUsers(showLoader: false);
    });
  }

  Future<void> _openRecentActivityPage() async {
    await fetchFullActivity(showLoader: true);
    if (!mounted) return;
    setState(() => _selectedIndex = 9);
  }

  Future<void> fetchFullActivity({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _isLoadingActivity = true);
    }

    try {
      final response = await http.get(ApiService.uri('get_full_activity.php'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => _allActivities = json.decode(response.body));
      }
    } catch (e) {
      debugPrint("Activity Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingActivity = false);
      }
    }
  }

  Future<void> fetchAllUsers({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _isLoadingUsers = true);
    }

    try {
      final response = await http.get(ApiService.uri('get_latest_reg.php'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() => _allUsers = json.decode(response.body));
      }
    } catch (e) {
      debugPrint("Users Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  @override
  void dispose() {
    UserStore.currentUser.removeListener(_handleUserChanged);
    _notificationTimer?.cancel();
    _dashboardRealtimeTimer?.cancel();
    super.dispose();
  }

  void _handleUserChanged() {
    if (mounted) setState(() {});
  }

  void _showNotifications() async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final button =
        _notificationKey.currentContext!.findRenderObject() as RenderBox;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;
    final screenSize = overlay.size;
    final panelWidth = screenSize.width < 420 ? screenSize.width - 32 : 360.0;
    final left = (buttonPosition.dx + buttonSize.width - panelWidth)
        .clamp(16.0, screenSize.width - panelWidth - 16.0)
        .toDouble();
    final top = (buttonPosition.dy + buttonSize.height + 10)
        .clamp(16.0, screenSize.height - 420.0)
        .toDouble();

    await showGeneralDialog(
      context: context,
      barrierLabel: 'Notifications',
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: panelWidth,
                  constraints: BoxConstraints(
                    maxHeight: screenSize.height * 0.62,
                    minHeight: 220,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8DADF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Notifications',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Color(0xFF4A152C),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _adminNotifications.isEmpty
                            ? const Center(
                                child: Text(
                                  'No recent activity',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemCount: _adminNotifications.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final act = _adminNotifications[index];
                                  final title =
                                      act['title']?.toString() ?? 'Update';
                                  final time =
                                      act['time']?.toString() ?? 'Just now';

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    minVerticalPadding: 12,
                                    isThreeLine: true,
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: primaryMaroon.withValues(
                                          alpha: 0.9,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.notifications_outlined,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4A152C),
                                        height: 1.3,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        time,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 768;
    bool isTablet = screenWidth >= 768 && screenWidth < 1024;

    if (!_hasInitializedLayout) {
      _isSidebarCollapsed = isTablet;
      _hasInitializedLayout = true;
    }

    return Scaffold(
      backgroundColor: bgLight,
      drawer: isMobile
          ? Drawer(
              child: Sidebar(
                role: "admin",
                selectedIndex: _selectedIndex,
                isInDrawer: true,
                onItemSelected: (index) {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(
              role: "admin",
              selectedIndex: _selectedIndex,
              isCollapsed: _isSidebarCollapsed,
              onToggleSidebar: () =>
                  setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
              onItemSelected: (index) => setState(() => _selectedIndex = index),
            ),
          Expanded(
            child: Column(
              children: [
                _buildHeader(isMobile),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: List.generate(
                      _pageCache.length,
                      (index) =>
                          _pageCache[index] ??
                          (index == _selectedIndex
                              ? _pageCache[index] = _buildPage(index)
                              : const SizedBox.shrink()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return AdminDashboard(
          user: widget.user,
          onActionSelected: (target) => setState(() => _selectedIndex = target),
          onOpenRecentActivity: _openRecentActivityPage,
          onOpenLatestUsers: () => setState(() => _selectedIndex = 10),
        );
      case 1:
        return const AlumniList();
      case 2:
        return const GraduateRegistryPage();
      case 3:
        return const ProgramsPage();
      case 4:
        return const TracerDataPage();
      case 5:
        return const PendingUsersPage();
      case 6:
        return const AnnouncementsPage();
      case 7:
        return const JobsPage();
      case 8:
        return const AdminSettings();
      case 9:
        return RecentActivityPage(
          activities: _allActivities,
          isLoading: _isLoadingActivity,
          onBack: () => setState(() => _selectedIndex = dashboard),
          onRefresh: fetchFullActivity,
        );
      case 10:
        return UserRegistrationsPage(
          users: _allUsers,
          isLoading: _isLoadingUsers,
          onBack: () => setState(() => _selectedIndex = dashboard),
          onRefresh: fetchAllUsers,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeader(bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 640;
    final liveUser = UserStore.value ?? widget.user;
    final profilePhoto = UserMediaService.profilePhotoProvider(liveUser);
    return Container(
      height: isCompact ? 88 : 86,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF9F5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFE8E1E4))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          if (!isMobile)
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F1F4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE7DCE1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      color: primaryMaroon,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Monitor registrations, tracer activity, and system-wide updates from one polished workspace.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Spacer(),
          SizedBox(width: isCompact ? 8 : 12),
          IconButton(
            key: _notificationKey,
            onPressed: _showNotifications,
            icon: Badge(
              label: Text(_adminNotifications.length.toString()),
              isLabelVisible: _adminNotifications.isNotEmpty,
              backgroundColor: accentGold,
              child: Icon(
                Icons.notifications_none_outlined,
                color: primaryMaroon,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 8 : 20),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentGold, primaryMaroon.withValues(alpha: 0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              backgroundColor: primaryMaroon,
              backgroundImage: profilePhoto,
              child: profilePhoto == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
