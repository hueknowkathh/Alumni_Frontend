import 'package:flutter/material.dart';

class AlumniManagementPage extends StatefulWidget {
  const AlumniManagementPage({super.key});

  @override
  State<AlumniManagementPage> createState() => _AlumniManagementPageState();
}

class _AlumniManagementPageState extends State<AlumniManagementPage> {
  final Color primaryMaroon = const Color(0xFF420031);
  final Color accentGold = const Color(0xFFB08900);
  final Color bgGrey = const Color(0xFFF8F9FA);

  String _selectedStatus = "All Statuses";
  String _selectedVerification = "All Verification";

  // Data structure expanded with Admin-only fields
  final List<Map<String, dynamic>> _allAlumni = [
    {
      "name": "John Smith",
      "batch": "Batch 2020",
      "course": "BS Information Technology",
      "birthDate": "January 15, 1998",
      "gender": "Male",
      "email": "john.smith@university.edu",
      "contact": "+63 912 345 6789",
      "employment": "Employed",
      "verification": "Verified",
      "position": "Software Engineer",
      "company": "Tech Corp",
      "industry": "Technology",
    },
    {
      "name": "Sarah Johnson",
      "batch": "Batch 2020",
      "course": "BS Computer Science",
      "birthDate": "March 22, 1999",
      "gender": "Female",
      "email": "s.johnson@corporate.com",
      "contact": "+63 922 888 1111",
      "employment": "Employed",
      "verification": "Verified",
      "position": "Data Analyst",
      "company": "Data Solutions",
      "industry": "Data Science",
    },
  ];

  List<Map<String, dynamic>> _foundAlumni = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _foundAlumni = _allAlumni;
    super.initState();
  }

  void _runFilter() {
    String keyword = _searchController.text.toLowerCase();
    setState(() {
      _foundAlumni = _allAlumni.where((user) {
        // Null-safe search to prevent red screen crashes
        String name = (user["name"] ?? "").toLowerCase();
        String batch = (user["batch"] ?? "").toLowerCase();
        
        bool matchesSearch = name.contains(keyword) || batch.contains(keyword);
        bool matchesStatus = _selectedStatus == "All Statuses" || user["employment"] == _selectedStatus;
        bool matchesVerify = _selectedVerification == "All Verification" || user["verification"] == _selectedVerification;
        return matchesSearch && matchesStatus && matchesVerify;
      }).toList();
    });
  }

  // UPDATED MODAL: Added Gender, Course, Birth Date, Contact, and Email
  void _showAlumniProfile(Map<String, dynamic> alumni) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 550, // Slightly wider for admin details
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Alumni Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryMaroon)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20)),
                  ],
                ),
                const SizedBox(height: 30),
                
                // PERSONAL INFO SECTION
                Row(
                  children: [
                    Expanded(child: _infoField("Name", alumni['name'] ?? "N/A")),
                    Expanded(child: _infoField("Course", alumni['course'] ?? "N/A")),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _infoField("Batch", alumni['batch'] ?? "N/A")),
                    Expanded(child: _infoField("Gender", alumni['gender'] ?? "N/A")),
                    Expanded(child: _infoField("Birth Date", alumni['birthDate'] ?? "N/A")),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _infoField("Email", alumni['email'] ?? "N/A")),
                    Expanded(child: _infoField("Contact Info", alumni['contact'] ?? "N/A")),
                  ],
                ),

                const Padding(padding: EdgeInsets.symmetric(vertical: 25), child: Divider()),

                // EMPLOYMENT INFO SECTION
                Text("Current Employment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryMaroon)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _infoField("Position", alumni['position'] ?? "N/A")),
                    Expanded(child: _infoField("Company", alumni['company'] ?? "N/A")),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _infoField("Industry", alumni['industry'] ?? "N/A")),
                    Expanded(child: _badgeField("Employment Status", alumni['employment'] ?? "N/A", const Color(0xFFE6F4EA), Colors.green)),
                  ],
                ),
                const SizedBox(height: 20),
                _badgeField("Verification Status", alumni['verification'] ?? "N/A", const Color(0xFFFEF7E0), accentGold),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Department Alumni", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryMaroon)),
            const Text("View and search alumni under your department", style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 35),

            // SEARCH & FILTER
            _buildSearchAndFilter(),

            const SizedBox(height: 30),

            // DATA TABLE
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFFAFAFA)),
                dataRowMinHeight: 65,
                dataRowMaxHeight: 65,
                columns: const [
                  DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  DataColumn(label: Text('Batch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  DataColumn(label: Text('Employment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  DataColumn(label: Text('Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                ],
                rows: _foundAlumni.map((alumni) => DataRow(cells: [
                  DataCell(Text(alumni['name'] ?? "N/A")),
                  DataCell(Text(alumni['batch'] ?? "N/A")),
                  DataCell(_statusBadge(alumni['employment'] ?? "N/A", alumni['employment'] == "Employed" ? const Color(0xFFE6F4EA) : const Color(0xFFF1F3F4), alumni['employment'] == "Employed" ? Colors.green : Colors.black54)),
                  DataCell(_statusBadge(alumni['verification'] ?? "N/A", const Color(0xFFFEF7E0), accentGold)),
                  DataCell(
                    TextButton.icon(
                      onPressed: () => _showAlumniProfile(alumni),
                      icon: Icon(Icons.visibility_outlined, size: 16, color: primaryMaroon),
                      label: Text("View", style: TextStyle(color: primaryMaroon, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ])).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER COMPONENTS ---

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Search & Filter", style: TextStyle(fontWeight: FontWeight.bold, color: primaryMaroon, fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _runFilter(),
                  decoration: InputDecoration(
                    hintText: "Search by name or batch...",
                    prefixIcon: const Icon(Icons.search, size: 18),
                    filled: true,
                    fillColor: bgGrey,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(child: _dropdownFilter(["All Statuses", "Employed", "Unemployed"], _selectedStatus, (v) => setState(() => _selectedStatus = v!))),
              const SizedBox(width: 15),
              Expanded(child: _dropdownFilter(["All Verification", "Verified", "Pending"], _selectedVerification, (v) => setState(() => _selectedVerification = v!))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownFilter(List<String> items, String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: bgGrey, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) {
            onChanged(v);
            _runFilter();
          },
        ),
      ),
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _badgeField(String label, String value, Color bgColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        _statusBadge(value, bgColor, textColor),
      ],
    );
  }

  Widget _statusBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
  Widget _iconButton(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(border: Border.all(color: Colors.black26), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 5), Text(label)]),
    );
  }
