import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/activity_service.dart';
import '../../services/api_service.dart';
import '../../services/user_media_service.dart';
import '../widgets/luxury_module_banner.dart';

class PendingUsersPage extends StatefulWidget {
  const PendingUsersPage({super.key});

  @override
  State<PendingUsersPage> createState() => _PendingUsersPageState();
}

class _PendingUsersPageState extends State<PendingUsersPage> {
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE5E7EB);
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color accentGold = const Color(0xFFC5A046);

  // ✅ Live Data States
  List<dynamic> pendingUsers = [];
  bool isLoading = true;
  final Set<String> _selectedUserIds = <String>{};

  @override
  void initState() {
    super.initState();
    fetchPendingUsers();
  }

  // ✅ FETCH: Get users with status='pending'
  Future<void> fetchPendingUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(ApiService.uri('get_pending_users.php'));

      if (response.statusCode == 200) {
        setState(() {
          pendingUsers = json.decode(response.body);
          _selectedUserIds.removeWhere(
            (id) => !pendingUsers.any((user) => user['id'].toString() == id),
          );
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
          await ActivityService.logImportantFlow(
            action: isApprove ? 'approve_user' : 'reject_user',
            title:
                'Admin ${isApprove ? 'approved' : 'rejected'} the registration of $name',
            type: 'Verification',
            targetId: id,
            targetType: 'alumni_registration',
            description:
                'Registration for $name was ${isApprove ? 'approved' : 'rejected'}.',
            metadata: {
              'status': action,
              'target_user_id': id,
              'target_user_name': name,
            },
          );
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

  Future<void> _handleBulkAction(bool isApprove) async {
    if (_selectedUserIds.isEmpty) return;

    final action = isApprove ? 'approved' : 'rejected';
    final selectedUsers = pendingUsers
        .where((user) => _selectedUserIds.contains(user['id'].toString()))
        .map((user) => Map<String, dynamic>.from(user))
        .toList();

    try {
      final response = await http.post(
        ApiService.uri('approve_user.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ids': _selectedUserIds.map(int.parse).toList(),
          'action': action,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          for (final user in selectedUsers) {
            final id = user['id']?.toString() ?? '';
            final name = user['name']?.toString() ?? 'Unknown User';
            await ActivityService.logImportantFlow(
              action: isApprove ? 'approve_user' : 'reject_user',
              title:
                  'Admin ${isApprove ? 'approved' : 'rejected'} the registration of $name',
              type: 'Verification',
              targetId: id,
              targetType: 'alumni_registration',
              description:
                  'Registration for $name was ${isApprove ? 'approved' : 'rejected'} through bulk action.',
              metadata: {
                'status': action,
                'target_user_id': id,
                'target_user_name': name,
                'bulk_action': true,
              },
            );
          }

          setState(() => _selectedUserIds.clear());
          fetchPendingUsers();
          _showSnackBar(
            result['message']?.toString() ??
                (isApprove
                    ? 'Selected users approved.'
                    : 'Selected users rejected.'),
            isApprove,
          );
        } else {
          _showSnackBar(
            result['message']?.toString() ?? 'Bulk action failed.',
            false,
          );
        }
      }
    } catch (e) {
      debugPrint("Bulk Action Error: $e");
      _showSnackBar('Bulk action failed.', false);
    }
  }

  void _toggleAllSelections(bool selected) {
    setState(() {
      if (selected) {
        _selectedUserIds
          ..clear()
          ..addAll(
            pendingUsers
                .map((user) => user['id']?.toString() ?? '')
                .where((id) => id.isNotEmpty),
          );
      } else {
        _selectedUserIds.clear();
      }
    });
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
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFFBF7),
                  Color(0xFFF8F1F4),
                  Color(0xFFFFFCFA),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: primaryMaroon.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  color: primaryMaroon.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF5A1832),
                        Color(0xFF6A2A43),
                        Color(0xFF35101E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.14),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: accentGold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          Icons.verified_user_outlined,
                          color: accentGold,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                'ALUMNI VERIFICATION',
                                style: TextStyle(
                                  color: accentGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'User details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPopupField("Full Name", user['name'] ?? 'N/A'),
                        const SizedBox(height: 14),
                        _buildPopupField(
                          "Email Address",
                          user['email'] ?? 'N/A',
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isStacked = constraints.maxWidth < 440;
                            final programField = _buildPopupField(
                              "Program",
                              user['program'] ?? 'N/A',
                            );
                            final yearField = _buildPopupField(
                              "Year Graduated",
                              user['year_graduated'].toString(),
                            );
                            if (isStacked) {
                              return Column(
                                children: [
                                  programField,
                                  const SizedBox(height: 14),
                                  yearField,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: programField),
                                const SizedBox(width: 14),
                                Expanded(child: yearField),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildPopupField(
                          "Student ID",
                          user['student_number'] ??
                              user['alumni_number'] ??
                              user['id'].toString(),
                        ),
                        const SizedBox(height: 14),
                        _buildAlumniIdProof(user),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _handleAction(
                                    user['id'].toString(),
                                    user['name'],
                                    false,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(
                                    color: Colors.red.withValues(alpha: 0.18),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  "Reject",
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _handleAction(
                                    user['id'].toString(),
                                    user['name'],
                                    true,
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryMaroon,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                ),
                                label: const Text(
                                  "Approve",
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupField(String label, String value) {
    return _buildReviewShell(
      label: label,
      child: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: Color(0xFF2B1A22),
        ),
      ),
    );
  }

  Widget _buildReviewShell({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: primaryMaroon.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          child,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7F8FA), Color(0xFFF4F1F2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryMaroon))
          : SingleChildScrollView(
              padding: EdgeInsets.all(
                MediaQuery.of(context).size.width < 600 ? 16 : 32,
              ),
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
    final width = MediaQuery.of(context).size.width;
    final isStacked = width < 980;
    return LuxuryModuleBanner(
      compact: isStacked,
      title: 'Pending Alumni Verification',
      description:
          'Review and approve newly registered alumni accounts in a cleaner verification workspace.',
      icon: Icons.verified_user_outlined,
      actions: [
        LuxuryBannerAction(
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          onPressed: fetchPendingUsers,
          iconOnly: !isStacked,
        ),
      ],
    );
  }

  Widget _buildAlumniIdProof(Map<String, dynamic> user) {
    final fileName =
        (user['alumni_id_filename'] ?? user['alumniIdFilename'] ?? '')
            .toString()
            .trim();
    final url = UserMediaService.alumniIdUrl(user);
    final canPreview = _isPreviewableImage(fileName);

    return _buildReviewShell(
      label: "Uploaded Alumni ID",
      child: fileName.isEmpty || url == null
          ? const Text(
              "No alumni ID uploaded",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Color(0xFF2B1A22),
              ),
            )
          : canPreview
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildProofFallback(),
              ),
            )
          : _buildProofFallback(),
    );
  }

  Widget _buildProofFallback() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F1F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, color: primaryMaroon, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Alumni ID proof uploaded",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPreviewableImage(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  Widget _buildTableContainer() {
    final selectableIds = pendingUsers
        .map((user) => user['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final hasSelection = _selectedUserIds.isNotEmpty;
    final hasBulkSelection = _selectedUserIds.length > 1;
    final areAllSelected =
        selectableIds.isNotEmpty &&
        _selectedUserIds.length == selectableIds.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                const Text(
                  "Pending Users List",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (hasBulkSelection)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _handleBulkAction(false),
                        icon: const Icon(Icons.close_rounded),
                        label: Text('Reject (${_selectedUserIds.length})'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _handleBulkAction(true),
                        icon: const Icon(Icons.done_rounded),
                        label: Text('Approve (${_selectedUserIds.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D0D1D),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
              ],
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
                      columns: [
                        DataColumn(
                          label: Checkbox(
                            value: areAllSelected,
                            tristate: hasSelection && !areAllSelected,
                            onChanged: (value) =>
                                _toggleAllSelections(value ?? false),
                          ),
                        ),
                        DataColumn(label: Text("Name")),
                        DataColumn(label: Text("Email")),
                        DataColumn(label: Text("Program")),
                        DataColumn(label: Text("Year")),
                        DataColumn(label: Text("Alumni ID")),
                        DataColumn(
                          label: SizedBox(
                            width: 280,
                            child: Text("Actions", textAlign: TextAlign.center),
                          ),
                        ),
                      ],
                      rows: pendingUsers
                          .map(
                            (user) => DataRow(
                              selected: _selectedUserIds.contains(
                                user['id'].toString(),
                              ),
                              cells: [
                                DataCell(
                                  Checkbox(
                                    value: _selectedUserIds.contains(
                                      user['id'].toString(),
                                    ),
                                    onChanged: (value) {
                                      final id = user['id'].toString();
                                      setState(() {
                                        if (value == true) {
                                          _selectedUserIds.add(id);
                                        } else {
                                          _selectedUserIds.remove(id);
                                        }
                                      });
                                    },
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      user['name'] ?? 'N/A',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 220,
                                    child: Text(
                                      user['email'] ?? 'N/A',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 140,
                                    child: Text(
                                      user['program'] ?? 'N/A',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(user['year_graduated'].toString()),
                                ),
                                DataCell(
                                  _buildProofStatus(user),
                                ),
                                DataCell(_buildRowActions(user)),
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

  Widget _buildProofStatus(Map<String, dynamic> user) {
    final hasProof =
        (user['alumni_id_path'] ?? user['alumniIdPath'] ?? '')
            .toString()
            .trim()
            .isNotEmpty;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasProof ? Icons.check_circle_outline : Icons.error_outline,
          size: 18,
          color: hasProof ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 6),
        Text(hasProof ? 'Uploaded' : 'Missing'),
      ],
    );
  }

  Widget _buildRowActions(Map<String, dynamic> user) {
    final id = user['id'].toString();
    final name = user['name']?.toString() ?? 'User';

    return SizedBox(
      width: 280,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Tooltip(
            message: 'Review details',
            child: SizedBox(
              width: 40,
              height: 40,
              child: OutlinedButton(
                onPressed: () => _showUserDetails(user),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: Colors.blue,
                  side: BorderSide(color: Colors.blue.withValues(alpha: 0.16)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.visibility_outlined, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: _buildBoxedButton(
              "Approve",
              const Color(0xFFE8F5E9),
              Colors.green,
              () => _handleAction(id, name, true),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 82,
            child: _buildBoxedButton(
              "Reject",
              const Color(0xFFFFEBEE),
              Colors.red,
              () => _handleAction(id, name, false),
            ),
          ),
        ],
      ),
    );
  }
}
