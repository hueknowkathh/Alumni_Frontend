import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';

class DeanDashboard extends StatefulWidget {
  final Map<String, dynamic> user;

  const DeanDashboard({super.key, required this.user});

  @override
  State<DeanDashboard> createState() => _DeanDashboardState();
}

class _DeanDashboardState extends State<DeanDashboard> {
  static const Color primaryMaroon = Color(0xFF4A152C);
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color accentGold = Color(0xFFC5A046);

  static const List<Color> chartColors = [
    Color(0xFF4A152C),
    Color(0xFFC5A046),
    Color(0xFF2F80ED),
    Color(0xFF27AE60),
    Color(0xFFF2994A),
    Color(0xFF9B51E0),
  ];

  String _selectedProgram = 'All';
  bool _isLoading = true;

  Map<String, dynamic> _summary = {
    'total_alumni': 0,
    'employment_rate': 0,
    'unemployment_rate': 0,
    'submissions': 0,
  };
  List<Map<String, dynamic>> _batchData = [];
  List<Map<String, dynamic>> _industryData = [];
  List<Map<String, dynamic>> _topEmployers = [];
  Map<String, dynamic> _jobRelevance = {
    'related': 0,
    'other': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await http.get(
        ApiService.uri(
          'dean_dashboard.php',
          queryParameters: {
            'program': _selectedProgram,
          },
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Request failed: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }

      if (!mounted) return;

      setState(() {
        _summary = Map<String, dynamic>.from(decoded['summary'] ?? {});
        _batchData = ((decoded['batch_data'] ?? []) as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _industryData = ((decoded['industries'] ?? []) as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _topEmployers = ((decoded['top_employers'] ?? []) as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _jobRelevance = Map<String, dynamic>.from(
          decoded['job_relevance'] ?? {'related': 0, 'other': 0},
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dean dashboard: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1100;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome, ${widget.user['name'] ?? 'Dean'}!",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                "Live tracer analytics based on submitted alumni records.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedProgram,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'All',
                                        child: Text('All Programs'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'BSIT',
                                        child: Text('BSIT'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'BSSW',
                                        child: Text('BSSW'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() => _selectedProgram = value);
                                      _fetchDashboardData();
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                onPressed: _fetchDashboardData,
                                icon: const Icon(Icons.refresh_rounded),
                                tooltip: 'Refresh',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primaryMaroon,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _buildStatCard(
                            "Total Submissions",
                            "${_summary['total_alumni'] ?? 0}",
                            Icons.people_alt_outlined,
                            Colors.blue,
                            constraints.maxWidth,
                          ),
                          _buildStatCard(
                            "Employment Rate",
                            "${_summary['employment_rate'] ?? 0}%",
                            Icons.trending_up,
                            Colors.green,
                            constraints.maxWidth,
                          ),
                          _buildStatCard(
                            "Unemployment",
                            "${_summary['unemployment_rate'] ?? 0}%",
                            Icons.trending_down,
                            Colors.redAccent,
                            constraints.maxWidth,
                          ),
                          _buildStatCard(
                            "Tracer Submissions",
                            "${_summary['submissions'] ?? 0}",
                            Icons.assignment_turned_in_outlined,
                            accentGold,
                            constraints.maxWidth,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildDashboardSection(
                        title: "Employment Rate Per Batch",
                        child: SizedBox(
                          height: 300,
                          child: _batchData.isEmpty
                              ? _buildEmptyState("No batch data yet.")
                              : _buildBarChart(),
                        ),
                      ),
                      const SizedBox(height: 32),
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
                                child: _industryData.isEmpty
                                    ? _buildEmptyState(
                                        "No industry data found in tracer submissions.",
                                      )
                                    : _buildPieChart(),
                              ),
                            ),
                          ),
                          if (isWide)
                            const SizedBox(width: 24)
                          else
                            const SizedBox(height: 24),
                          Expanded(
                            flex: isWide ? 1 : 0,
                            child: _buildDashboardSection(
                              title: "Top Employers",
                              child: _topEmployers.isEmpty
                                  ? _buildEmptyState(
                                      "No employer records available yet.",
                                    )
                                  : Column(
                                      children: _topEmployers
                                          .asMap()
                                          .entries
                                          .map(
                                            (entry) => _buildEmployerItem(
                                              entry.value['name']?.toString() ??
                                                  'Unknown Employer',
                                              "${entry.value['count'] ?? 0} Alumni",
                                              chartColors[
                                                  entry.key % chartColors.length],
                                            ),
                                          )
                                          .toList(),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDashboardSection(
                              title: "Job Relevance",
                              child: _buildJobRelevanceCard(),
                            ),
                          ),
                          if (isWide)
                            const SizedBox(width: 24)
                          else
                            const SizedBox(height: 24),
                          Expanded(
                            child: _buildDashboardSection(
                              title: "Data Notes",
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: lightBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "This dashboard now reads live tracer submissions.",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      "Industry data is grouped from the tracer form's sector field.",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Batch employment is grouped from year_graduated.",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildJobRelevanceCard() {
    final related = (_jobRelevance['related'] ?? 0) as int;
    final other = (_jobRelevance['other'] ?? 0) as int;
    final total = related + other;
    final relatedRate = total > 0 ? ((related / total) * 100).round() : 0;
    final otherRate = total > 0 ? ((other / total) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMiniMetric(
                  "Related",
                  "$relatedRate%",
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniMetric(
                  "Other/Partial",
                  "$otherRate%",
                  accentGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            value: total > 0 ? related / total : 0,
            minHeight: 12,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: Colors.grey.shade300,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          Text(
            "$related related responses and $other other or partial responses",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final total = _industryData.fold<double>(
      0,
      (sum, item) => sum + ((item['value'] ?? 0) as num).toDouble(),
    );

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 42,
        sections: _industryData.asMap().entries.map((entry) {
          final item = entry.value;
          final value = ((item['value'] ?? 0) as num).toDouble();
          final percentage = total > 0 ? (value / total) * 100 : 0;
          final title = percentage >= 10
              ? "${percentage.toStringAsFixed(0)}%"
              : '';

          return PieChartSectionData(
            value: value,
            color: chartColors[entry.key % chartColors.length],
            title: title,
            radius: 58,
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmployerItem(String name, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 35,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Text(
            count,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double totalWidth,
  ) {
    double cardWidth = (totalWidth - 64 - (20 * 3)) / 4;
    if (totalWidth < 1100) cardWidth = (totalWidth - 64 - 20) / 2;
    if (totalWidth < 600) cardWidth = totalWidth - 64;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

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
                final index = value.toInt();
                if (index < 0 || index >= _batchData.length) {
                  return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _batchData[index]['year']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, m) => Text(
                "${v.toInt()}%",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _batchData.asMap().entries.map((entry) {
          final rate = ((entry.value['rate'] ?? 0) as num).toDouble();
          return _makeGroupData(entry.key, rate);
        }).toList(),
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
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: lightBackground,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardSection({
    required String title,
    required Widget child,
  }) {
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
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
