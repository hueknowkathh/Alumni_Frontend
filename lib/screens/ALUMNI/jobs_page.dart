import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../services/api_service.dart';
import '../../services/content_service.dart';

class AlumniJobsPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const AlumniJobsPage({super.key, required this.user});

  @override
  State<AlumniJobsPage> createState() => _AlumniJobsPageState();
}

class _AlumniJobsPageState extends State<AlumniJobsPage> {
  List<Map<String, dynamic>> jobs = [];
  bool isLoading = true;
  final Color primaryMaroon = const Color(0xFF4A152C);

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    try {
      final fetchedJobs = await ContentService.fetchJobs().timeout(
        const Duration(seconds: 10),
      );
      if (!mounted) return;
      setState(() {
        jobs = fetchedJobs;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch jobs. Check your connection.'),
        ),
      );
    }
  }

  Future<void> applyForJob(String jobId, String jobTitle) async {
    try {
      final url = ApiService.uri('apply_job.php');
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": widget.user['id'], "job_id": jobId}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['status'] == 'success'
                  ? 'Successfully applied for $jobTitle!'
                  : result['message'] ?? 'Application failed',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    }
  }

  void _showJobDetails(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text((job['title'] ?? "Job Details").toString()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (job['company'] ?? "Company not specified").toString(),
                style: TextStyle(
                  fontSize: 16,
                  color: primaryMaroon,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _detailRow("Location", job['location']),
              _detailRow("Salary", job['salary']),
              const SizedBox(height: 16),
              const Text(
                "Description:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(job['description'] ?? "No description available"),
              if (job['requirements'] != null &&
                  job['requirements'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  "Requirements:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(job['requirements'].toString()),
              ],
              const SizedBox(height: 16),
              Text(
                "Contact: ${(job['contact_email'] ?? 'Not provided').toString()}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                "Posted: ${(job['date_posted'] ?? 'Unknown').toString()}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              applyForJob(
                job['id'].toString(),
                (job['title'] ?? 'this job').toString(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryMaroon),
            child: const Text("Apply Now"),
          ),
        ],
      ),
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
            child: Text(
              value?.toString() ?? "Not specified",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Opportunities"),
        backgroundColor: primaryMaroon,
      ),
      body: Container(
        color: const Color(0xFFF7F8FA),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : jobs.isEmpty
            ? const Center(child: Text("No job opportunities available."))
            : RefreshIndicator(
                onRefresh: fetchJobs,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () => _showJobDetails(job),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      (job['title'] ?? "No Title").toString(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryMaroon.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "Apply",
                                      style: TextStyle(
                                        color: Color(0xFF4A152C),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (job['company'] ?? "Company not specified")
                                    .toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: primaryMaroon,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                (job['description'] ?? "No description")
                                    .toString(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (job['location'] ??
                                            "Location not specified")
                                        .toString(),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.attach_money,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (job['salary'] ?? "Salary not specified")
                                        .toString(),
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Posted: ${(job['date_posted'] ?? 'Recently').toString()}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
