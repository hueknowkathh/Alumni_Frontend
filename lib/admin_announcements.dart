import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _announcements = [];
  List<dynamic> _surveys = [];
  bool _isLoadingAnnouncements = true;
  bool _isLoadingSurveys = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAnnouncements();
    fetchSurveys();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------- FETCH ----------------
  Future<void> fetchAnnouncements() async {
    setState(() => _isLoadingAnnouncements = true);
    final url = 'http://localhost:8080/alumni_api/get_announcementsadmin.php';
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          _announcements = json.decode(res.body);
          _isLoadingAnnouncements = false;
        });
      } else {
        setState(() => _isLoadingAnnouncements = false);
      }
    } catch (e) {
      print("Error fetching announcements: $e");
      setState(() => _isLoadingAnnouncements = false);
    }
  }

  Future<void> fetchSurveys() async {
    setState(() => _isLoadingSurveys = true);
    final url = 'http://localhost:8080/alumni_api/get_surveys.php';
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        setState(() {
          _surveys = json.decode(res.body);
          _isLoadingSurveys = false;
        });
      } else {
        setState(() => _isLoadingSurveys = false);
      }
    } catch (e) {
      print("Error fetching surveys: $e");
      setState(() => _isLoadingSurveys = false);
    }
  }

  // ---------------- ADD ----------------
  Future<void> addAnnouncement(Map<String, dynamic> data) async {
    final url = 'http://localhost:8080/alumni_api/add_announcement.php';
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      final response = json.decode(res.body);
      if (res.statusCode == 200 && response['status'] == 'success') {
        fetchAnnouncements();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Announcement added!")),
        );
      }
    } catch (e) {
      print("Add announcement error: $e");
    }
  }

  Future<void> addSurvey(Map<String, dynamic> data) async {
    final url = 'http://localhost:8080/alumni_api/add_survey.php';
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      final response = json.decode(res.body);
      if (res.statusCode == 200 && response['status'] == 'success') {
        fetchSurveys();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Survey added!")),
        );
      }
    } catch (e) {
      print("Add survey error: $e");
    }
  }

  // ---------------- DELETE ----------------
  Future<void> deleteAnnouncement(dynamic announcementId) async {
  // Ensure the ID is numeric
  int id;
  try {
    id = int.parse(announcementId.toString());
  } catch (e) {
    print("Invalid announcement ID: $announcementId");
    return;
  }

  print("Trying to delete announcement id=$id");

  final url = 'http://localhost:8080/alumni_api/delete_announcement.php';

  try {
    final res = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'id': id}),
    );

    print("Server response: ${res.body}");

    final response = json.decode(res.body);

    if (response['status'] == 'success') {
      // Remove the deleted announcement from the list immediately
      setState(() {
        _announcements.removeWhere((a) => int.parse(a['id'].toString()) == id);
      });
      print("Announcement $id deleted successfully");
    } else {
      print("Failed to delete announcement: ${response['message']}");
    }
  } catch (e) {
    print("Delete announcement error: $e");
  }
}

  Future<void> deleteSurvey(dynamic surveyId) async {
  // Ensure the ID is numeric
  int id;
  try {
    id = int.parse(surveyId.toString());
  } catch (e) {
    print("Invalid survey ID: $surveyId");
    return;
  }

  print("Trying to delete survey id=$id");

  final url = 'http://localhost:8080/alumni_api/delete_survey.php';

  try {
    final res = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'id': id}),
    );

    print("Server response: ${res.body}");

    final response = json.decode(res.body);

    if (response['status'] == 'success') {
      // Remove the deleted survey from the list immediately
      setState(() {
        _surveys.removeWhere((s) => int.parse(s['id'].toString()) == id);
      });
      print("Survey $id deleted successfully");
    } else {
      print("Failed to delete survey: ${response['message']}");
    }
  } catch (e) {
    print("Delete survey error: $e");
  }
}

  // ---------------- UI HELPERS ----------------
  Map<String, Color> _getTheme(String type) {
    if (type == "Event" || type == "Active") {
      return {"bg": const Color(0xFFFFEAEA), "icon": const Color(0xFFFF4D4D)};
    }
    return {"bg": const Color(0xFFF3E5F5), "icon": const Color(0xFF6C5DD3)};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 25),
            Row(
              children: [
                _statBox("Total Posts", _announcements.length.toString()),
                _statBox(
                  "Active Surveys",
                  _surveys.where((s) => s['status'] == "Active").length.toString(),
                ),
                _statBox("Engagement", "2.1k"),
              ],
            ),
            const SizedBox(height: 25),
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF420031),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFD4A017),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: "Announcements & Events"),
                Tab(text: "Tracer Studies & Surveys"),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAnnouncementsList(),
                  _buildSurveysList(),
                ],
              ),
            ),
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
              "Communication Hub",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF420031)),
            ),
            Text(
              "Manage university announcements and tracer study data",
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4A017),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: _showEntryDialog,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Create New",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _statBox(String title, String count) {
    return Expanded(
      child: Container(
        height: 90,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF420031))),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    if (_isLoadingAnnouncements) return const Center(child: CircularProgressIndicator());
    if (_announcements.isEmpty) return const Center(child: Text("No announcements found."));
    return ListView.builder(
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final item = _announcements[index];
        final theme = _getTheme(item['type']);
        return _buildActionCard(
          title: item['title'],
          subtitle: item['description'] ?? "",
          meta: "By ${item['author']} • ${item['date_created'] ?? item['date']}",
          icon: item['type'] == "Event" ? Icons.event : Icons.campaign,
          theme: theme,
          onDelete: () => deleteAnnouncement(item['id']),
        );
      },
    );
  }

  Widget _buildSurveysList() {
    if (_isLoadingSurveys) return const Center(child: CircularProgressIndicator());
    if (_surveys.isEmpty) return const Center(child: Text("No surveys found."));
    return ListView.builder(
      itemCount: _surveys.length,
      itemBuilder: (context, index) {
        final survey = _surveys[index];
        final theme = _getTheme(survey['status']);
        return _buildActionCard(
          title: survey['title'],
          subtitle: "${survey['responses']} Responses Collected",
          meta: "Created: ${survey['date_created']} • Status: ${survey['status']}",
          icon: Icons.poll_rounded,
          theme: theme,
          onDelete: () => deleteSurvey(survey['id']),
        );
      },
    );
  }

  Widget _buildActionCard({
  required String title,
  required String subtitle,
  required String meta,
  required IconData icon,
  required Map<String, Color> theme,
  required VoidCallback onDelete,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.black12),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: theme['bg'], borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: theme['icon']),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text(meta, style: const TextStyle(color: Colors.black26, fontSize: 11)),
            ],
          ),
        ),
        // Buttons row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () {
                print("Edit pressed for: $title");
                // Add your edit logic here
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ],
    ),
  );
}
  void _showEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create New Content"),
        content: const Text("Would you like to publish a new Announcement or start a new Tracer Study Survey?"),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(context);
            _showAnnouncementForm();
          }, child: const Text("Announcement")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSurveyForm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4A017)),
            child: const Text("Survey", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementForm() {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    String type = 'Announcement';
    String eventDate = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("New Announcement"),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Title"),
                      validator: (val) => val == null || val.isEmpty ? "Enter title" : null,
                      onSaved: (val) => title = val!,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: "Description"),
                      validator: (val) => val == null || val.isEmpty ? "Enter description" : null,
                      onSaved: (val) => description = val!,
                    ),
                    DropdownButtonFormField<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(value: 'Announcement', child: Text('Announcement')),
                        DropdownMenuItem(value: 'Event', child: Text('Event')),
                      ],
                      onChanged: (val) => setStateDialog(() => type = val ?? 'Announcement'),
                      decoration: const InputDecoration(labelText: "Type"),
                    ),
                    if (type == 'Event')
                      TextFormField(
                        decoration: const InputDecoration(labelText: "Event Date"),
                        onSaved: (val) => eventDate = val ?? '',
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    addAnnouncement({
                      'title': title,
                      'description': description,
                      'type': type,
                      'event_date': eventDate,
                      'author': 'Admin',
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          );
        });
      },
    );
  }

  void _showSurveyForm() {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    String status = 'Active';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Survey"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: "Title"),
                validator: (val) => val == null || val.isEmpty ? "Enter title" : null,
                onSaved: (val) => title = val!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: "Description"),
                validator: (val) => val == null || val.isEmpty ? "Enter description" : null,
                onSaved: (val) => description = val!,
              ),
              DropdownButtonFormField<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: 'Active', child: Text('Active')),
                  DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                ],
                onChanged: (val) => status = val ?? 'Active',
                decoration: const InputDecoration(labelText: "Status"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                addSurvey({
                  'title': title,
                  'description': description,
                  'status': status,
                  'responses': 0,
                  'date_created': DateTime.now().toIso8601String().substring(0, 19).replaceAll('T', ' '),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }
}