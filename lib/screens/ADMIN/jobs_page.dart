import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE0E0E0);

  bool isLoading = false;
  bool isSaving = false;
  List jobs = [];

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  /// FETCH DATA
  Future<void> fetchJobs() async {
    setState(() => isLoading = true);
    try {
      var url = ApiService.uri('get_jobs.php');
      var response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          jobs = data['jobs'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching jobs: $e");
    }
    setState(() => isLoading = false);
  }

  /// SAVE (CREATE / UPDATE)
  Future<bool> saveJob(
    String title,
    String description,
    String company,
    String location,
    String salary,
    String requirements,
    String contactEmail, {
    String? id,
  }) async {
    final url = ApiService.uri('add_job.php');

    setState(() => isSaving = true);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id": id ?? "",
          "title": title,
          "description": description,
          "company": company,
          "location": location,
          "salary": salary,
          "requirements": requirements,
          "contact_email": contactEmail,
        }),
      );

      debugPrint("SERVER RAW OUTPUT: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(response.body);

          if (result['status'] == 'success') {
            await fetchJobs();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Job posted successfully"),
                  backgroundColor: Colors.green,
                ),
              );
            }

            setState(() => isSaving = false);
            return true;
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "❌ Error: ${result['message'] ?? 'Unknown error'}",
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint("JSON Parse Error: $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("❌ Server response error"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ HTTP Error: ${response.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Network Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Network error. Check connection."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => isSaving = false);
    return false;
  }

  /// DELETE
  Future<void> deleteJob(String id) async {
    final url = ApiService.uri('delete_job.php');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": id}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          await fetchJobs();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("🗑️ Job deleted successfully"),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgLight,
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildAddButton(),
            const SizedBox(height: 32),
            _buildJobsList(),
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
              "Job Opportunities Management",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryMaroon,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Post and manage job opportunities for alumni",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: fetchJobs,
          icon: const Icon(Icons.refresh),
          label: const Text("Refresh"),
          style: OutlinedButton.styleFrom(foregroundColor: primaryMaroon),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: () => _showJobDialog(),
        icon: const Icon(Icons.add),
        label: const Text("Post New Job"),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMaroon,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildJobsList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (jobs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: Text("No jobs posted yet."),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        job['title'] ?? "No Title",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showJobDialog(job: job),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(job['id'].toString()),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  job['company'] ?? "No Company",
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryMaroon,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  job['description'] ?? "No Description",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      job['location'] ?? "Not specified",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.attach_money, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      job['salary'] ?? "Not specified",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Posted: ${job['date_posted'] ?? 'Unknown'}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJobDialog({Map<String, dynamic>? job}) {
    final isEditing = job != null;

    final titleController = TextEditingController(text: job?['title'] ?? '');
    final descriptionController = TextEditingController(
      text: job?['description'] ?? '',
    );
    final companyController = TextEditingController(
      text: job?['company'] ?? '',
    );
    final locationController = TextEditingController(
      text: job?['location'] ?? '',
    );
    final salaryController = TextEditingController(text: job?['salary'] ?? '');
    final requirementsController = TextEditingController(
      text: job?['requirements'] ?? '',
    );
    final contactEmailController = TextEditingController(
      text: job?['contact_email'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? "Edit Job" : "Post New Job"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Job Title *"),
              ),
              TextField(
                controller: companyController,
                decoration: const InputDecoration(labelText: "Company Name *"),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: "Location *"),
              ),
              TextField(
                controller: salaryController,
                decoration: const InputDecoration(labelText: "Salary Range"),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: "Job Description *",
                ),
                maxLines: 3,
              ),
              TextField(
                controller: requirementsController,
                decoration: const InputDecoration(labelText: "Requirements"),
                maxLines: 2,
              ),
              TextField(
                controller: contactEmailController,
                decoration: const InputDecoration(labelText: "Contact Email *"),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: isSaving
                ? null
                : () async {
                    if (titleController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        companyController.text.isEmpty ||
                        locationController.text.isEmpty ||
                        contactEmailController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill required fields"),
                        ),
                      );
                      return;
                    }

                    final success = await saveJob(
                      titleController.text,
                      descriptionController.text,
                      companyController.text,
                      locationController.text,
                      salaryController.text,
                      requirementsController.text,
                      contactEmailController.text,
                      id: job?['id']?.toString(),
                    );

                    if (success) {
                      Navigator.pop(context);
                    }
                  },
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEditing ? "Update" : "Post"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Job"),
        content: const Text(
          "Are you sure you want to delete this job posting?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              deleteJob(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
