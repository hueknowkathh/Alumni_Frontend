import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CareerOverviewPage extends StatefulWidget {
  const CareerOverviewPage({super.key});

  @override
  State<CareerOverviewPage> createState() => _CareerOverviewPageState();
}

class _CareerOverviewPageState extends State<CareerOverviewPage> {
  // Theme Setup
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color accentGold = const Color(0xFFC5A046);
  final Color bgLight = const Color(0xFFF7F8FA);

  // Mock Data
  Map<String, dynamic> data = {
    "total": 500,
    "employed": 380,
    "unemployed": 70,
    "further_studies": 50,
    "employment_rate": 76.0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Career Overview",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              "Summary of alumni career outcomes",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      // FIX 1: Ensure the entire body is scrollable to prevent RenderFlex overflow
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 1. SUMMARY CARDS
              Row(
                children: [
                  _buildSummaryCard(
                    "Total Alumni",
                    "${data['total']}",
                    Icons.groups,
                    Colors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryCard(
                    "Employed",
                    "${data['employed']}",
                    Icons.work,
                    Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryCard(
                    "Unemployed",
                    "${data['unemployed']}",
                    Icons.person_off,
                    Colors.red,
                  ),
                  const SizedBox(width: 16),
                  _buildSummaryCard(
                    "Employment Rate",
                    "${data['employment_rate']}%",
                    Icons.trending_up,
                    accentGold,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// LEFT COLUMN (Charts)
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Trend Chart stays at a fixed height for visual consistency
                        _buildSectionCard(
                          "Employment Trend (Yearly %)",
                          SizedBox(height: 200, child: _buildLineChart()),
                        ),
                        const SizedBox(height: 24),
                        // Industry Distribution is dynamic (no fixed height for the child)
                        _buildSectionCard(
                          "Industry Distribution",
                          _buildIndustryDistribution(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  /// RIGHT COLUMN (Insights)
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildTopRolesCard(),
                        const SizedBox(height: 24),
                        _buildInsightsPanel(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// --- UI COMPONENTS ---

  Widget _buildSectionCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:
            MainAxisSize.min, // FIX 2: Allow container to shrink-wrap content
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          child, // No forced SizedBox(height: 200) here anymore
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 18,
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  /// --- CHARTS & DATA VISUALS ---

  Widget _buildIndustryDistribution() {
    final industries = [
      {"name": "IT & Technology", "value": 0.40, "color": primaryMaroon},
      {"name": "Business & Finance", "value": 0.25, "color": accentGold},
      {"name": "Education", "value": 0.20, "color": Colors.blueGrey},
      {"name": "Others", "value": 0.15, "color": Colors.grey},
    ];

    return Column(
      children: industries.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18.0), // Slightly more padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['name'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text("${((item['value'] as double) * 100).toInt()}%"),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: item['value'] as double,
                  minHeight: 10, // Slightly thicker bar
                  backgroundColor: bgLight,
                  color: item['color'] as Color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopRolesCard() {
    final roles = [
      "Software Developer",
      "Secondary Teacher",
      "HR Associate",
      "Admin Assistant",
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Top Job Roles",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...roles.map(
            (role) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.stars_rounded, color: accentGold),
              title: Text(role, style: const TextStyle(fontSize: 14)),
              dense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(2020, 70),
              FlSpot(2021, 74),
              FlSpot(2022, 76),
              FlSpot(2023, 82),
            ],
            isCurved: true,
            color: primaryMaroon,
            barWidth: 4,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: primaryMaroon.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryMaroon,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: accentGold, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Quick Insights",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "• Most graduates find jobs within 6 months.",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text(
            "• IT industry continues to lead in hiring.",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text(
            "• 70% of alumni report course relevance.",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
