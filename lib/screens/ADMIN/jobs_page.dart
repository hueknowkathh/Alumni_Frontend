import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import '../widgets/luxury_module_banner.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key});

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color accentGold = const Color(0xFFC5A046);
  final Color bgLight = const Color(0xFFF7F8FA);
  final Color borderColor = const Color(0xFFE5E7EB);
  final Color softRose = const Color(0xFFF8F1F4);

  bool isLoading = false;
  bool isSaving = false;
  List jobs = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedLocation = 'All Locations';

  List<String> get _locationOptions {
    final locations =
        jobs
            .map((job) => (job['location'] ?? '').toString().trim())
            .where((location) => location.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['All Locations', ...locations];
  }

  List get _filteredJobs {
    final query = _searchController.text.trim().toLowerCase();
    return jobs.where((job) {
      final title = (job['title'] ?? '').toString().toLowerCase();
      final company = (job['company'] ?? '').toString().toLowerCase();
      final location = (job['location'] ?? '').toString().trim();

      final matchesSearch =
          query.isEmpty || title.contains(query) || company.contains(query);
      final matchesLocation = _selectedLocation == 'All Locations'
          ? true
          : location == _selectedLocation;

      return matchesSearch && matchesLocation;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchJobs() async {
    setState(() => isLoading = true);
    try {
      final url = ApiService.uri('get_jobs.php');
      final response = await http.get(url);

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

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['status'] == 'success') {
          await fetchJobs();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Job posted successfully"),
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
                content: Text("Error: ${result['message'] ?? 'Unknown error'}"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("HTTP Error: ${response.statusCode}"),
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
            content: Text("Network error. Check connection."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => isSaving = false);
    return false;
  }

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
                content: Text("Job deleted successfully"),
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
    final isCompact = MediaQuery.of(context).size.width < 720;
    return Container(
      color: bgLight,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F8FA), Color(0xFFF4F1F2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 16 : 24,
            isCompact ? 16 : 24,
            isCompact ? 16 : 24,
            32,
          ),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildFilterBar(),
            const SizedBox(height: 24),
            if (isLoading)
              Center(child: CircularProgressIndicator(color: primaryMaroon))
            else
              _buildJobsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isStacked = MediaQuery.of(context).size.width < 860;
    return LuxuryModuleBanner(
      compact: isStacked,
      title: 'Job Opportunities Management',
      description:
          'Post and manage alumni openings with the same polished visual style used on the alumni jobs page.',
      icon: Icons.cases_outlined,
      actions: [
        LuxuryBannerAction(
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          onPressed: fetchJobs,
          iconOnly: !isStacked,
        ),
        LuxuryBannerAction(
          icon: Icons.add,
          label: 'Post New Job',
          onPressed: () => _showJobDialog(),
          filled: true,
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final withSalary = jobs
        .where((job) => (job['salary'] ?? '').toString().trim().isNotEmpty)
        .length;
    final withLocation = jobs
        .where((job) => (job['location'] ?? '').toString().trim().isNotEmpty)
        .length;
    final withContact = jobs
        .where(
          (job) => (job['contact_email'] ?? '').toString().trim().isNotEmpty,
        )
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardWidth = availableWidth >= 1180
            ? (availableWidth - 48) / 4
            : availableWidth >= 760
            ? (availableWidth - 16) / 2
            : double.infinity;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _statCard(
              "Open Roles",
              jobs.length.toString(),
              Icons.work_outline,
              primaryMaroon,
              cardWidth,
            ),
            _statCard(
              "With Salary Info",
              withSalary.toString(),
              Icons.payments_outlined,
              accentGold,
              cardWidth,
            ),
            _statCard(
              "With Location",
              withLocation.toString(),
              Icons.location_on_outlined,
              Colors.teal,
              cardWidth,
            ),
            _statCard(
              "With Contact",
              withContact.toString(),
              Icons.mail_outline,
              Colors.indigo,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final isNarrow = MediaQuery.of(context).size.width < 900;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: isNarrow
          ? Column(
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildLocationDropdown(),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: _buildSearchField()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildLocationDropdown()),
              ],
            ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search title or company...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildLocationDropdown() {
    final items = _locationOptions;
    final value = items.contains(_selectedLocation)
        ? _selectedLocation
        : items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedLocation = value);
        },
      ),
    );
  }

  Widget _buildJobsList() {
    if (_filteredJobs.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _filteredJobs.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: _buildJobCard(entry.value, entry.key),
        );
      }).toList(),
    );
  }

  Widget _buildJobCard(dynamic job, int index) {
    final title = (job['title'] ?? "No Title").toString();
    final company = (job['company'] ?? "Company not specified").toString();
    final description = (job['description'] ?? "No Description").toString();
    final location = (job['location'] ?? "Location not specified").toString();
    final salary = (job['salary'] ?? "Salary not specified").toString();
    final datePosted = (job['date_posted'] ?? 'Unknown').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryMaroon.withValues(alpha: 0.95),
                        const Color(0xFF7B2E4B),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      company.isNotEmpty
                          ? company.substring(0, 1).toUpperCase()
                          : 'J',
                      style: TextStyle(
                        color: accentGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: primaryMaroon,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: accentGold.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              "Manage",
                              style: TextStyle(
                                color: primaryMaroon,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: () => _showJobDialog(job: job),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(job['id'].toString()),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _metaPill(Icons.location_on_outlined, location),
                _metaPill(Icons.payments_outlined, salary),
                _metaPill(Icons.schedule_outlined, "Posted $datePosted"),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Opportunity ${index + 1}",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primaryMaroon),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters =
        _searchController.text.trim().isNotEmpty ||
        _selectedLocation != 'All Locations';
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width < 500
            ? MediaQuery.of(context).size.width - 32
            : 420,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: softRose,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.work_off_outlined,
                color: primaryMaroon,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasFilters ? "No jobs found" : "No jobs posted yet",
              style: TextStyle(
                color: primaryMaroon,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? "Try changing the search term or location filter to see more job postings."
                  : "Create your first posting and it will appear here in the updated jobs layout.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
            ),
          ],
        ),
      ),
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
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFFFBF7),
                  Color(0xFFF8F1F4),
                  Color(0xFFFFFCFA),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: primaryMaroon.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  color: primaryMaroon.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF5A1832),
                        Color(0xFF6A2A43),
                        Color(0xFF35101E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.14),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: accentGold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          isEditing
                              ? Icons.edit_outlined
                              : Icons.work_outline_rounded,
                          color: accentGold,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                isEditing ? 'JOB EDITOR' : 'NEW OPPORTUNITY',
                                style: TextStyle(
                                  color: accentGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isEditing ? 'Update job post' : 'Post new job',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                    child: Column(
                      children: [
                        _buildDialogFieldShell(
                          label: 'Job Title',
                          child: TextField(
                            controller: titleController,
                            decoration: _dialogInputDecoration(
                              'Enter the role title',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isStacked = constraints.maxWidth < 520;
                            final companyField = _buildDialogFieldShell(
                              label: 'Company Name',
                              child: TextField(
                                controller: companyController,
                                decoration: _dialogInputDecoration(
                                  'Enter the employer name',
                                ),
                              ),
                            );
                            final locationField = _buildDialogFieldShell(
                              label: 'Location',
                              child: TextField(
                                controller: locationController,
                                decoration: _dialogInputDecoration(
                                  'City, region, or remote',
                                ),
                              ),
                            );

                            if (isStacked) {
                              return Column(
                                children: [
                                  companyField,
                                  const SizedBox(height: 14),
                                  locationField,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: companyField),
                                const SizedBox(width: 14),
                                Expanded(child: locationField),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isStacked = constraints.maxWidth < 520;
                            final salaryField = _buildDialogFieldShell(
                              label: 'Salary Range',
                              child: TextField(
                                controller: salaryController,
                                decoration: _dialogInputDecoration(
                                  'Optional compensation range',
                                ),
                              ),
                            );
                            final contactField = _buildDialogFieldShell(
                              label: 'Contact Email',
                              child: TextField(
                                controller: contactEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _dialogInputDecoration(
                                  'Email for applications',
                                ),
                              ),
                            );

                            if (isStacked) {
                              return Column(
                                children: [
                                  salaryField,
                                  const SizedBox(height: 14),
                                  contactField,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: salaryField),
                                const SizedBox(width: 14),
                                Expanded(child: contactField),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildDialogFieldShell(
                          label: 'Job Description',
                          child: TextField(
                            controller: descriptionController,
                            maxLines: 4,
                            decoration: _dialogInputDecoration(
                              'Summarize the opportunity and key responsibilities',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildDialogFieldShell(
                          label: 'Requirements',
                          child: TextField(
                            controller: requirementsController,
                            maxLines: 3,
                            decoration: _dialogInputDecoration(
                              'List qualifications, skills, or experience',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryMaroon,
                                  side: BorderSide(
                                    color: primaryMaroon.withValues(alpha: 0.18),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        if (titleController.text.isEmpty ||
                                            descriptionController.text.isEmpty ||
                                            companyController.text.isEmpty ||
                                            locationController.text.isEmpty ||
                                            contactEmailController
                                                .text
                                                .isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Please fill required fields",
                                              ),
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

                                        if (!context.mounted) return;

                                        if (success) {
                                          Navigator.pop(context);
                                        }
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryMaroon,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        isEditing
                                            ? Icons.check_circle_outline
                                            : Icons.publish_outlined,
                                        size: 18,
                                      ),
                                label: Text(
                                  isEditing ? 'Update Job' : 'Publish Job',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogFieldShell({
    required String label,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: primaryMaroon.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFFCF8F5),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: borderColor.withValues(alpha: 0.9),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: borderColor.withValues(alpha: 0.9),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryMaroon, width: 1.2),
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
