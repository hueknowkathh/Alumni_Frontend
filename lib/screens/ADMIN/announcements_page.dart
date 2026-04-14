import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import '../widgets/luxury_module_banner.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color accentGold = const Color(0xFFC5A046);
  final Color bgLight = const Color(0xFFF7F8FA);
  final Color borderColor = const Color(0xFFE5E7EB);
  final Color softRose = const Color(0xFFF8F1F4);

  bool isLoading = false;
  bool isSaving = false;
  List announcements = [];
  List filteredAnnouncements = [];
  String selectedCategory = "All Categories";
  String searchQuery = "";

  Color getCategoryColor(String category) {
    switch (category) {
      case "Events":
        return Colors.blue;
      case "Reminders":
        return Colors.orange;
      case "Job Opportunities":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAnnouncements();
  }

  Future<void> fetchAnnouncements() async {
    setState(() => isLoading = true);
    try {
      final url = ApiService.uri('get_announcements.php');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          announcements = decoded is List
              ? decoded
              : (decoded is Map ? decoded['announcements'] ?? [] : []);
          _applyFilters();
        });
      }
    } catch (e) {
      debugPrint("Error fetching announcements: $e");
    }
    setState(() => isLoading = false);
  }

  void _applyFilters() {
    filteredAnnouncements = announcements.where((ann) {
      final title = (ann['title'] ?? "").toString().toLowerCase();
      final category = (ann['category'] ?? "General").toString();
      final matchesSearch = title.contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == "All Categories"
          ? true
          : category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<bool> saveAnnouncement(
    String title,
    String desc,
    String category, {
    String? id,
  }) async {
    final url = ApiService.uri('add_announcement.php');

    setState(() => isSaving = true);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id ?? "",
          "title": title,
          "description": desc,
          "category": category,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['status'] == 'success') {
          await fetchAnnouncements();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Announcement saved successfully"),
                backgroundColor: Colors.green,
              ),
            );
          }

          setState(() => isSaving = false);
          return true;
        } else {
          _showError(result['message'] ?? "Unknown Error");
        }
      }
    } catch (e) {
      debugPrint("Connection failed: $e");
      _showError("Could not connect to server.");
    }

    setState(() => isSaving = false);
    return false;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      final url = ApiService.uri(
        'delete_announcement.php',
        queryParameters: {'id': id},
      );

      final response = await http.post(url, body: {"id": id});
      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        await fetchAnnouncements();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Announcement deleted"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        _showError(result['message'] ?? "Delete failed");
      }
    } catch (e) {
      debugPrint("Delete error: $e");
      _showError("Failed to delete announcement");
    }
  }

  void _showAnnouncementDialog({Map<String, dynamic>? announcement}) {
    final isEditing = announcement != null;

    final titleController = TextEditingController(
      text: isEditing ? announcement['title'] : "",
    );
    final descController = TextEditingController(
      text: isEditing ? announcement['description'] : "",
    );

    String selectedCategory = isEditing
        ? (announcement['category'] ?? "Events")
        : "Events";

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
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
                border: Border.all(
                  color: primaryMaroon.withValues(alpha: 0.10),
                ),
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
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
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
                            isEditing
                                ? Icons.edit_outlined
                                : Icons.campaign_outlined,
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
                                  isEditing
                                      ? 'ANNOUNCEMENT EDITOR'
                                      : 'NEW ANNOUNCEMENT',
                                  style: TextStyle(
                                    color: accentGold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            Text(
                              isEditing
                                  ? 'Update announcement'
                                  : 'Create announcement',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
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
                          _buildDialogFieldShell(
                            label: 'Announcement Title',
                            child: TextField(
                              controller: titleController,
                              decoration: _dialogInputDecoration(
                                'Enter a clear headline',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildDialogFieldShell(
                            label: 'Description',
                            child: TextField(
                              controller: descController,
                              maxLines: 4,
                              decoration: _dialogInputDecoration(
                                'Write the full announcement details',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildDialogFieldShell(
                            label: 'Category',
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedCategory,
                              items: const [
                                "Events",
                                "Reminders",
                                "Job Opportunities",
                                "GENERAL",
                              ].map(
                                (cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ),
                              ).toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => selectedCategory = value);
                              },
                              decoration: _dialogInputDecoration(
                                'Choose a category',
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryMaroon,
                                    side: BorderSide(
                                      color: primaryMaroon.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
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
                                  onPressed: isSaving
                                      ? null
                                      : () async {
                                          final success =
                                              await saveAnnouncement(
                                                titleController.text,
                                                descController.text,
                                                selectedCategory,
                                                id: isEditing
                                                    ? announcement['id']
                                                    : null,
                                              );

                                          if (success &&
                                              dialogContext.mounted) {
                                            Navigator.of(dialogContext).pop();
                                          }
                                        },
                                  icon: isSaving
                                      ? const SizedBox(
                                          height: 16,
                                          width: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          isEditing
                                              ? Icons.check_circle_outline
                                              : Icons.publish_outlined,
                                          size: 18,
                                        ),
                                  label: Text(
                                    isEditing ? 'Update Post' : 'Publish Post',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
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
      ),
    );
  }

  Widget _buildDialogFieldShell({
    required String label,
    required Widget child,
  }) {
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

  InputDecoration _dialogInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFFCF8F5),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: borderColor.withValues(alpha: 0.9),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: borderColor.withValues(alpha: 0.9),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryMaroon, width: 1.2),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Announcement?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await deleteAnnouncement(id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 720;
    return Container(
      color: bgLight,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F8FA), Color(0xFFF4F1F2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: primaryMaroon))
            : ListView(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 16 : 24,
                  isCompact ? 16 : 24,
                  isCompact ? 16 : 24,
                  32,
                ),
                children: [
                  _buildHeroHeader(),
                  const SizedBox(height: 24),
                  _buildQuickStats(),
                  const SizedBox(height: 24),
                  _buildFilterBar(),
                  const SizedBox(height: 24),
                  if (filteredAnnouncements.isEmpty)
                    _buildEmptyState()
                  else
                    ...filteredAnnouncements.asMap().entries.map((entry) {
                      final ann = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _buildAnnouncementCard(ann, entry.key),
                      );
                    }),
                ],
              ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final isStacked = MediaQuery.of(context).size.width < 860;
    return LuxuryModuleBanner(
      compact: isStacked,
      title: 'Manage Announcements',
      description:
          'Create and oversee public updates with the same polished card system as the alumni jobs experience.',
      icon: Icons.campaign_outlined,
      actions: [
        LuxuryBannerAction(
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          onPressed: fetchAnnouncements,
          iconOnly: !isStacked,
        ),
        LuxuryBannerAction(
          icon: Icons.add,
          label: 'Create New',
          onPressed: () => _showAnnouncementDialog(),
          filled: true,
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final events = announcements
        .where((ann) => (ann['category'] ?? '') == 'Events')
        .length;
    final jobOpportunities = announcements
        .where((ann) => (ann['category'] ?? '') == 'Job Opportunities')
        .length;
    final reminders = announcements
        .where((ann) => (ann['category'] ?? '') == 'Reminders')
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardWidth = availableWidth >= 980
            ? (availableWidth - 48) / 4
            : availableWidth >= 760
            ? (availableWidth - 16) / 2
            : double.infinity;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _statCard(
              "Total Posts",
              announcements.length.toString(),
              Icons.feed_outlined,
              primaryMaroon,
              cardWidth,
            ),
            _statCard(
              "Events",
              events.toString(),
              Icons.event_available_outlined,
              accentGold,
              cardWidth,
            ),
            _statCard(
              "Job Opportunities",
              jobOpportunities.toString(),
              Icons.work_outline,
              Colors.green,
              cardWidth,
            ),
            _statCard(
              "Reminders",
              reminders.toString(),
              Icons.notifications_active_outlined,
              Colors.teal,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final isNarrow = MediaQuery.of(context).size.width < 900;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: isNarrow
          ? Column(
              children: [
                _searchField(),
                const SizedBox(height: 12),
                _categoryDropdown(),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: _searchField()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _categoryDropdown()),
              ],
            ),
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (value) {
        setState(() {
          searchQuery = value;
          _applyFilters();
        });
      },
      decoration: InputDecoration(
        hintText: "Search announcements...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedCategory,
      items: [
        "All Categories",
        "Events",
        "Reminders",
        "Job Opportunities",
        "GENERAL",
      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          selectedCategory = value;
          _applyFilters();
        });
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(dynamic ann, int index) {
    final catColor = getCategoryColor(ann['category'] ?? "");
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryMaroon.withValues(alpha: 0.95), catColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.campaign_outlined, color: accentGold),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ann['title'] ?? "No Title",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: primaryMaroon,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              ann['category']?.toString() ?? "GENERAL",
                              style: TextStyle(
                                color: catColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _metaPill(
                            Icons.schedule_outlined,
                            (ann['created_at'] ?? ann['date'] ?? 'Recent')
                                .toString(),
                          ),
                          _metaPill(Icons.label_outline, "Post ${index + 1}"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      onPressed: () =>
                          _showAnnouncementDialog(announcement: ann),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _confirmDelete(ann['id'].toString()),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              ann['description'] ?? "",
              style: TextStyle(color: Colors.grey.shade700, height: 1.55),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primaryMaroon),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters =
        searchQuery.trim().isNotEmpty || selectedCategory != "All Categories";
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width < 500
            ? MediaQuery.of(context).size.width - 32
            : 420,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: softRose,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.campaign_outlined,
                color: primaryMaroon,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasFilters ? "No announcements found" : "No announcements yet",
              style: TextStyle(
                color: primaryMaroon,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? "Try changing the search term or category filter to see more announcements."
                  : "Create your first update for alumni and it will appear here in the new card layout.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
