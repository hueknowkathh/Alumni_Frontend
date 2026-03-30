import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE0E0E0);

  bool isLoading = false;
  bool isSaving = false;
  List announcements = [];

  // ✅ ADD THIS HERE
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

  /// FETCH DATA
  Future<void> fetchAnnouncements() async {
    setState(() => isLoading = true);
    try {
      var url = ApiService.uri('get_announcements.php');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          announcements = decoded is List
              ? decoded
              : (decoded is Map ? decoded['announcements'] ?? [] : []);
        });
      }
    } catch (e) {
      debugPrint("Error fetching announcements: $e");
    }
    setState(() => isLoading = false);
  }

  /// SAVE (CREATE / UPDATE)
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

      debugPrint("SERVER RAW OUTPUT: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(response.body);

          if (result['status'] == 'success') {
            await fetchAnnouncements();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Announcement saved successfully"),
                  backgroundColor: Colors.green,
                ),
              );
            }

            setState(() => isSaving = false);
            return true;
          } else {
            _showError(result['message'] ?? "Unknown Error");
          }
        } catch (e) {
          debugPrint("Invalid JSON from server");
          _showError("Server Error: Invalid response.");
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

  /// DELETE
  Future<void> deleteAnnouncement(String id) async {
    try {
      final url = ApiService.uri(
        'delete_announcement.php',
        queryParameters: {'id': id},
      );

      final response = await http.post(url, body: {"id": id});

      debugPrint("DELETE RESPONSE: ${response.body}");

      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        await fetchAnnouncements();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("🗑️ Announcement deleted"),
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

  /// DIALOG (UNCHANGED UI)
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
      builder: (_) => AlertDialog(
        title: Text(isEditing ? "Edit Announcement" : "Create Announcement"),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: ["Events", "Reminders", "Job Opportunities", "GENERAL"]
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) => selectedCategory = value!,
                decoration: const InputDecoration(labelText: "Category"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryMaroon,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: isSaving
                ? null
                : () async {
                    bool success = await saveAnnouncement(
                      titleController.text,
                      descController.text,
                      selectedCategory,
                      id: isEditing ? announcement['id'] : null,
                    );

                    if (success && mounted) {
                      Navigator.pop(context); // ✅ only once
                    }
                  },
            child: isSaving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isEditing ? "Update" : "Post"),
          ),
        ],
      ),
    );
  }

  /// DELETE CONFIRM
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
    return Container(
      color: bgLight,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Manage Announcements",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryMaroon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Create and oversee public updates for the alumni portal.",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: fetchAnnouncements,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text("Refresh"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAnnouncementDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Create New"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryMaroon,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(indent: 32, endIndent: 32),

          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: primaryMaroon))
                : announcements.isEmpty
                ? Center(
                    child: Text(
                      "No announcements yet.",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      var ann = announcements[index];
                      Color catColor = getCategoryColor(ann['category'] ?? "");

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 4,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: catColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: catColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            ann['category']?.toUpperCase() ??
                                                "GENERAL",
                                            style: TextStyle(
                                              color: catColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ann['title'] ?? "No Title",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF2D3436),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      ann['description'] ?? "",
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    onPressed: () => _showAnnouncementDialog(
                                      announcement: ann,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _confirmDelete(ann['id'].toString()),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
