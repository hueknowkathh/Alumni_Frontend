import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // <--- ADD THIS LINE

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String _selectedFilter = "All Roles";

 List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // This runs as soon as the page opens
  }

  Future<void> _fetchUsers() async {
    try {
      // Use 10.0.2.2 for Android Emulator, or your Local IP for physical devices
      final response = await http.get(Uri.parse('http://localhost:8080/alumni_api/get_users.php'));

      if (response.statusCode == 200) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(json.decode(response.body));
          _isLoading = false; // Stop showing the loading spinner
        });
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_selectedFilter == "All Roles") return _users;
    return _users.where((u) => u['userType'] == _selectedFilter).toList();
  }

  void _deleteUser(int index) {
    setState(() => _users.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User deleted successfully"), backgroundColor: Colors.redAccent),
    );
  }

  void _showHistory(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${user['name']}'s History"),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: (user['activities'] as List<String>)
                .map((act) => ListTile(
                      leading: const Icon(Icons.history, size: 18),
                      title: Text(act, style: const TextStyle(fontSize: 14)),
                      dense: true,
                    ))
                .toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
    // Match the lowercase 'admin', 'alumni', and 'dean' from your database
int adminCount = _users.where((u) => u['role'] == 'admin').length;
int alumniCount = _users.where((u) => u['role'] == 'alumni').length;
int deanCount = _users.where((u) => u['role'] == 'dean').length;
int totalCount = _users.length; // This should show '4' now

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Admin User Management", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _selectedFilter,
                  underline: const SizedBox(),
                  
                  items: ["All Roles", "Admin", "Alumni", "Dean"]
                      .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedFilter = val!),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                _summaryCard("Admins", adminCount.toString(), Icons.person_add_alt_1, Colors.blue),
                _summaryCard("Alumni", alumniCount.toString(), Icons.verified_user_outlined, Colors.green),
                _summaryCard("Deans", deanCount.toString(), Icons.school_outlined, Colors.orange),
                _summaryCard("Total", _users.length.toString(), Icons.group_outlined, Colors.purple),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: DataTable(
                columnSpacing: 10,
                headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                columns: const [
                  DataColumn(label: SizedBox(width: 180, child: Text('NAME', style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(label: SizedBox(width: 140, child: Text('ROLE', style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(label: SizedBox(width: 100, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold)))),
                  DataColumn(label: SizedBox(width: 160, child: Text('LAST LOGIN', style: TextStyle(fontWeight: FontWeight.bold)))),
                  // DINHI NA-UPDATE: Align header to the right
                  DataColumn(
                    label: Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
                rows: _filteredUsers.asMap().entries.map((entry) {
  int idx = entry.key;
  Map<String, dynamic> user = entry.value;

  return DataRow(cells: [
    // --- NAME COLUMN ---
    DataCell(
      SizedBox(
        width: 180,
        child: Row(
          children: [
            const CircleAvatar(radius: 12, backgroundColor: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                user['full_name'] ?? 'Unknown Name',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),

    // --- ROLE COLUMN ---
    DataCell(
      SizedBox(
        width: 140,
        child: _roleBadge(user['role'] ?? 'No Role'),
      ),
    ),

    // --- STATUS COLUMN ---
    DataCell(
      SizedBox(
        width: 100,
        child: _statusBadge(user['status'] ?? 'inactive'),
      ),
    ),

    // --- LAST LOGIN COLUMN ---
    DataCell(
      SizedBox(
        width: 160,
        child: Text(
          user['lastLogin'] ?? 'Never',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ),

    // --- ACTIONS COLUMN ---
    DataCell(
      Align(
        alignment: Alignment.centerRight,
        child: PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_vert),
          onSelected: (val) {
            if (val == 'delete') _deleteUser(idx); // Update this to call DB delete later
            if (val == 'history') _showHistory(user);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'history',
              child: ListTile(
                leading: Icon(Icons.history_outlined),
                title: Text('History'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    ),
  ]);
}).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _summaryCard(String title, String count, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        height: 110,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), Icon(icon, size: 18, color: iconColor)]),
            Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String? status) {
  String currentStatus = status ?? "inactive"; // Fallback inside the function
  bool isActive = currentStatus == "active";
  return UnconstrainedBox(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFD1FAE5) : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        currentStatus,
        style: TextStyle(
          color: isActive ? const Color(0xFF10B981) : Colors.red[700],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

  Widget _roleBadge(String role) {
    String currentRole = role ?? "User";
    Color bg = const Color(0xFFE0D7FF);
    Color text = const Color(0xFF6C5DD3);
    
    if (role == "College Dean") {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFD97706);
    } else if (role == "Alumni") {
      bg = const Color(0xFFDBEAFE);
      text = const Color(0xFF2563EB);
    }
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(
          currentRole, 
          style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}