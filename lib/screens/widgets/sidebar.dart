import 'package:flutter/material.dart';
import '../login_screen.dart'; // Adjust path if needed

class Sidebar extends StatelessWidget {
  final String role;
  final int selectedIndex;
  final Function(int)? onItemSelected;

  const Sidebar({
    super.key,
    required this.role,
    this.selectedIndex = 0,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    const Color sidebarBg = Color(0xFF4A152C); // Deep Maroon
    const Color activeGold = Color.fromARGB(255, 255, 183, 0); // Yellow highlight
    const Color inactiveText = Colors.white70;

    final List<Map<String, dynamic>> menuItems = _getMenuItems(role);

    return Container(
      width: 280,
      color: sidebarBg,
      child: Column(
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      _getRoleHeader(role),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.only(left: 34.0),
                  child: Text("Alumni Management", style: TextStyle(color: inactiveText, fontSize: 12)),
                ),
                const SizedBox(height: 20),
                Container(height: 1, color: Colors.white10),
                const SizedBox(height: 4),
                Container(height: 1, width: 80, color: activeGold.withOpacity(0.2)),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // MENU ITEMS
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  for (int i = 0; i < menuItems.length; i++)
                    _customTile(
                      context,
                      menuItems[i]['title'],
                      menuItems[i]['icon'],
                      i,
                      isActive: i == selectedIndex,
                      activeColor: activeGold,
                    ),
                  const Divider(color: Colors.white24, height: 32),
                  _customTile(context, "Logout", Icons.logout, -1, isLogout: true),
                ],
              ),
            ),
          ),

          // FOOTER
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Academic Year", style: TextStyle(color: inactiveText, fontSize: 10)),
                  Text("2025-2026", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
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
          {'title': 'Tracer Form', 'icon': Icons.assignment_outlined},
          {'title': 'Announcements', 'icon': Icons.campaign_outlined},
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
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? activeColor?.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.white70),
        title: Text(
          title,
          style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
        ),
        onTap: () async {
          if (isLogout) {
            bool? confirmLogout = await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Confirm Logout"),
                content: const Text("Are you sure you want to logout?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Logout"),
                  ),
                ],
              ),
            );

            if (confirmLogout ?? false) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            }
            return;
          }

          if (onItemSelected != null && index >= 0) {
            onItemSelected!(index);
          }
        },
      ),
    );
  }
}