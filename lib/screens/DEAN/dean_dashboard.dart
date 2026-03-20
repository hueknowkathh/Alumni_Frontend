import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DeanDashboard extends StatefulWidget {
  const DeanDashboard({super.key});

  @override
  State<DeanDashboard> createState() => _DeanDashboardState();
}

class _DeanDashboardState extends State<DeanDashboard> {
  static const Color primaryMaroon = Color(0xFF4A152C);
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color accentGold = Color(0xFFC5A046);
  
  String _selectedDept = "All Departments";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 1100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 1. WELCOME & FILTER SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dean Oversight Overview",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          "Comprehensive analytics for alumni employment and departmental growth.",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    // Department Dropdown Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDept,
                          items: ["All Departments", "CICS", "CTE", "CBA", "CAS"]
                              .map((dept) => DropdownMenuItem(value: dept, child: Text(dept, style: const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedDept = val!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                /// 2. ANALYTICS CARDS (Total Alumni, Employment Rate, etc.)
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    _buildStatCard("Total Alumni", "1,284", Icons.people_alt_outlined, Colors.blue, constraints.maxWidth),
                    _buildStatCard("Employment Rate", "88%", Icons.trending_up, Colors.green, constraints.maxWidth),
                    _buildStatCard("Unemployment", "12%", Icons.trending_down, Colors.redAccent, constraints.maxWidth),
                    _buildStatCard("Submissions", "942", Icons.assignment_turned_in_outlined, accentGold, constraints.maxWidth),
                  ],
                ),
                const SizedBox(height: 32),

                /// 3. BATCH EMPLOYMENT (Full Width Bar Chart)
                _buildDashboardSection(
                  title: "Employment Rate Per Batch",
                  child: SizedBox(
                    height: 300,
                    child: _buildBarChart(),
                  ),
                ),
                const SizedBox(height: 32),

                /// 4. INDUSTRY & TOP EMPLOYERS (Responsive Row)
                Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: _buildDashboardSection(
                        title: "Industry Distribution",
                        child: SizedBox(
                          height: 300,
                          child: _buildPieChart(),
                        ),
                      ),
                    ),
                    if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: _buildDashboardSection(
                        title: "Top Employers",
                        child: Column(
                          children: [
                            _buildEmployerItem("Google Philippines", "45 Alumni", Colors.blue),
                            _buildEmployerItem("Accenture", "38 Alumni", Colors.purple),
                            _buildEmployerItem("Department of IT", "22 Alumni", Colors.orange),
                            _buildEmployerItem("BDO Unibank", "18 Alumni", Colors.blue.shade900),
                            _buildEmployerItem("Globe Telecom", "15 Alumni", Colors.red),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                /// 5. SALARY & JOB RELEVANCE (Responsive Row)
                Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildDashboardSection(
                        title: "Salary Distribution",
                        child: Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: lightBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bar_chart, color: Colors.grey),
                                Text("Salary Range (20k - 50k+) Histogram", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isWide) const SizedBox(width: 24) else const SizedBox(height: 24),
                    Expanded(
                      flex: 1,
                      child: _buildDashboardSection(
                        title: "Job Relevance",
                        child: Container(
                          height: 250,
                          decoration: BoxDecoration(
                            color: lightBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.donut_large, color: Colors.grey),
                                Text("Related (82%) vs. Unrelated (18%) Chart", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// PIE CHART: Industry Distribution
  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 50,
        sections: [
          PieChartSectionData(value: 40, color: Colors.blue, title: 'IT (40%)', radius: 60, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(value: 20, color: Colors.green, title: 'Fin (20%)', radius: 60, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(value: 15, color: accentGold, title: 'Gov (15%)', radius: 60, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(value: 25, color: primaryMaroon, title: 'Other (25%)', radius: 60, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  /// EMPLOYER LIST ITEM
  Widget _buildEmployerItem(String name, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(width: 4, height: 35, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          Text(count, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// STAT CARD
  Widget _buildStatCard(String label, String value, IconData icon, Color color, double totalWidth) {
    double cardWidth = (totalWidth - 64 - (20 * 3)) / 4;
    if (totalWidth < 1100) cardWidth = (totalWidth - 64 - 20) / 2;
    if (totalWidth < 600) cardWidth = totalWidth - 64;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 20),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// BAR CHART: Batch Employment
  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const batches = ['2022', '2023', '2024', '2025'];
                return (value >= 0 && value < batches.length)
                    ? Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(batches[value.toInt()], style: const TextStyle(fontSize: 12, color: Colors.grey)))
                    : const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text("${v.toInt()}%", style: const TextStyle(fontSize: 11, color: Colors.grey)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        barGroups: [
          _makeGroupData(0, 75),
          _makeGroupData(1, 82),
          _makeGroupData(2, 65),
          _makeGroupData(3, 88),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x, 
      barRods: [
        BarChartRodData(
          toY: y, 
          color: primaryMaroon, 
          width: 40, 
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: lightBackground),
        )
      ],
    );
  }

  /// SECTION WRAPPER
  Widget _buildDashboardSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}