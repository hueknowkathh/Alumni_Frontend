import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final String role;
  final int selectedIndex;
  final bool isCollapsed;
  final bool isInDrawer;
  final Function(int) onItemSelected;
  final VoidCallback? onToggleSidebar;

  const Sidebar({
    super.key,
    required this.role,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isCollapsed = false,
    this.isInDrawer = false,
    this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    // Theme Colors matching your Main Layout
    const Color primaryMaroon = Color(0xFF4A152C);
    const Color accentGold = Color(0xFFC5A046);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCollapsed ? 80 : 260,
      color: primaryMaroon,
      child: Column(
        children: [
          // Sidebar Header
          Container(
            height: 70,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 20),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed)
                  const Text(
                    "ALUMNI ADMIN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                // This is the button that was missing in your screenshot
                if (!isInDrawer)
                  IconButton(
                    icon: Icon(
                      isCollapsed ? Icons.menu_open : Icons.menu,
                      color: Colors.white,
                    ),
                    onPressed: onToggleSidebar,
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),

          // Navigation Items
          Expanded(
            child: ListView(
              children: [
                _buildNavItem(
                  0,
                  Icons.dashboard,
                  "Dashboard",
                  selectedIndex == 0,
                ),
                _buildNavItem(
                  1,
                  Icons.people,
                  "Alumni List",
                  selectedIndex == 1,
                ),
                _buildNavItem(
                  2,
                  Icons.bar_chart,
                  "Tracer Data",
                  selectedIndex == 2,
                ),
                _buildNavItem(
                  3,
                  Icons.person_add_alt,
                  "Pending Users",
                  selectedIndex == 3,
                ),
                _buildNavItem(
                  4,
                  Icons.announcement,
                  "Announcements",
                  selectedIndex == 4,
                ),
                _buildNavItem(5, Icons.work, "Jobs", selectedIndex == 5),
                _buildNavItem(
                  99,
                  Icons.settings,
                  "Settings",
                  selectedIndex == 99,
                ), // Example index
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    return ListTile(
      onTap: () => onItemSelected(index),
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFFC5A046) : Colors.white70,
      ),
      title: isCollapsed
          ? null
          : Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
      tileColor: isSelected
          ? Colors.white.withOpacity(0.1)
          : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
