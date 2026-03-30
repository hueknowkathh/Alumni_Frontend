import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'admin_dashboard.dart';
import 'alumni_list.dart';
import 'tracer_data.dart';
import 'pending_users.dart';
import 'announcements_page.dart';
import 'jobs_page.dart';
import 'settings_page.dart';
import 'recent_activity.dart';
import 'latest_registrations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
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
  static const int recentActivity = 6;
  static const int userRegistrationsPage = 7;

  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color accentGold = const Color(0xFFC5A046);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    if (UserStore.value == null) UserStore.set(widget.user);
    fetchFullActivity();
    fetchAllUsers();
    _dashboardRealtimeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchFullActivity(showLoader: false);
      fetchAllUsers(showLoader: false);
    });
  }

  Future<void> fetchFullActivity({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _isLoadingActivity = true);
    }

    try {
      final response = await http.get(
        ApiService.uri('get_full_activity.php'),
      );

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
      final response = await http.get(
        ApiService.uri('get_latest_reg.php'),
      );

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
    _notificationTimer?.cancel();
    _dashboardRealtimeTimer?.cancel();
    super.dispose();
  }

  void _showNotifications() async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final button =
        _notificationKey.currentContext!.findRenderObject() as RenderBox;
    final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;

    await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          buttonPosition.dx,
          buttonPosition.dy + buttonSize.height,
          buttonSize.width,
          buttonSize.height,
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          child: Container(
            width: 330,
            height: 360,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _allActivities.isEmpty
                      ? const Center(child: Text('No recent activity'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _allActivities.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final act = _allActivities[index];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: accentGold.withOpacity(0.2),
                                child: Icon(
                                  Icons.notifications,
                                  size: 18,
                                  color: primaryMaroon,
                                ),
                              ),
                              title: Text(
                                act['title'] ?? 'Update',
                                style: const TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                act['time'] ?? 'Just now',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
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

    final List<Widget> pages = [
      AdminDashboard(
        user: widget.user,
        onActionSelected: (index) => setState(() => _selectedIndex = index),
        onViewAll: fetchFullActivity,
        onViewAllUsers: fetchAllUsers,
      ),
      const AlumniList(),
      const TracerDataPage(),
      const PendingUsersPage(),
      const AnnouncementsPage(),
      const JobsPage(),
      const AdminSettings(),
      RecentActivityPage(
        activities: _allActivities,
        isLoading: _isLoadingActivity,
        onBack: () => setState(() => _selectedIndex = dashboard),
        onRefresh: fetchFullActivity,
      ),
      UserRegistrationsPage(
        users: _allUsers,
        isLoading: _isLoadingUsers,
        onBack: () => setState(() => _selectedIndex = dashboard),
        onRefresh: fetchAllUsers,
      ),
    ];

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
                  child: IndexedStack(index: _selectedIndex, children: pages),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
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
          const Spacer(),
          IconButton(
            key: _notificationKey,
            onPressed: _showNotifications,
            icon: Badge(
              label: Text(_allActivities.length.toString()),
              isLabelVisible: _allActivities.isNotEmpty,
              backgroundColor: accentGold,
              child: const Icon(
                Icons.notifications_none_outlined,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 20),
          CircleAvatar(
            backgroundColor: primaryMaroon,
            child: const Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
