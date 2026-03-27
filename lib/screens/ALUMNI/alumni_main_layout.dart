import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'alumni_dashboard.dart';
import 'profile_page.dart';
import 'announcement_page.dart';
import 'settings_page.dart';
import 'bsit_tracer.dart';
import 'bssw_tracer.dart';

class AlumniMainLayout extends StatefulWidget {
  final Map<String, dynamic> user; 

  const AlumniMainLayout({super.key, required this.user});

  @override
  State<AlumniMainLayout> createState() => _AlumniMainLayoutState();
}

class _AlumniMainLayoutState extends State<AlumniMainLayout> {
  int _selectedIndex = 0;

  final Color bgLight = const Color(0xFFF8F9FA);
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color borderColor = const Color(0xFFE0E0E0);

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      AlumniDashboard(user: widget.user),
      const ProfilePage(),
      const AnnouncementPage(),
      const SettingsPage(),
      BSSWTracerPage(), 
      BSITTracerPage(),
];
  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Row(
        children: [
          // Sidebar
          SizedBox(
            width: 280,
            child: Sidebar(
              role: "alumni",
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),

          // Main Content
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
        border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Spacer(),

          // Notification
          Badge(
            label: const Text(
              '3',
              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.redAccent,
            largeSize: 18,
            child: const Icon(Icons.notifications_none_outlined, color: Colors.black54, size: 26),
          ),

          const SizedBox(width: 24),

          // ✅ REAL USER INFO
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                user['name'] ?? "Alumni User",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              Text(
                user['role'] ?? "Alumni",
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