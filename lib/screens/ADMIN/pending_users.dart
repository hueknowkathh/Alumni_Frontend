import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/api_service.dart';

class PendingUsersPage extends StatefulWidget {
  const PendingUsersPage({super.key});

  @override
  State<PendingUsersPage> createState() => _PendingUsersPageState();
}

class _PendingUsersPageState extends State<PendingUsersPage> {
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE0E0E0);
  final Color primaryMaroon = const Color(0xFF4A152C);

  // ✅ Live Data States
  List<dynamic> pendingUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPendingUsers();
  }

  // ✅ FETCH: Get users with status='pending'
  Future<void> fetchPendingUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        ApiService.uri('get_pending_users.php'),
      );

      if (response.statusCode == 200) {
        setState(() {
          pendingUsers = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

  // ✅ UPDATE: Approve or Reject in Database
  Future<void> _handleAction(String id, String name, bool isApprove) async {
    final action = isApprove ? 'approved' : 'rejected';

    try {
      final response = await http.post(
        ApiService.uri('approve_user.php'),
        body: {"id": id, "action": action},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          fetchPendingUsers(); // Refresh list
          _showSnackBar(
            isApprove ? "Approved $name" : "Rejected $name",
            isApprove,
          );
        }
      }
    } catch (e) {
      debugPrint("Action Error: $e");
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(32),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "User Details",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                "Review the alumni information before approval",
                style: TextStyle(color: Colors.grey),
              ),
              const Divider(height: 32),
              _buildPopupField("Full Name", user['name'] ?? 'N/A'),
              _buildPopupField("Email Address", user['email'] ?? 'N/A'),
              Row(
                children: [
                  Expanded(
                    child: _buildPopupField(
                      "Program",
                      user['program'] ?? 'N/A',
                    ),
                  ),
                  Expanded(
                    child: _buildPopupField(
                      "Year Graduated",
                      user['year_graduated'].toString(),
                    ),
                  ),
                ],
              ),
              _buildPopupField(
                "Student ID",
                user['sid'] ?? user['id'].toString(),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildBoxedButton(
                    "Reject",
                    const Color(0xFFFFEBEE),
                    Colors.red,
                    () {
                      Navigator.pop(context);
                      _handleAction(user['id'].toString(), user['name'], false);
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildBoxedButton(
                    "Approve",
                    const Color(0xFF0D0D1D),
                    Colors.white,
                    () {
                      Navigator.pop(context);
                      _handleAction(user['id'].toString(), user['name'], true);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxedButton(
    String label,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgLight,
      child: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryMaroon))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildTableContainer(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pending Alumni Verification",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              "Review and approve newly registered alumni accounts",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: fetchPendingUsers,
          icon: const Icon(Icons.refresh),
          label: const Text("Refresh"),
        ),
      ],
    );
  }

  Widget _buildTableContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              "Pending Users List",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          if (pendingUsers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: Text("No pending verification requests.")),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFFAFAFA),
                      ),
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Email")),
                        DataColumn(label: Text("Program")),
                        DataColumn(label: Text("Year")),
                        DataColumn(
                          label: Expanded(
                            child: Text("Actions", textAlign: TextAlign.right),
                          ),
                        ),
                      ],
                      rows: pendingUsers
                          .map(
                            (user) => DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    user['name'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(Text(user['email'] ?? 'N/A')),
                                DataCell(Text(user['program'] ?? 'N/A')),
                                DataCell(
                                  Text(user['year_graduated'].toString()),
                                ),
                                DataCell(
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.visibility_outlined,
                                            size: 22,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () =>
                                              _showUserDetails(user),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildBoxedButton(
                                          "Approve",
                                          const Color(0xFFE8F5E9),
                                          Colors.green,
                                          () => _handleAction(
                                            user['id'].toString(),
                                            user['name'],
                                            true,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildBoxedButton(
                                          "Reject",
                                          const Color(0xFFFFEBEE),
                                          Colors.red,
                                          () => _handleAction(
                                            user['id'].toString(),
                                            user['name'],
                                            false,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
