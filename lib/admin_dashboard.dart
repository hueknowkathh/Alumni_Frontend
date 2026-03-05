import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool isLoading = true;

  int totalAlumni = 0;
  int verifiedAlumni = 0;
  int pendingVerification = 0;
  double employmentRate = 0;

  List<dynamic> recentSubmissions = [];
  List<FlSpot> employmentTrend = [];
  List<BarChartGroupData> batchDistribution = [];

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8080/alumni_api/admin_dashboard.php"), // CHANGE IF USING REAL DEVICE
      );

      final data = json.decode(response.body);

      setState(() {
        totalAlumni = data['total_alumni'];
        verifiedAlumni = data['verified_alumni'];
        pendingVerification = data['pending_verification'];
        employmentRate =
            double.tryParse(data['employment_rate'].toString()) ?? 0;

        recentSubmissions = data['recent_submissions'];

        // LINE CHART
        employmentTrend = [];
        for (int i = 0;
            i < data['batch_distribution'].length;
            i++) {
          employmentTrend.add(
            FlSpot(
              i.toDouble(),
              double.parse(
                  data['batch_distribution'][i]['employed']
                      .toString()),
            ),
          );
        }

        // BAR CHART
        batchDistribution = [];
        for (int i = 0;
            i < data['batch_distribution'].length;
            i++) {
          batchDistribution.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: double.parse(
                      data['batch_distribution'][i]
                              ['total_alumni']
                          .toString()),
                  width: 15,
                  color: const Color(0xFF420031),
                )
              ],
            ),
          );
        }

        isLoading = false;
      });
    } catch (e) {
      print("Dashboard Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        MediaQuery.of(context).size.width < 1200;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "High-level monitoring and decision-making for department alumni",
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 25),

            /// STAT CARDS
            Wrap(
              spacing: 15,
              runSpacing: 15,
              children: [
                _statCard("Total Alumni",
                    totalAlumni.toString(), Icons.people_outline,
                    const Color(0xFF420031)),
                _statCard(
                    "Employment Rate",
                    "${employmentRate.toStringAsFixed(1)}%",
                    Icons.trending_up,
                    const Color(0xFFB08900)),
                _statCard("Verified Alumni",
                    verifiedAlumni.toString(),
                    Icons.check_circle_outline,
                    const Color(0xFF420031)),
                _statCard("Pending Verification",
                    pendingVerification.toString(),
                    Icons.access_time,
                    const Color(0xFF70134F)),
              ],
            ),

            const SizedBox(height: 30),

            /// CHART + SUBMISSIONS
            isMobile
                ? Column(
                    children: [
                      _chartBox(
                          "Employment Trend",
                          _buildLineChart()),
                      const SizedBox(height: 25),
                      _recentSubmissionsBox(),
                    ],
                  )
                : Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 2,
                          child: _chartBox(
                              "Employment Trend",
                              _buildLineChart())),
                      const SizedBox(width: 20),
                      Expanded(
                          child:
                              _recentSubmissionsBox()),
                    ],
                  ),

            const SizedBox(height: 25),

            /// BAR CHART
            _chartBox("Batch Distribution",
                _buildBarChart()),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value,
      IconData icon, Color accent) {
    return Container(
      width: 250,
      height: 130,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600)),
              Icon(icon, color: accent),
            ],
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                  color: accent)),
        ],
      ),
    );
  }

  Widget _chartBox(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(height: 300, child: chart),
        ],
      ),
    );
  }

  Widget _recentSubmissionsBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
              "Recent Alumni Submissions",
              style: TextStyle(
                  fontWeight:
                      FontWeight.bold)),
          const SizedBox(height: 15),
          ...recentSubmissions.map((item) {
            return ListTile(
              leading: const CircleAvatar(
                  child: Icon(Icons.person)),
              title: Text(item['name']),
              subtitle: Text(
                  "${item['course']} • Batch ${item['batch']}"),
            );
          })
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(LineChartData(
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: employmentTrend,
          isCurved: true,
          color: const Color(0xFFB08900),
          barWidth: 3,
          dotData:
              const FlDotData(show: false),
        )
      ],
    ));
  }

  Widget _buildBarChart() {
    return BarChart(BarChartData(
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      barGroups: batchDistribution,
    ));
  }
}