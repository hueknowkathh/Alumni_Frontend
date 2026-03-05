import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerificationQueuePage extends StatefulWidget {
  const VerificationQueuePage({super.key});

  @override
  State<VerificationQueuePage> createState() => _VerificationQueuePageState();
}

class _VerificationQueuePageState extends State<VerificationQueuePage> {
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingUsers();
  }

  // 1. DATA SOURCE: Fetch real pending users from MySQL
  Future<void> _fetchPendingUsers() async {
    try {
      // Usba ang IP kung naggamit ka og physical device (pananglitan: 192.168.1.x)
      final response = await http.get(Uri.parse('http://localhost:8080/alumni_api/get_pending_users.php'));
      
      if (response.statusCode == 200) {
        setState(() {
          _requests = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching users: $e");
      setState(() => _isLoading = false);
    }
  }

  // 2. ACTION: Process Approval/Rejection in Database
  Future<void> _processVerification(int id, String name, int index, bool isApproved) async {
    if (!isApproved) {
      setState(() => _requests.removeAt(index));
      _showSnackBar("Rejected $name", Colors.red);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost/alumni_api/verify_user.php'),
        body: jsonEncode({"id": id}),
      );

      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        setState(() => _requests.removeAt(index));
        _showSnackBar("Approved $name successfully!", Colors.green);
      } else {
        _showSnackBar("Error: ${result['message']}", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Connection Error", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 3. ACTION: Simulate Viewing Documents
  void _showDocumentPreview(String docType, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("$docType - $name"),
        content: Container(
          height: 300,
          width: 400,
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insert_drive_file, size: 60, color: Colors.grey),
              SizedBox(height: 10),
              Text("Document Preview Placeholder", style: TextStyle(color: Colors.black54)),
              Text("(Testing Mode)", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
    ? const Center(child: CircularProgressIndicator(color: Color(0xFF420031)))
    : SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Verification Queue", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const Text("Review and approve pending alumni verification requests", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 25),

            // DYNAMIC STATS CARDS
            Row(
              children: [
                _topStatCard("Pending", _requests.length.toString(), Icons.people_outline),
                _topStatCard("To Review", _requests.length.toString(), Icons.assignment_ind_outlined),
                _topStatCard("System Status", "Live", Icons.check_circle_outline),
              ],
            ),
            const SizedBox(height: 30),

            // DYNAMIC LIST
            if (_requests.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Column(
                    children: [
                      Icon(Icons.verified_user_outlined, size: 80, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("No pending requests found", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _requests.length,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final user = _requests[index];

                  // PREVENT NULL ERRORS: Use null-coalescing (??)
                  final String name = user['full_name'] ?? "No Name Provided";
                  final String email = user['email'] ?? "No Email";
                  final String role = (user['role'] ?? "ALUMNI").toString().toUpperCase();
                  final int userId = int.tryParse(user['id'].toString()) ?? 0;

                  return _verificationRequestCard(index, userId, name, role, email);
                },
              ),
          ],
        ),
      );
  }

  Widget _topStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                Icon(icon, size: 18, color: const Color(0xFF420031)),
              ],
            ),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _verificationRequestCard(int index, int id, String name, String role, String email) {
    // Role-based Color Logic
    Color roleColor = role == "ADMIN" ? Colors.red : (role == "DEAN" ? Colors.blue : Colors.green);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 35, 
                backgroundColor: roleColor,
                child: Text(
                  name.isNotEmpty ? name[0] : "?", 
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(email, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 5),
                    Text("Role: $role", style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              _statusBadge("PENDING", const Color(0xFFFFDADA), const Color(0xFFC62828)),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Submitted Documents (Testing):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _docChip("Diploma", () => _showDocumentPreview("Official Diploma", name)),
                const SizedBox(width: 10),
                _docChip("Valid ID", () => _showDocumentPreview("Government ID", name)),
                const SizedBox(width: 10),
                _docChip("Proof of Graduation", () => _showDocumentPreview("Proof", name)),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _processVerification(id, name, index, true),
                  child: const Text("Approve Verification", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDECEA),
                    foregroundColor: const Color(0xFFC62828),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFC62828))),
                  ),
                  onPressed: () => _processVerification(id, name, index, false),
                  child: const Text("Reject", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _docChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.file_present_rounded, size: 16, color: Colors.blueGrey),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}