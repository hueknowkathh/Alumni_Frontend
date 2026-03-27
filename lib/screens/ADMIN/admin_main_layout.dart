import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'admin_dashboard.dart';
import 'alumni_list.dart';
import 'tracer_data.dart';
import 'pending_users.dart';
import 'announcements_page.dart';
import 'settings_page.dart';
import 'recent_activity.dart';
import 'latest_registrations.dart'; // ✅ New
import 'dart:convert'; 
import 'package:http/http.dart' as http; 

class AdminMainLayout extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminMainLayout({super.key, required this.user});

  @override
  State<AdminMainLayout> createState() => _AdminMainLayoutState();
}

class _AdminMainLayoutState extends State<AdminMainLayout> {
  int _selectedIndex = 0;

  // Activity
  List<dynamic> _allActivities = [];
  bool _isLoadingActivity = false;

  // Users
  List<dynamic> _allUsers = [];
  bool _isLoadingUsers = false;

  // 🔥 Page indices
  static const int DASHBOARD = 0;
  static const int ALUMNI_LIST = 1;
  static const int TRACER_DATA = 2;
  static const int PENDING_USERS_PAGE = 3;
  static const int ANNOUNCEMENTS = 4;
  static const int SETTINGS = 5;
  static const int RECENT_ACTIVITY = 6;
  static const int USER_REGISTRATIONS_PAGE = 7;

  // Theme
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color accentGold = const Color(0xFFC5A046);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    fetchFullActivity();
    fetchAllUsers();
  }

  // Fetch full activity
  Future<void> fetchFullActivity() async {
    setState(() => _isLoadingActivity = true);
    try {
      final response = await http.get(
        Uri.parse("http://localhost/alumni_php/get_full_activity.php")
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() => _allActivities = data);
      }
    } catch (e) {
      debugPrint("Error fetching activity: $e");
    } finally {
      setState(() => _isLoadingActivity = false);
    }
  }

  // Fetch all users
  Future<void> fetchAllUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await http.get(
        Uri.parse("http://localhost/alumni_php/get_latest_reg.php")
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() => _allUsers = data);
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      // 0 Dashboard
      AdminDashboard(
        onActionSelected: (index) => setState(() => _selectedIndex = index),

        // Recent Activity View All
        onViewAll: () async {
          await fetchFullActivity();
          setState(() => _selectedIndex = RECENT_ACTIVITY);
        },

        // Latest Registrations View All → UserRegistrationsPage
        onViewAllUsers: () async {
          await fetchAllUsers();
          setState(() => _selectedIndex = USER_REGISTRATIONS_PAGE);
        },
      ),

      const AlumniList(),
      const TracerDataPage(),
      const PendingUsersPage(), // pending users only
      const AnnouncementsPage(),
      const AdminSettings(),

      // 6 Recent Activity Page
      RecentActivityPage(
        activities: _allActivities,
        isLoading: _isLoadingActivity,
        onBack: () => setState(() => _selectedIndex = DASHBOARD),
        onRefresh: fetchFullActivity,
      ),

      // 7 User Registrations Page (View All)
      UserRegistrationsPage(
        users: _allUsers,
        isLoading: _isLoadingUsers,
        onBack: () => setState(() => _selectedIndex = DASHBOARD),
        onRefresh: fetchAllUsers,
      ),
    ];

    return Scaffold(
      backgroundColor: bgLight,
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: Sidebar(
              role: "admin",
              selectedIndex: _selectedIndex,
              onItemSelected: (index) => setState(() => _selectedIndex = index),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final user = widget.user;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Spacer(),
          Badge(
            label: Text(_allActivities.length.toString()),
            backgroundColor: accentGold,
            child: const Icon(Icons.notifications_none_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                user['name'] ?? "Admin",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                user['role'] ?? "Administrator",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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