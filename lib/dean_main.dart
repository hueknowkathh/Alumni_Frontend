import 'package:flutter/material.dart';
import 'dean_analytics.dart';
import 'dean_announcements.dart';
import 'dean_career_overview.dart';
import 'dean_dashboard.dart'; 
import 'dean_department.dart'; 
import 'dean_settings.dart';

class DeanMainShell extends StatefulWidget {
  final String deanName;
  final String deanRole;

  const DeanMainShell({
    super.key,
    this.deanName = "Department Dean", 
    this.deanRole = "College Access",
  });

  @override
  State<DeanMainShell> createState() => _DeanMainShellState();
}

class _DeanMainShellState extends State<DeanMainShell> {
  int _selectedIndex = 0;

  // The pages accessible via the sidebar
  final List<Widget> _pages = [
    const DeanDashboard(),        
    const DepartmentAlumniPage(),  
    const CareerOverviewPage(),    
    const AnalyticsReportsPage(),  
    const AnnouncementsPage(),     
    const SettingsPage(),          
  ];

  // --- AI ASSISTANT MODAL ---
  void _showAIChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.psychology, color: Color(0xFFC69C6D)),
                  const SizedBox(width: 10),
                  const Text("Dean's AI Assistant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Hello Dean ${widget.deanName}, I can help you analyze department trends or draft announcements for the ${widget.deanRole}.",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Ask about department data...",
                  suffixIcon: const Icon(Icons.send, color: Color(0xFF420031)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      
      floatingActionButton: FloatingActionButton(
        onPressed: _showAIChat,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF420031), Color(0xFFC69C6D)], 
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
            ],
          ),
          child: const Icon(Icons.psychology, color: Colors.white, size: 30),
        ),
      ),

      body: Row(
        children: [
          // 1. SIDEBAR
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: Color(0xFF420031),
            ),
            child: Column(
              children: [
                _buildSidebarHeader(),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      _navItem(Icons.grid_view_rounded, "Dashboard", 0),
                      _navItem(Icons.people_outline, "Department Alumni", 1),
                      _navItem(Icons.business_center_outlined, "Career Overview", 2),
                      _navItem(Icons.bar_chart_outlined, "Analytics & Reports", 3),
                      _navItem(Icons.campaign_outlined, "Announcements", 4),
                      _navItem(Icons.settings_outlined, "Settings", 5),
                    ],
                  ),
                ),
                
                const Divider(color: Colors.white24, indent: 20, endIndent: 20),
                _navItem(Icons.logout_rounded, "Logout", -1), 
                
                _buildSidebarFooter(),
              ],
            ),
          ),

          // 2. MAIN AREA
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(), 
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out of the Dean portal?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(25),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("JMC Alumni", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(widget.deanRole, style: const TextStyle(color: Color(0xFFC69C6D), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20, top: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("System Status", style: TextStyle(color: Colors.white54, fontSize: 10)),
          Text("Dean Access Active", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 45,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                  hintText: "Search department records...",
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const Spacer(),
          const Icon(Icons.notifications_none, color: Color(0xFF420031), size: 26),
          const SizedBox(width: 25),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.deanName,
                style: const TextStyle(color: Color.from(alpha: 1, red: 0.259, green: 0, blue: 0.192), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                widget.deanRole,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 15),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF420031),
            child: Text(
              widget.deanName.isNotEmpty ? widget.deanName[0].toUpperCase() : "D",
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFC69C6D) : Colors.transparent, 
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: -2),
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        onTap: () {
          if (index == -1) {
            _showLogoutDialog();
          } else {
            setState(() => _selectedIndex = index);
          }
        },
      ),
    );
  }
}