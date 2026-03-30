import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/api_service.dart';
import '../../services/content_service.dart';
import '../../state/user_store.dart';

class AlumniDashboard extends StatefulWidget {
  final Map<String, dynamic> user;
  final ValueChanged<int>? onModuleSelected;

  const AlumniDashboard({super.key, required this.user, this.onModuleSelected});

  @override
  State<AlumniDashboard> createState() => _AlumniDashboardState();
}

class _AlumniDashboardState extends State<AlumniDashboard> {
  static const Color primaryMaroon = Color(0xFF4A152C);
  static const Color lightBackground = Color(0xFFF7F8FA);

  bool isLoading = true;
  List<Map<String, dynamic>> announcements = [];
  Map<String, dynamic>? tracerInfo;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final rawUserId =
          widget.user['id'] ??
          widget.user['user_id'] ??
          widget.user['alumni_id'];
      final userId = int.tryParse('$rawUserId') ?? 0;

      // Fetch announcements
      final annData = await ContentService.fetchAnnouncements();

      // Fetch tracer submission status
      Map<String, dynamic> tracerData = const {"submitted": false};

      if (userId > 0) {
        final tracerRes = await http.get(
          ApiService.uri(
            'check_tracer.php',
            queryParameters: {'alumni_id': '$userId'},
          ),
        );

        if (tracerRes.statusCode != 200) {
          throw Exception(
            'Tracer status request failed (${tracerRes.statusCode})',
          );
        }

        final tracerBody = tracerRes.body.trim();
        debugPrint('TRACER STATUS: ${tracerRes.statusCode}');
        debugPrint('TRACER BODY: $tracerBody');

        if (tracerBody.isEmpty) {
          throw Exception('Tracer API returned an empty response');
        }

        if (tracerBody.startsWith('<')) {
          throw Exception(
            'Tracer API returned HTML instead of JSON: $tracerBody',
          );
        }

        final decoded = jsonDecode(tracerBody);
        if (decoded is Map<String, dynamic>) {
          tracerData = decoded;
        }
      }

      if (!mounted) return;

      setState(() {
        announcements = annData
            .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
            .toList();

        final submitted = tracerData['submitted'] == true;
        tracerInfo = {'submitted': submitted ? 'Yes' : 'No'};
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching data: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<Map<String, dynamic>?>(
                    valueListenable: UserStore.currentUser,
                    builder: (context, liveUser, _) {
                      final name =
                          (liveUser?['name'] ?? widget.user['name'] ?? 'Alumni')
                              .toString()
                              .trim();

                      return Text(
                        "Welcome back, ${name.isEmpty ? 'Alumni' : name}!",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Here's an overview of your alumni profile and activities",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _profileCard()),
                      const SizedBox(width: 24),
                      Expanded(child: _tracerCard(context)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Quick Access",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _quickAccess(
                        Icons.person_outline,
                        "Profile",
                        _openProfileModule,
                      ),
                      const SizedBox(width: 16),
                      _quickAccess(
                        Icons.campaign_outlined,
                        "Announcements",
                        _openAnnouncementsModule,
                      ),
                      const SizedBox(width: 16),
                      _quickAccess(Icons.work_outline, "Jobs", _openJobsModule),
                      const SizedBox(width: 16),
                      _quickAccess(
                        Icons.settings_outlined,
                        "Settings",
                        _openSettingsModule,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _announcementsCard()),
                      const SizedBox(width: 24),
                      Expanded(flex: 1, child: _recentUpdatesCard()),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _quickAccess(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryMaroon.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryMaroon, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tracerCard(BuildContext context) {
    final submissionStatus =
        tracerInfo != null && tracerInfo!['submitted'] == "Yes"
        ? "Submitted"
        : "Not Submitted";

    final statusColor = submissionStatus == "Submitted"
        ? Colors.green
        : Colors.red;

    return _cardBase(
      "Tracer Form Status",
      Icons.assignment_turned_in_outlined,
      Column(
        children: [
          _infoRow("Submission", submissionStatus, statusColor),
          const SizedBox(height: 16),
          if (submissionStatus == "Not Submitted")
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                "Please complete your tracer form to help us track alumni career outcomes. Deadline: March 31, 2026",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openTracerModule,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                submissionStatus == "Submitted"
                    ? "View Tracer Form"
                    : "Complete Tracer Form",
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _announcementsCard() {
    if (announcements.isEmpty) {
      return _cardBase(
        "Latest Announcements",
        Icons.campaign_outlined,
        const Text(
          "No announcements available.",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return _cardBase(
      "Latest Announcements",
      Icons.campaign_outlined,
      Column(
        children: announcements
            .map(
              (a) => Column(
                children: [
                  _announcement(
                    (a['title'] ?? '').toString(),
                    (a['description'] ?? '').toString(),
                    (a['created_at'] ?? '').toString(),
                  ),
                  const Divider(),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _announcement(String title, String content, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _recentUpdatesCard() {
    return _cardBase(
      "Recent Updates",
      Icons.access_time,
      Column(
        children: [
          _update("New announcement posted", "2 hours ago"),
          _update("Reminder: Complete tracer form", "1 day ago"),
        ],
      ),
    );
  }

  Widget _update(String text, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontSize: 13)),
                Text(
                  time,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard() {
    return _cardBase(
      "Profile Status",
      Icons.person_search_outlined,
      Column(
        children: [
          _infoRow("Completion", "Complete", Colors.green),
          _infoRow(
            "Student Number",
            (widget.user['student_number'] ?? "N/A").toString(),
          ),
          _infoRow(
            "Graduation Year",
            (widget.user['graduation_year'] ?? "N/A").toString(),
          ),
          _infoRow("Degree", (widget.user['degree'] ?? "N/A").toString()),
          const SizedBox(height: 16),
          const Divider(),
          TextButton(
            onPressed: _openProfileModule,
            child: const Text(
              "View Full Profile",
              style: TextStyle(color: primaryMaroon),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardBase(String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryMaroon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, [Color? status]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          status != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: status.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: status,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
        ],
      ),
    );
  }

  void _openProfileModule() => widget.onModuleSelected?.call(1);

  void _openAnnouncementsModule() => widget.onModuleSelected?.call(2);

  void _openJobsModule() => widget.onModuleSelected?.call(3);

  void _openSettingsModule() => widget.onModuleSelected?.call(4);

  void _openTracerModule() {
    final program = (widget.user['program'] ?? "").toString();
    final tracerIndex = switch (program) {
      "BSSW" => 5,
      "BSIT" => 6,
      _ => -1,
    };

    if (tracerIndex != -1) {
      widget.onModuleSelected?.call(tracerIndex);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Program not recognized")));
  }
}
