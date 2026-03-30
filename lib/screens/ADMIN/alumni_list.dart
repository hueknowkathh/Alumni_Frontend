import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../services/api_service.dart';

class AlumniList extends StatefulWidget {
  const AlumniList({super.key});

  @override
  State<AlumniList> createState() => _AlumniListState();
}

class _AlumniListState extends State<AlumniList> {
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE0E0E0);

  List<dynamic> allAlumni = [];
  List<dynamic> filteredAlumni = [];
  bool isLoading = true;
  Timer? _autoRefreshTimer;

  String searchQuery = "";
  String selectedProgram = "All Programs";
  String selectedYear = "All Years";

  @override
  void initState() {
    super.initState();
    fetchAlumni();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => fetchAlumni(showLoader: false),
    );
  }

  // ✅ FETCH: Get all verified alumni
  Future<void> fetchAlumni({bool showLoader = true}) async {
    if (showLoader) setState(() => isLoading = true);
    try {
      final response = await http.get(
        ApiService.uri('get_alumni_list.php'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          allAlumni = data;
          _applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar("Error connecting to server", Colors.red);
      setState(() => isLoading = false);
    }
  }

  // ✅ DELETE: Remove user from DB
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _deleteAlumni(String id, String name) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text(
          "Are you sure you want to remove $name? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.post(
          ApiService.uri('delete_alumni.php'),
          body: {"id": id.toString()},
        );
        final result = json.decode(response.body);
        if (result['success']) {
          _showSnackBar("Alumni $name deleted.", Colors.green);
          fetchAlumni();
        }
      } catch (e) {
        _showSnackBar("Failed to delete.", Colors.red);
      }
    }
  }

  // ✅ VIEW: Show Detail Popup
  void _viewAlumni(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.person, color: primaryMaroon),
            const SizedBox(width: 10),
            const Text("Alumni Profile"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Full Name", user['name']),
            _detailRow("Email", user['email']),
            _detailRow("Program", user['program']),
            _detailRow("Graduation Year", user['year']?.toString()),
            _detailRow("Employment Status", user['status']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      filteredAlumni = allAlumni.where((alumni) {
        final name = (alumni['name'] ?? "").toString().toLowerCase();
        final email = (alumni['email'] ?? "").toString().toLowerCase();
        final matchesSearch =
            name.contains(searchQuery.toLowerCase()) ||
            email.contains(searchQuery.toLowerCase());
        final matchesProgram =
            selectedProgram == "All Programs" ||
            alumni['program'] == selectedProgram;
        final matchesYear =
            selectedYear == "All Years" ||
            alumni['year'].toString() == selectedYear;
        return matchesSearch && matchesProgram && matchesYear;
      }).toList();
    });
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 14),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value ?? "N/A"),
          ],
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
                  const SizedBox(height: 32),
                  _buildFilterBar(),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Alumni List",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryMaroon,
              ),
            ),
            Text(
              "Manage verified graduates in the system.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: fetchAlumni,
          icon: const Icon(Icons.refresh),
          label: const Text("Refresh List"),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryMaroon,
            side: BorderSide(color: borderColor),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            onChanged: (val) {
              searchQuery = val;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: "Search name or email...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryMaroon),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildDropdown(
          selectedProgram,
          ["All Programs", "BSIT", "BSCS", "BSECE"],
          (val) {
            setState(() {
              selectedProgram = val!;
              _applyFilters();
            });
          },
        ),
        const SizedBox(width: 16),
        _buildDropdown(
          selectedYear,
          ["All Years", "2021", "2022", "2023", "2024"],
          (val) {
            setState(() {
              selectedYear = val!;
              _applyFilters();
            });
          },
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String val,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
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
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(bgLight),
        columns: const [
          DataColumn(label: Text("NAME")),
          DataColumn(label: Text("PROGRAM")),
          DataColumn(label: Text("YEAR")),
          DataColumn(label: Text("STATUS")),
          DataColumn(label: Text("ACTIONS")),
        ],
        rows: filteredAlumni
            .map(
              (user) => DataRow(
                cells: [
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user['name'] ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user['email'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(user['program'] ?? 'N/A')),
                  DataCell(Text(user['year']?.toString() ?? 'N/A')),
                  DataCell(_statusBadge(user['status'] ?? 'N/A')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.visibility_outlined,
                            color: Colors.blue,
                          ),
                          onPressed: () => _viewAlumni(user),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteAlumni(
                            user['id'].toString(),
                            user['name'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = status == "Employed"
        ? Colors.green
        : (status == "Unemployed" ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
