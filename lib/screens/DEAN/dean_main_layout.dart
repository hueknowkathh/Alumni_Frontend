import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'dean_dashboard.dart';
import 'announcement_page.dart';
import 'settings_page.dart';
import 'department_alumni.dart';
import 'career_reports.dart';
import 'career_overview.dart';

class DeanMainLayout extends StatefulWidget {
  final Map<String, dynamic> user; // ✅ Pass the logged-in user

  const DeanMainLayout({super.key, required this.user});

  @override
  State<DeanMainLayout> createState() => _DeanMainLayoutState();
}

class _DeanMainLayoutState extends State<DeanMainLayout> {
  int _selectedIndex = 0;

  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color accentGold = const Color(0xFFC5A046); 
  final Color bgLight = const Color(0xFFF7F8FA);
  final Color borderColor = const Color(0xFFEEEEEE);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DeanDashboard(),        
      const DepartmentAlumniPage(),  
      const CareerReportsPage(),
      const CareerOverviewPage(),
      const AnnouncementPage(),
      const SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: Sidebar(
              role: "dean",
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                if (index >= 0 && index < _pages.length) {
                  setState(() {
                    _selectedIndex = index;
                  });
                }
              },
            ),
          ),

          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DYNAMIC HEADER
  Widget _buildHeader() {
    final user = widget.user;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 450),
                height: 40,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search alumni, reports, or announcements...",
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF1F3F4), 
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Notification
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_outlined, color: Colors.grey, size: 26),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accentGold,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Text(
                    "3",
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 24),

          // ✅ REAL USER INFO
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                user['name'] ?? "Dean",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: primaryMaroon,
                ),
              ),
              Text(
                user['role'] ?? "Dean",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(width: 12),

          CircleAvatar(
            backgroundColor: primaryMaroon,
            radius: 18,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}