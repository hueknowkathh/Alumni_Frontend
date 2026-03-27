import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TracerDataPage extends StatefulWidget {
  const TracerDataPage({super.key});

  @override
  State<TracerDataPage> createState() => _TracerDataPageState();
}

class _TracerDataPageState extends State<TracerDataPage> {
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE0E0E0);

  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = true;

  String selectedStatus = "All Status";
  String selectedRelated = "All Degree Related";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTracerData();
  }

  Future<void> _fetchTracerData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("http://localhost/alumni_php/get_tracer_submissions.php"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          _allData = jsonData.map((item) => Map<String, dynamic>.from(item)).toList();
          _filteredList = _allData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _runFilter() {
    setState(() {
      _filteredList = _allData.where((item) {
        final name = (item['full_name'] ?? "").toString().toLowerCase();
        final query = _searchController.text.toLowerCase();

        final matchesSearch = name.contains(query);
        final matchesStatus =
            selectedStatus == "All Status" || item['employment_status'] == selectedStatus;
        final matchesRelated =
            selectedRelated == "All Degree Related" || item['job_related'] == selectedRelated;

        return matchesSearch && matchesStatus && matchesRelated;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgLight,
      width: double.infinity,
      child: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryMaroon))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildAnalyticsCards(),
                  const SizedBox(height: 32),
                  _buildFilterAndSearchBar(),
                  const SizedBox(height: 24),
                  _filteredList.isEmpty
                      ? const Center(
                          child: Padding(
                          padding: EdgeInsets.all(50.0),
                          child: Text("No data found."),
                        ))
                      : _buildTracerTable(),
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
            Text("Tracer Submissions",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryMaroon)),
            const SizedBox(height: 4),
            Text("Monitoring outcomes for ${_allData.length} alumni responses.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
        OutlinedButton.icon(
          onPressed: _fetchTracerData,
          icon: const Icon(Icons.refresh),
          label: const Text("Refresh Data"),
          style: OutlinedButton.styleFrom(foregroundColor: primaryMaroon),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCards() {
    int total = _allData.length;
    int employed = _allData.where((e) => e['employment_status'] == "Employed").length;
    int selfEmployed = _allData.where((e) => e['employment_status'] == "Self-Employed").length;
    int unemployed = _allData.where((e) => e['employment_status'] == "Unemployed").length;

    return Row(
      children: [
        _statCard("Total Responses", total.toString(), Icons.people, Colors.blue),
        const SizedBox(width: 16),
        _statCard("Employed", employed.toString(), Icons.work, Colors.green),
        const SizedBox(width: 16),
        _statCard("Self-Employed", selfEmployed.toString(), Icons.storefront, Colors.purple),
        const SizedBox(width: 16),
        _statCard("Unemployed", unemployed.toString(), Icons.person_off, Colors.red),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterAndSearchBar() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _searchController,
            onChanged: (val) => _runFilter(),
            decoration: InputDecoration(
              hintText: "Search alumni by name...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _dropdown("Status", selectedStatus,
            ["All Status", "Employed", "Self-Employed", "Unemployed"], (val) {
          setState(() {
            selectedStatus = val!;
            _runFilter();
          });
        }),
        const SizedBox(width: 12),
        _dropdown("Related", selectedRelated,
            ["All Degree Related", "Yes", "Somewhat", "No"], (val) {
          setState(() {
            selectedRelated = val!;
            _runFilter();
          });
        }),
      ],
    );
  }

  Widget _dropdown(String hint, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTracerTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor)),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(bgLight),
        columns: const [
          DataColumn(label: Text("ALUMNI NAME")),
          DataColumn(label: Text("STATUS")),
          DataColumn(label: Text("JOB TITLE")),
          DataColumn(label: Text("RELATED")),
          DataColumn(label: Text("ACTION")),
        ],
        rows: _filteredList.map((data) {
          final isUnemployed = data['employment_status'] == "Unemployed";

          return DataRow(cells: [
            DataCell(Text(data['full_name'] ?? "N/A",
                style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(_statusBadge(data['employment_status'] ?? "N/A")),

            // ✅ FIX: Hide job title if unemployed
            DataCell(Text(isUnemployed ? "—" : (data['job_title'] ?? "N/A"))),

            DataCell(Text(data['job_related'] ?? "N/A")),
            DataCell(IconButton(
              icon: const Icon(Icons.visibility, color: Colors.blue),
              onPressed: () => _showTracerDetails(data),
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.grey;
    if (status == "Employed") color = Colors.green;
    if (status == "Self-Employed") color = Colors.purple;
    if (status == "Unemployed") color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  void _showTracerDetails(Map<String, dynamic> data) {
  final isUnemployed = data['employment_status'] == "Unemployed";
  final isNotRelated = data['job_related']?.toString().toLowerCase() == "no";
  final isWantMoreHours = data['want_more_hours']?.toString().toLowerCase() == "yes";

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Tracer Details: ${data['full_name'] ?? 'Unknown'}"),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailSection("Graduate Profile", [
                _detailRow("Sex", data['sex']),
                _detailRow("Age", data['age']),
                _detailRow("Civil Status", data['civil_status']),
                _detailRow("Contact", data['contact_number']),
                _detailRow("Address", data['address']),
                _detailRow("Year Graduated", data['year_graduated']),
                _detailRow("Honors / Awards", data['honors']),
                _detailRow("Pre-graduation Experience", data['pre_grad_experience']),
                _detailRow("Study Mode", data['study_mode']),


              ]),

              const Divider(height: 32),

              _detailSection("Employment Info", [
                _detailRow("Status", data['employment_status']),

                if (!isUnemployed) ...[
                  _detailRow("Time to First Employment", data['first_job_timing']),
                  _detailRow("First Job Related to Degree", data['first_job_related']),
                  _detailRow("Employment Type", data['employment_type']),
                  _detailRow("Job Title", data['job_title']),
                  _detailRow("Company/Organization", data['company_name']),
                  _detailRow("Sector", data['sector']),
                  _detailRow("Country of Work", data['country']),
                  _detailRow("Income", data['income_range']),
                  _detailRow("Related to Degree", data['job_related']),
                  if (isNotRelated)
                    _detailRow("Reason for working outside field", data['not_related_reason']),
                  _detailRow("How long in current position?", data['job_duration']),
                  _detailRow("Promoted since first job?", data['promotion']),
                  _detailRow("Would you like to work more hours?", data['want_more_hours']),

                  if (isWantMoreHours)
                    _detailRow("Reason for seeking more hours", data['more_hours_reason']),
                  
                  _detailRow("Employment Classification", data['classification']),
                  _detailRow("Job Satisfaction", data['satisfaction']),
                ],

                if (isUnemployed)
                  _detailRow("Reason", data['unemployment_reason']),
              ]),

              const Divider(height: 32),
              _detailRow("Submitted On", data['submitted_at']),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
      ],
    ),
  );
}


  Widget _detailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryMaroon, fontSize: 16)),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
              child: Text(value?.toString() ?? "N/A",
                  style: TextStyle(color: Colors.grey.shade800))),
        ],
      ),
    );
  }
}