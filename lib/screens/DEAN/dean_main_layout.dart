import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/content_service.dart';
import '../../services/user_media_service.dart';
import '../../state/user_store.dart';
import '../widgets/sidebar.dart';
import 'announcement_page.dart';
import 'career_overview.dart';
import 'career_reports.dart';
import 'dean_dashboard.dart';
import 'department_alumni.dart';
import 'settings_page.dart';

class DeanMainLayout extends StatefulWidget {
  final Map<String, dynamic> user;

  const DeanMainLayout({super.key, required this.user});

  @override
  State<DeanMainLayout> createState() => _DeanMainLayoutState();
}

class _DeanMainLayoutState extends State<DeanMainLayout> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  bool _hasInitializedLayout = false;
  final GlobalKey _notificationKey = GlobalKey();
  Timer? _notificationTimer;
  List<dynamic> _notifications = [];

  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color accentGold = const Color(0xFFC5A046);
  final Color bgLight = const Color(0xFFF7F8FA);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    if (UserStore.value == null) UserStore.set(widget.user);
    UserStore.currentUser.addListener(_handleUserChanged);
    _pages = [
      DeanDashboard(
        user: widget.user,
        onModuleSelected: (index) {
          if (!mounted) return;
          setState(() => _selectedIndex = index);
        },
      ),
      const DepartmentAlumniPage(),
      const CareerReportsPage(),
      const CareerOverviewPage(),
      const AnnouncementPage(),
      SettingsPage(user: widget.user),
    ];
    _fetchNotifications();
    _notificationTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _fetchNotifications();
    });
  }

  Future<void> _fetchNotifications() async {
    try {
      final announcements = await ContentService.fetchAnnouncements();
      if (!mounted) return;
      setState(() {
        _notifications = announcements.take(10).map((item) {
          return {
            'title': item['title']?.toString() ?? 'Announcement',
            'time': item['created_at']?.toString() ?? 'Just now',
            'type': item['category']?.toString() ?? 'Announcement',
            'description': item['description']?.toString() ?? '',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint("Notifications Error: $e");
    }
  }

  @override
  void dispose() {
    UserStore.currentUser.removeListener(_handleUserChanged);
    _notificationTimer?.cancel();
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
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _notifications.isEmpty
                            ? const Center(
                                child: Text(
                                  'No notifications yet',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: _notifications.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final note = _notifications[index];
                                  final type = note['type']?.toString() ?? '';
                                  final time =
                                      note['time']?.toString() ?? 'Just now';

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    minVerticalPadding: 10,
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
                                        Icons.announcement_outlined,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          note['title']?.toString() ?? 'Update',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF4A152C),
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          type.isNotEmpty
                                              ? '$type - $time'
                                              : time,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                            height: 1.25,
                                          ),
                                        ),
                                      ],
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    if (!_hasInitializedLayout) {
      _isSidebarCollapsed = isTablet;
      _hasInitializedLayout = true;
    }

    return Scaffold(
      backgroundColor: bgLight,
      drawer: isMobile
          ? Drawer(
              child: Sidebar(
                role: "dean",
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
              role: "dean",
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
                  child: IndexedStack(index: _selectedIndex, children: _pages),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
        border: const Border(bottom: BorderSide(color: Color(0xFFE8E1E4))),
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
          SizedBox(width: isCompact ? 8 : 12),
          if (!isMobile)
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
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
                      Icons.analytics_outlined,
                      color: primaryMaroon,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Review tracer trends, employment insights, and department records.",
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
          IconButton(
            key: _notificationKey,
            onPressed: _showNotifications,
            icon: Badge(
              label: Text(_notifications.length.toString()),
              isLabelVisible: _notifications.isNotEmpty,
              backgroundColor: accentGold,
              child: Icon(
                Icons.notifications_none_outlined,
                color: primaryMaroon,
              ),
            ),
          ),
          SizedBox(width: isCompact ? 8 : 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCompact)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      liveUser['name']?.toString() ?? "Dean",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: primaryMaroon,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      liveUser['role']?.toString() ?? "Dean",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              if (!isCompact) const SizedBox(width: 10),
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
                  radius: 18,
                  backgroundImage: profilePhoto,
                  child: profilePhoto == null
                      ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
