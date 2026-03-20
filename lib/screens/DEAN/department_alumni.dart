import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Add this import
import 'dart:convert';

class DepartmentAlumniPage extends StatefulWidget {
  const DepartmentAlumniPage({super.key});

  @override
  State<DepartmentAlumniPage> createState() => _DepartmentAlumniPageState();
}

class _DepartmentAlumniPageState extends State<DepartmentAlumniPage> {
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color bgLight = const Color(0xFFF7F8FA);
  final Color accentGold = const Color(0xFFC5A046);

  // Filter States
  String selectedProgram = "BSIT";
  String selectedBatch = "2022";
  String selectedStatus = "All Status";

  // Data State
  List<dynamic> _filteredAlumni = [];
  Map<String, dynamic> _summary = {
    "total_graduates": 0,
    "employed": 0,
    "employment_rate": "0%",
    "job_alignment": "0%"
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlumniData(); // Initial load
  }

  // --- NEW LIVE FETCH METHOD ---
  Future<void> _fetchAlumniData() async {
    setState(() => _isLoading = true);
    try {
      // Construct URL with query parameters for filtering
      final String url = "http://localhost:8080/alumni_php/get_department_alumni.php"
          "?program=$selectedProgram"
          "&batch=$selectedBatch"
          "&status=$selectedStatus";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _filteredAlumni = data['alumni'];
          _summary = data['summary'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to connect to server")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 1. HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Department Alumni Analysis", 
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    Text("Supporting Accreditation & Program Monitoring • $selectedProgram", 
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {}, // Export PDF Logic here
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text("Export Accreditation Report"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryMaroon,
                    side: BorderSide(color: primaryMaroon.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                ),
              ],
            ),
          ),

          /// 2. DYNAMIC METRIC CARDS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                _buildMetricCard("Total Graduates", "${_summary['total_graduates']}", Icons.people, Colors.blue),
                const SizedBox(width: 16),
                _buildMetricCard("Employed", "${_summary['employed']}", Icons.work, Colors.green),
                const SizedBox(width: 16),
                _buildMetricCard("Employment Rate", "${_summary['employment_rate']}", Icons.trending_up, accentGold),
                const SizedBox(width: 16),
                _buildMetricCard("Job Alignment", "${_summary['job_alignment']}", Icons.check_circle_outline, Colors.purple),
              ],
            ),
          ),

          /// 3. FILTER BAR
          _buildFilterBar(),

          /// 4. DATA TABLE (LIVE)
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: primaryMaroon))
                : _filteredAlumni.isEmpty 
                    ? const Center(child: Text("No records found."))
                    : _buildDataTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FA)),
                  columns: const [
                    DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Year", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text("Company/Organization", style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Center(child: Text("Job Alignment", style: TextStyle(fontWeight: FontWeight.bold)))),
                  ],
                  rows: _filteredAlumni.map((a) => DataRow(cells: [
                    DataCell(Text(a['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(Text(a['year'].toString())),
                    DataCell(_buildStatusBadge(a['status'] ?? 'N/A')),
                    DataCell(Text(a['company'] ?? 'N/A')),
                    DataCell(
                      Center(
                        child: Icon(
                          a['alignment'] == true ? Icons.verified : Icons.help_outline,
                          color: a['alignment'] == true ? Colors.green : Colors.grey,
                          size: 18,
                        ),
                      ),
                    ),
                  ])).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UPDATED FILTER BAR TO TRIGGER FETCH ---
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(8), 
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Row(children: [
        _buildDropdownFilter("Program", selectedProgram, ["BSIT", "BSCS", "BSHM"], (v) => setState(() => selectedProgram = v!)),
        const SizedBox(width: 24),
        _buildDropdownFilter("Batch", selectedBatch, ["2021", "2022", "2023"], (v) => setState(() => selectedBatch = v!)),
        const SizedBox(width: 24),
        _buildDropdownFilter("Status", selectedStatus, ["All Status", "Employed", "Unemployed", "Further Studies"], (v) => setState(() => selectedStatus = v!)),
        const Spacer(),
        ElevatedButton(
          onPressed: _fetchAlumniData, // Triggers Live Fetch
          style: ElevatedButton.styleFrom(backgroundColor: primaryMaroon, foregroundColor: Colors.white),
          child: const Text("Apply Filter"),
        ),
      ]),
    );
  }

  // UI Helpers (Same as your original code)
  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border(bottom: BorderSide(color: color, width: 3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildDropdownFilter(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
      DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        isDense: true,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    ]);
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == "Employed" ? Colors.green : (status == "Unemployed" ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}