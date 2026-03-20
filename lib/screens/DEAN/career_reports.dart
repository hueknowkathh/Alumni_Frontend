import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CareerReportsPage extends StatefulWidget {
  const CareerReportsPage({super.key});

  @override
  State<CareerReportsPage> createState() => _CareerReportsPageState();
}

class _CareerReportsPageState extends State<CareerReportsPage> {
  // Theme Colors
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color accentGold = const Color(0xFFC5A046);
  final Color bgLight = const Color(0xFFF7F8FA);

  // Filter States
  String selectedProgram = "BSIT";
  String selectedBatch = "2022";
  String selectedStatus = "All Status";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text("Career Reports", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.print_outlined)),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text("Export CSV/PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryMaroon,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 1. DYNAMIC FILTER SECTION
            _buildFilterSection(),
            const SizedBox(height: 24),

            /// 2. SUMMARY CARDS
            Row(
              children: [
                _buildSummaryCard("Graduates", "120", Icons.people, Colors.blue),
                const SizedBox(width: 12),
                _buildSummaryCard("Employed", "95", Icons.work, Colors.green),
                const SizedBox(width: 12),
                _buildSummaryCard("Unemployed", "15", Icons.person_off, Colors.red),
                const SizedBox(width: 12),
                _buildSummaryCard("Rate", "79%", Icons.trending_up, accentGold),
              ],
            ),
            const SizedBox(height: 24),

            /// 3. MAIN CHARTS GRID
            // A. Employment Rate (Full Width Bar Chart)
            _buildChartContainer(
              title: "Employment Rate per Batch (%)",
              child: _buildBarChart(),
              height: 300,
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // B. Industry Distribution (Pie)
                Expanded(
                  child: _buildChartContainer(
                    title: "Industry Distribution",
                    child: _buildPieChart(isIndustry: true),
                    height: 300,
                  ),
                ),
                const SizedBox(width: 24),
                // C. Salary Distribution (Bar)
                Expanded(
                  child: _buildChartContainer(
                    title: "Salary Distribution (PHP)",
                    child: _buildSalaryChart(),
                    height: 300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // D. Job Relevance (Pie)
                Expanded(
                  child: _buildChartContainer(
                    title: "Job Relevance",
                    child: _buildPieChart(isIndustry: false),
                    height: 300,
                  ),
                ),
                const SizedBox(width: 24),
                // E. Employment Classification (Bar)
                Expanded(
                  child: _buildChartContainer(
                    title: "Employment Classification",
                    child: _buildClassificationChart(),
                    height: 300,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// UI COMPONENT: Filter Bar
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined, color: Colors.grey),
          const SizedBox(width: 16),
          _buildDropdown("Program", selectedProgram, ["BSIT", "BSCS", "BSHM"], (v) => setState(() => selectedProgram = v!)),
          const SizedBox(width: 24),
          _buildDropdown("Batch", selectedBatch, ["2020", "2021", "2022"], (v) => setState(() => selectedBatch = v!)),
          const SizedBox(width: 24),
          _buildDropdown("Status", selectedStatus, ["All Status", "Employed", "Unemployed"], (v) => setState(() => selectedStatus = v!)),
          const Spacer(),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh),
            label: const Text("Refresh Data"),
            style: TextButton.styleFrom(foregroundColor: primaryMaroon),
          )
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        DropdownButton<String>(
          value: value,
          isDense: true,
          underline: const SizedBox(),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartContainer({required String title, required Widget child, required double height}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(child: child),
        ],
      ),
    );
  }

  /// --- CHART LOGIC (MOCK DATA) ---

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        backgroundColor: Colors.transparent,
        barGroups: [
          BarChartGroupData(x: 2020, barRods: [BarChartRodData(toY: 75, color: accentGold, width: 20)]),
          BarChartGroupData(x: 2021, barRods: [BarChartRodData(toY: 80, color: accentGold, width: 20)]),
          BarChartGroupData(x: 2022, barRods: [BarChartRodData(toY: 85, color: primaryMaroon, width: 20)]),
        ],
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
      ),
    );
  }

  Widget _buildPieChart({required bool isIndustry}) {
    return PieChart(
      PieChartData(
        sections: isIndustry 
        ? [
            PieChartSectionData(value: 40, color: primaryMaroon, title: 'IT', radius: 50, titleStyle: const TextStyle(color: Colors.white, fontSize: 10)),
            PieChartSectionData(value: 20, color: accentGold, title: 'Biz', radius: 50),
            PieChartSectionData(value: 15, color: Colors.blue, title: 'Edu', radius: 50),
            PieChartSectionData(value: 25, color: Colors.grey, title: 'Other', radius: 50),
          ]
        : [
            PieChartSectionData(value: 70, color: Colors.green, title: 'Related', radius: 50, titleStyle: const TextStyle(color: Colors.white)),
            PieChartSectionData(value: 30, color: Colors.red, title: 'Not Related', radius: 50, titleStyle: const TextStyle(color: Colors.white)),
          ],
      ),
    );
  }

  Widget _buildSalaryChart() {
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 10, color: Colors.grey)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 30, color: Colors.grey)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 35, color: primaryMaroon)]),
          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 25, color: accentGold)]),
        ],
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildClassificationChart() {
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 50, color: primaryMaroon)]), // Rank & File
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 20, color: Colors.blue)]),    // Supervisor
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 10, color: accentGold)]),    // Manager
        ],
        borderData: FlBorderData(show: false),
      ),
    );
  }
}