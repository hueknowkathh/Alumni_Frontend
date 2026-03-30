import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class Sidebar extends StatefulWidget {
  final String role;
  final int selectedIndex;
  final Function(int)? onItemSelected;
  final bool isCollapsed;
  final VoidCallback? onToggleSidebar;
  final bool isInDrawer;

  const Sidebar({
    super.key,
    required this.role,
    this.selectedIndex = 0,
    this.onItemSelected,
    this.isCollapsed = false,
    this.onToggleSidebar,
    this.isInDrawer = false,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isCollapsed;
  }

  @override
  void didUpdateWidget(Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isCollapsed = widget.isCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    const Color sidebarBg = Color(0xFF4A152C); // Deep Maroon
    const Color activeGold = Color.fromARGB(
      255,
      255,
      183,
      0,
    ); // Yellow highlight
    const Color inactiveText = Colors.white70;

    final List<Map<String, dynamic>> menuItems = _getMenuItems(widget.role);

    // Responsive width based on collapse state and screen size
    double sidebarWidth = _isCollapsed ? 80 : 280;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: sidebarWidth,
      color: sidebarBg,
      child: Column(
        children: [
          // HEADER WITH TOGGLE
          Padding(
            padding: EdgeInsets.fromLTRB(
              _isCollapsed ? 8 : 12,
              24,
              _isCollapsed ? 8 : 12,
              10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_isCollapsed)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.admin_panel_settings,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _getRoleHeader(widget.role),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Tooltip(
                        message: _getRoleHeader(widget.role),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    // Toggle Button - Always visible and clickable
                    GestureDetector(
                      onTap: () {
                        if (widget.isInDrawer) {
                          // If in drawer, close the drawer
                          Navigator.of(context).pop();
                        } else {
                          // Otherwise, toggle collapse
                          setState(() => _isCollapsed = !_isCollapsed);
                          widget.onToggleSidebar?.call();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Tooltip(
                          message: widget.isInDrawer
                              ? "Close Menu"
                              : (_isCollapsed
                                    ? "Expand Sidebar"
                                    : "Collapse Sidebar"),
                          child: Icon(
                            widget.isInDrawer
                                ? Icons.close
                                : (_isCollapsed
                                      ? Icons.menu_open_outlined
                                      : Icons.menu_rounded),
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 0),
                    child: Text(
                      "Alumni Management",
                      style: TextStyle(color: inactiveText, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: Colors.white10),
                  const SizedBox(height: 4),
                  Container(
                    height: 1,
                    width: 80,
                    color: activeGold.withValues(alpha: 0.2),
                  ),
                ] else
                  const SizedBox(height: 12),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // MENU ITEMS
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < menuItems.length; i++)
                    _customTile(
                      context,
                      menuItems[i]['title'],
                      menuItems[i]['icon'],
                      i,
                      isActive: i == widget.selectedIndex,
                      activeColor: activeGold,
                      isCollapsed: _isCollapsed,
                    ),
                  SizedBox(height: _isCollapsed ? 8 : 16),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isCollapsed ? 8 : 4,
                    ),
                    child: Divider(
                      color: Colors.white24,
                      height: _isCollapsed ? 8 : 16,
                    ),
                  ),
                  SizedBox(height: _isCollapsed ? 8 : 16),
                  _customTile(
                    context,
                    "Logout",
                    Icons.logout,
                    -1,
                    isLogout: true,
                    isCollapsed: _isCollapsed,
                  ),
                ],
              ),
            ),
          ),

          // FOOTER
          if (!_isCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Academic Year",
                      style: TextStyle(color: inactiveText, fontSize: 10),
                    ),
                    Text(
                      "2025-2026",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Tooltip(
                message: "2025-2026",
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.calendar_month,
                      color: Colors.white54,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getRoleHeader(String role) {
    switch (role.toLowerCase()) {
      case "admin":
        return "System Admin";
      case "dean":
        return "Department Dean";
      case "alumni":
        return "Alumni Member";
      default:
        return "Welcome";
    }
  }

  List<Map<String, dynamic>> _getMenuItems(String role) {
    switch (role.toLowerCase()) {
      case "admin":
        return [
          {'title': 'Dashboard', 'icon': Icons.grid_view_outlined},
          {'title': 'Alumni Data', 'icon': Icons.people_outline},
          {'title': 'Tracer Submissions', 'icon': Icons.bar_chart},
          {'title': 'Verify Users', 'icon': Icons.campaign_outlined},
          {'title': 'Announcements', 'icon': Icons.campaign_outlined},
          {'title': 'Jobs', 'icon': Icons.work_outline},
          {'title': 'Settings', 'icon': Icons.settings_outlined},
        ];
      case "dean":
        return [
          {'title': 'Dashboard', 'icon': Icons.grid_view_outlined},
          {'title': 'Department Alumni', 'icon': Icons.people_outline},
          {'title': 'Career Reports', 'icon': Icons.work_outline},
          {'title': 'Career Overview', 'icon': Icons.analytics_outlined},
          {'title': 'Announcements', 'icon': Icons.campaign_outlined},
          {'title': 'Settings', 'icon': Icons.settings_outlined},
        ];
      case "alumni":
        return [
          {'title': 'Dashboard', 'icon': Icons.grid_view_outlined},
          {'title': 'Profile', 'icon': Icons.person_outline},
          {'title': 'Announcements', 'icon': Icons.campaign_outlined},
          {'title': 'Jobs', 'icon': Icons.work_outline},
          {'title': 'Settings', 'icon': Icons.settings_outlined},
        ];
      default:
        return [];
    }
  }

  Widget _customTile(
    BuildContext context,
    String title,
    IconData icon,
    int index, {
    bool isActive = false,
    Color? activeColor,
    bool isLogout = false,
    bool isCollapsed = false,
  }) {
    // Collapsed version with center-aligned icon
    if (isCollapsed) {
      return Tooltip(
        message: title,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor?.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                if (isLogout) {
                  await AuthService.logout(context);
                  return;
                }

                if (widget.onItemSelected != null && index >= 0) {
                  widget.onItemSelected!(index);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 0,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isActive ? Colors.white : Colors.white70,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Expanded version with full text
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor?.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (isLogout) {
              await AuthService.logout(context);
              return;
            }

            if (widget.onItemSelected != null && index >= 0) {
              widget.onItemSelected!(index);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
