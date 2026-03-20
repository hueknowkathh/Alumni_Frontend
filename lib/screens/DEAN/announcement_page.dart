import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  static const Color primaryMaroon = Color(0xFF4A152C);
  static const Color lightBackground = Color(0xFFF7F8FA);

  List announcements = [];
  List filteredAnnouncements = [];

  String selectedCategory = "All Categories";
  String searchQuery = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAnnouncements();
  }

  // ✅ FETCH FROM API
  Future<void> fetchAnnouncements() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // Ensure this URL is accessible from your device/emulator
      var url = Uri.parse("http://localhost:8080/alumni_php/get_announcements.php");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        final List decodedData = json.decode(response.body);
        setState(() {
          announcements = decodedData;
          applyFilters();
        });
      }
    } catch (e) {
      debugPrint("Error fetching announcements: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ✅ FILTER LOGIC
  void applyFilters() {
    setState(() {
      filteredAnnouncements = announcements.where((ann) {
        // Null safety: use ?? "" to prevent crashes if a field is null
        final String title = (ann['title'] ?? "").toString().toLowerCase();
        final String category = (ann['category'] ?? "General").toString();
        
        final matchesSearch = title.contains(searchQuery.toLowerCase());
        final matchesCategory = selectedCategory == "All Categories"
            ? true
            : category == selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  // 🎨 CATEGORY COLOR
  Color getCategoryColor(String category) {
    switch (category) {
      case "Events": return Colors.blue;
      case "Reminders": return Colors.orange;
      case "Job Opportunities": return Colors.green;
      default: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: lightBackground,
      child: RefreshIndicator(
        onRefresh: fetchAnnouncements,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Announcements",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Stay updated with the latest news and events from the alumni office",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 32),

              /// SEARCH + FILTER ROW
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      onChanged: (value) {
                        searchQuery = value;
                        applyFilters();
                      },
                      decoration: InputDecoration(
                        hintText: "Search announcements...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      items: ["All Categories", "Events", "Reminders", "Job Opportunities"]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          selectedCategory = value;
                          applyFilters();
                        }
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              /// LIST SECTION
              isLoading
                  ? const Center(child: Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: CircularProgressIndicator(color: primaryMaroon),
                    ))
                  : filteredAnnouncements.isEmpty
                      ? const Center(child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Text("No announcements found"),
                        ))
                      : Column(
                          children: filteredAnnouncements.map((ann) {
                            return _buildAnnouncementCard(
                              title: ann['title'] ?? "No Title",
                              // date maps to created_at in your DB
                              date: ann['date'] ?? "Recent", 
                              category: ann['category'] ?? "General",
                              // description maps to content in your DB
                              description: ann['description'] ?? "No description provided.",
                            );
                          }).toList(),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  // 🧾 CARD WIDGET
  Widget _buildAnnouncementCard({
    required String title,
    required String date,
    required String category,
    required String description,
  }) {
    final color = getCategoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.campaign_outlined, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(date, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
          ),
        ],
      ),
    );
  }
}