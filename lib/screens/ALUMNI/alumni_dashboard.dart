import 'package:flutter/material.dart';

class AlumniDashboard extends StatelessWidget {
  const AlumniDashboard({super.key});

  static const Color primaryMaroon = Color(0xFF4A152C);
  static const Color lightBackground = Color(0xFFF7F8FA);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: lightBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// GREETING
            const Text(
              "Welcome back, Maria!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Here's an overview of your alumni profile and activities",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),

            const SizedBox(height: 32),

            /// STATUS CARDS
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _profileCard()),
                const SizedBox(width: 24),
                Expanded(child: _tracerCard()),
              ],
            ),

            const SizedBox(height: 32),

            /// MODERN QUICK ACCESS SECTION
            const Text(
              "Quick Access",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _quickAccess(Icons.person_outline, "Profile"),
                const SizedBox(width: 16),
                _quickAccess(Icons.assignment_outlined, "Tracer Form"),
                const SizedBox(width: 16),
                _quickAccess(Icons.campaign_outlined, "Announcements"),
                const SizedBox(width: 16),
                _quickAccess(Icons.settings_outlined, "Settings"),
              ],
            ),

            const SizedBox(height: 32),

            /// BOTTOM SECTION
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _announcements()),
                const SizedBox(width: 24),
                Expanded(flex: 1, child: _recentUpdates()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// MODERN QUICK ACCESS ITEM
  Widget _quickAccess(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Styled Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryMaroon.withOpacity(0.08),
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
    );
  }

  /// CARD BASE STYLE
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  /// TRACER CARD (Fixed Const Error)
  Widget _tracerCard() {
    return _cardBase(
      "Tracer Form Status",
      Icons.assignment_turned_in_outlined,
      Column(
        children: [
          _infoRow("Submission", "Not Submitted", Colors.red),
          const SizedBox(height: 16),
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
                color: Colors.amber[900], // FIXED: Removed const from parent to allow runtime lookup
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryMaroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Complete Tracer Form"),
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
          _infoRow("Student Number", "2017-00123"),
          _infoRow("Graduation Year", "2021"),
          _infoRow("Degree", "Bachelor of Science"),
          const SizedBox(height: 16),
          const Divider(),
          TextButton(
            onPressed: () {},
            child: const Text("View Full Profile", style: TextStyle(color: primaryMaroon)),
          )
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.withOpacity(.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(color: status, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                )
              : Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _announcements() {
    return _cardBase(
      "Latest Announcements",
      Icons.campaign_outlined,
      Column(
        children: [
          _announcement("Alumni Homecoming 2026", "Join us for the Alumni Homecoming on April 15...", "2026-03-10"),
          const Divider(),
          _announcement("Tracer Study Reminder", "Please complete your tracer form by March 31...", "2026-03-15"),
        ],
      ),
    );
  }

  Widget _announcement(String title, String text, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Text(date, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _recentUpdates() {
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
                Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}