import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TracerFormPage extends StatefulWidget {
  const TracerFormPage({super.key});

  @override
  State<TracerFormPage> createState() => _TracerFormPageState();
}

class _TracerFormPageState extends State<TracerFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitted = false;
  bool _isLoading = false;

  // Theme Colors
  static const Color primaryMaroon = Color(0xFF4A152C);
  static const Color lightBackground = Color(0xFFF7F8FA);

  // --- Text Controllers ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _yearGraduatedController = TextEditingController();
  final TextEditingController _honorsController = TextEditingController();

  // --- Dropdown & Radio State ---
  String? _selectedSex;
  String? _civilStatus;
  String? _preGradExperience;
  String? _studyMode;

  String? _employmentStatus;
  String? _unemploymentReason;
  String? _firstJobTiming;
  String? _firstJobRelated;
  String? _employmentType;
  String? _sector;
  String? _country;
  String? _incomeRange;
  String? _notRelatedReason;
  String? _jobDuration;
  String? _promotion;
  String? _wantMoreHours;
  String? _moreHoursReason;

  String? _classification;
  String? _jobRelated;
  double _satisfaction = 3.0;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _jobTitleController.dispose();
    _companyController.dispose();
    _yearGraduatedController.dispose();
    _honorsController.dispose();
    super.dispose();
  }

  // --- SUBMIT FUNCTION ---
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse("http://localhost:8080/alumni_php/submit_tracer.php"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "alumni_id": 1, 
            "full_name": _nameController.text,
            "sex": _selectedSex ?? "",
            "age": _ageController.text,
            "civil_status": _civilStatus ?? "",
            "address": _addressController.text,
            "contact_number": _contactController.text,
            "year_graduated": _yearGraduatedController.text,
            "honors": _honorsController.text,
            "pre_grad_experience": _preGradExperience ?? "",
            "study_mode": _studyMode ?? "",
            "employment_status": _employmentStatus ?? "",
            "unemployment_reason": _unemploymentReason ?? "",
            "first_job_timing": _firstJobTiming ?? "",
            "first_job_related": _firstJobRelated ?? "",
            "employment_type": _employmentType ?? "",
            "job_title": _jobTitleController.text,
            "company_name": _companyController.text,
            "sector": _sector ?? "",
            "country": _country ?? "",
            "income_range": _incomeRange ?? "",
            "job_related": _jobRelated ?? "",
            "not_related_reason": _notRelatedReason ?? "",
            "job_duration": _jobDuration ?? "",
            "promotion": _promotion ?? "",
            "want_more_hours": _wantMoreHours ?? "",
            "more_hours_reason": _moreHoursReason ?? "",
            "classification": _classification ?? "",
            "satisfaction": _satisfaction.round().toString(),
          }),
        );

        final result = json.decode(response.body);
        if (result['success'] == true) {
          setState(() {
            _isSubmitted = true;
            _isLoading = false;
          });
        } else {
          throw Exception(result['message'] ?? "Failed to submit");
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: lightBackground,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryMaroon))
              : _isSubmitted
                  ? _buildSuccessState()
                  : _buildFormState(),
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Graduate Tracer Form",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryMaroon)),
            const SizedBox(height: 8),
            const Text("Please provide accurate information to update our records."),
            const SizedBox(height: 24),

            // --- SECTION 1: PROFILE ---
            _buildSectionCard("1. Graduate Profile", Icons.person_outline, [
              _buildTextField("Full Name", _nameController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _buildDropdown("Sex", ["Male", "Female", "Prefer not to say"], _selectedSex,
                          (v) => setState(() => _selectedSex = v))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField("Age", _ageController, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdown("Civil Status", ["Single", "Married", "Widowed", "Separated"], _civilStatus,
                  (v) => setState(() => _civilStatus = v)),
              const SizedBox(height: 16),
              _buildTextField("Current Address", _addressController, maxLines: 2),
              const SizedBox(height: 16),
              _buildTextField("Contact Number", _contactController, prefix: "+63 "),
              const SizedBox(height: 16),
              _buildTextField("Year Graduated", _yearGraduatedController),
              const SizedBox(height: 16),
              _buildTextField("Honors / Awards (optional)", _honorsController),
              const SizedBox(height: 16),
              _buildDropdown("Pre-graduation Experience", ["None", "Internship", "Part-time", "Full-time"],
                  _preGradExperience, (v) => setState(() => _preGradExperience = v)),
              const SizedBox(height: 16),
              _buildDropdown("Study Mode", ["Regular", "Distance/Online", "Mixed"], _studyMode,
                  (v) => setState(() => _studyMode = v)),
            ]),

            const SizedBox(height: 24),

            // --- SECTION 2: EMPLOYMENT ---
          _buildSectionCard("2. Employment Information", Icons.work_outline, [
  _buildDropdown(
    "Employment Status",
    ["Employed", "Self-Employed", "Unemployed"],
    _employmentStatus,
    (v) => setState(() {
      _employmentStatus = v;

      // reset when switching
      _unemploymentReason = null;
      _jobTitleController.clear();
      _companyController.clear();
      _firstJobTiming = null;
      _firstJobRelated = null;
      _employmentType = null;
      _sector = null;
      _country = null;
      _incomeRange = null;
      _jobRelated = null;
      _notRelatedReason = null;
      _jobDuration = null;
      _promotion = null;
      _wantMoreHours = null;
      _moreHoursReason = null;
    }),
  ),

  const SizedBox(height: 16),

  // =========================
  // ❌ UNEMPLOYED ONLY
  // =========================
  if (_employmentStatus == "Unemployed") ...[
    _buildDropdown(
      "Reason for Unemployment",
      ["Further study", "Family/health reasons", "Lack of job opportunities", "Relocation", "Others"],
      _unemploymentReason,
      (v) => setState(() => _unemploymentReason = v),
    ),
  ],

  // =========================
  // ✅ EMPLOYED OR SELF-EMPLOYED ONLY
  // =========================
  if (_employmentStatus == "Employed" || _employmentStatus == "Self-Employed") ...[
    _buildDropdown(
      "Time to First Employment",
      ["<1 month", "1–3 months", "4–6 months", "7–12 months", ">1 year"],
      _firstJobTiming,
      (v) => setState(() => _firstJobTiming = v),
    ),
    const SizedBox(height: 16),

    _buildDropdown(
      "First Job Related to Degree",
      ["Yes", "Partly", "No"],
      _firstJobRelated,
      (v) => setState(() => _firstJobRelated = v),
    ),
    const SizedBox(height: 16),

    _buildDropdown(
      "Employment Type",
      ["Full-time", "Part-time", "Project-based", "Freelance"],
      _employmentType,
      (v) => setState(() => _employmentType = v),
    ),
    const SizedBox(height: 16),

    _buildTextField("Job Title", _jobTitleController),
    const SizedBox(height: 16),

    _buildTextField("Company/Organization", _companyController),
    const SizedBox(height: 16),

    _buildDropdown(
      "Sector",
      ["Government", "Private", "NGO", "Academic", "Overseas"],
      _sector,
      (v) => setState(() => _sector = v),
    ),
    const SizedBox(height: 16),

    _buildDropdown(
      "Country of Work",
      ["Philippines", "Other"],
      _country,
      (v) => setState(() => _country = v),
    ),
    const SizedBox(height: 16),

    _buildDropdown(
      "Monthly Income Range",
      ["<15k", "15–25k", "25–35k", "35–50k", "50–75k", ">75k"],
      _incomeRange,
      (v) => setState(() => _incomeRange = v),
    ),
    const SizedBox(height: 16),

    _buildRadioGroup("Is your job related to course?", ["Yes", "Somewhat", "No"]),

    if (_jobRelated == "No") ...[
      const SizedBox(height: 16),
      _buildDropdown(
        "Reason not related",
        ["No jobs in field", "Better pay elsewhere", "Lack of experience", "Location limits", "Job satisfaction in another field"],
        _notRelatedReason,
        (v) => setState(() => _notRelatedReason = v),
      ),
    ],

    const SizedBox(height: 16),

    _buildDropdown(
      "How long in current position?",
      ["<6 months", "6–12 months", "1–2 years", "3+ years"],
      _jobDuration,
      (v) => setState(() => _jobDuration = v),
    ),
    const SizedBox(height: 16),

    _buildDropdown(
      "Promoted since first job?",
      ["Yes", "No"],
      _promotion,
      (v) => setState(() => _promotion = v),
    ),
    const SizedBox(height: 16),

    _buildDropdown(
      "Would you like to work more hours?",
      ["Yes", "No"],
      _wantMoreHours,
      (v) => setState(() {
        _wantMoreHours = v;
        if (v == "No") _moreHoursReason = null;
      }),
    ),

    if (_wantMoreHours == "Yes") ...[
      const SizedBox(height: 16),
      _buildDropdown(
        "Reason for wanting more hours",
        ["No available hours", "Studying", "Family obligations", "Lack of local opportunities"],
        _moreHoursReason,
        (v) => setState(() => _moreHoursReason = v),
      ),
    ],
  ],
]),

            const SizedBox(height: 24),

            // --- SECTION 3: CAREER PROGRESS ---
            _buildSectionCard("3. Career Progress", Icons.trending_up, [
              _buildDropdown("Employment Classification", ["Rank and File", "Supervisory", "Managerial"], _classification,
                  (v) => setState(() => _classification = v)),
              const SizedBox(height: 16),
              Text("Job Satisfaction (${_satisfaction.round()})", style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: _satisfaction,
                min: 1,
                max: 5,
                divisions: 4,
                activeColor: primaryMaroon,
                onChanged: (v) => setState(() => _satisfaction = v),
              ),
            ]),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryMaroon,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Submit Tracer Form",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---
  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType, int maxLines = 1, String? prefix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
          decoration: InputDecoration(
            prefixText: prefix,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }

  // UPDATED HELPER: Added currentValue and safety check
  Widget _buildDropdown(String label, List<String> items, String? currentValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: (currentValue != null && items.contains(currentValue)) ? currentValue : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          validator: (value) => value == null ? "Required" : null,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRadioGroup(String label, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Row(
          children: options
              .map((opt) => Row(
                    children: [
                      Radio<String>(
                          value: opt,
                          groupValue: _jobRelated,
                          activeColor: primaryMaroon,
                          onChanged: (v) => setState(() => _jobRelated = v)),
                      Text(opt),
                      const SizedBox(width: 20),
                    ],
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: primaryMaroon, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
            ]),
            const Divider(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          const Text("Success!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Your tracer form has been submitted."),
          const SizedBox(height: 32),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: primaryMaroon),
              child: const Text("Back to Dashboard", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}