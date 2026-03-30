import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

Map<String, dynamic> _parseJsonResponse(http.Response response) {
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return {
      'success': false,
      'message': 'Unexpected response format from server.',
    };
  } catch (_) {
    final snippet = response.body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return {
      'success': false,
      'message': response.statusCode >= 500
          ? 'Server error while submitting the tracer form.'
          : 'Server returned an invalid response: ${snippet.length > 160 ? snippet.substring(0, 160) : snippet}',
    };
  }
}

class BSITTracerPage extends StatefulWidget {
  final int userId;
  const BSITTracerPage({super.key, required this.userId});

  @override
  State<BSITTracerPage> createState() => _BSITTracerPageState();
}

class _BSITTracerPageState extends State<BSITTracerPage> {
  final _formKey = GlobalKey<FormState>();
  int currentStep = 0;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController yearGradController = TextEditingController();
  final TextEditingController honorsController = TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController feedback1Controller = TextEditingController();
  final TextEditingController feedback2Controller = TextEditingController();
  final TextEditingController feedback3Controller = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController otherCountryController = TextEditingController();
  final TextEditingController studyProgramController = TextEditingController();
  final TextEditingController studyInstitutionController =
      TextEditingController();

  // Dropdown values
  String? sex, civilStatus, studyMode, preGradExperience;
  String? employmentStatus, unemployedReason;
  String? timeFirstJob, firstJobRelated;
  String? jobType, sector, country, income, relatedJob, underutilizedReason;
  String? employmentClassification;
  String? promoted, wantMoreHours, moreHoursReason;
  String? furtherStudy, studyType, studyRelated;
  String? licensureTaken, licensureResult, cpd;
  String? reputation, alumniParticipation;

  // Sliders
  double satisfaction = 3;
  double recommendation = 5;
  double peo1 = 3, peo2 = 3, peo3 = 3;
  double curriculum = 3,
      faculty = 3,
      practicum = 3,
      resources = 3,
      guidance = 3,
      careerServices = 3,
      adminServices = 3,
      overall = 3;

  // Other
  bool isAgreed = false;
  List<String> selectedSkills = [];

  final skills = [
    "Programming and Software Development",
    "Database Management",
    "Networking and Cybersecurity",
    "Systems Analysis and Design",
    "Cloud Computing and DevOps",
    "Problem Solving",
    "Debugging",
    "Communication Skills",
    "Teamwork and Collaboration",
    "Time Management",
    "Adaptability",
    "UI/UX Design",
    "Version Control",
    "AI / Data Analytics",
  ];

  final signature = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

  bool get isEmployed =>
      employmentStatus == "Employed" ||
      employmentStatus == "Self-Employed" ||
      employmentStatus == "Employer";

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    addressController.dispose();
    contactController.dispose();
    yearGradController.dispose();
    honorsController.dispose();
    jobTitleController.dispose();
    companyController.dispose();
    feedback1Controller.dispose();
    feedback2Controller.dispose();
    feedback3Controller.dispose();
    dateController.dispose();
    otherCountryController.dispose();
    studyProgramController.dispose();
    studyInstitutionController.dispose();
    signature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BSIT Graduate Tracer Study")),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: currentStep,
          onStepContinue: () async {
            if (currentStep < 6) {
              setState(() => currentStep++);
              return;
            }

            await submitBSITTracer();
          },
          onStepCancel: () {
            if (currentStep > 0) setState(() => currentStep--);
          },
          steps: [
            // STEP 1: Graduate Profile
            Step(
              title: const Text("Graduate Profile"),
              content: Column(
                children: [
                  buildText("Name", nameController),
                  buildText("Age", ageController),
                  buildDropdown("Sex", [
                    "Male",
                    "Female",
                    "Prefer not to say",
                  ], (v) => sex = v),
                  buildDropdown("Civil Status", [
                    "Single",
                    "Married",
                    "Widowed",
                    "Separated",
                  ], (v) => civilStatus = v),
                  buildText("Permanent Address", addressController),
                  buildText("Contact Number / Email", contactController),
                  buildText("Year Graduated", yearGradController),
                  buildText("Honors or Awards", honorsController),
                  buildDropdown(
                    "Pre-graduation Employment Experience",
                    ["None", "Internship", "Part-time", "Full-time"],
                    (v) => preGradExperience = v,
                  ),
                  buildDropdown("Study Mode", [
                    "Regular",
                    "Distance/Online",
                    "Mixed",
                  ], (v) => studyMode = v),
                ],
              ),
            ),

            // STEP 2: Employment Status & Career Path
            Step(
              title: const Text("Employment Status & Career Path"),
              content: Column(
                children: [
                  buildDropdown(
                    "Current Employment Status",
                    [
                      "Employed",
                      "Self-Employed",
                      "Employer",
                      "Unemployed",
                      "Studying Full-Time",
                    ],
                    (v) {
                      setState(() {
                        employmentStatus = v;
                        unemployedReason = null;
                        timeFirstJob = null;
                        firstJobRelated = null;
                      });
                    },
                  ),
                  if (employmentStatus == "Unemployed")
                    buildDropdown("Reason for Unemployment", [
                      "Further study",
                      "Family/health reasons",
                      "Lack of job opportunities",
                      "Relocation",
                      "Others",
                    ], (v) => unemployedReason = v),
                  if (isEmployed) ...[
                    const Divider(),
                    buildDropdown(
                      "Time to First Employment After Graduation",
                      [
                        "<1 month",
                        "1–3 months",
                        "4–6 months",
                        "7–12 months",
                        ">1 year",
                      ],
                      (v) => timeFirstJob = v,
                    ),
                    buildDropdown("First Job Related to Degree?", [
                      "Yes",
                      "Partly",
                      "No",
                    ], (v) => firstJobRelated = v),
                    buildDropdown("Present Employment Type", [
                      "Full-time",
                      "Part-time",
                      "Project-based",
                      "Freelance",
                    ], (v) => jobType = v),
                    buildText("Job Title / Position", jobTitleController),
                    buildText("Employer / Company", companyController),
                    buildDropdown("Sector", [
                      "Government",
                      "Private",
                      "NGO",
                      "Academic",
                      "Overseas",
                    ], (v) => sector = v),
                    buildDropdown("Country of Work", [
                      "Philippines",
                      "Other",
                    ], (v) => country = v),
                    if (country == "Other")
                      buildText("Specify Country", otherCountryController),
                    buildDropdown("Monthly Income (₱)", [
                      "<15k",
                      "15–25k",
                      "25–35k",
                      "35–50k",
                      "50–75k",
                      ">75k",
                    ], (v) => income = v),
                    buildDropdown("Is your current job related to IT?", [
                      "Yes",
                      "Somewhat",
                      "No",
                    ], (v) => relatedJob = v),
                    if (relatedJob == "No")
                      buildDropdown("Reason job is NOT related", [
                        "No jobs in field",
                        "Better pay elsewhere",
                        "Lack of experience",
                        "Location limits",
                        "Job satisfaction in another field",
                      ], (v) => underutilizedReason = v),
                    buildDropdown(
                      "Duration in Current Job",
                      ["<6 months", "6–12 months", "1–2 years", "3+ years"],
                      (v) => employmentClassification = v,
                    ),
                    buildDropdown("Promoted since first job?", [
                      "Yes",
                      "No",
                    ], (v) => promoted = v),
                    buildDropdown("Want more working hours?", [
                      "Yes",
                      "No",
                    ], (v) => wantMoreHours = v),
                    if (wantMoreHours == "Yes")
                      buildDropdown("Reason for wanting more hours", [
                        "No available hours",
                        "Studying",
                        "Family obligations",
                        "Lack of local opportunities",
                      ], (v) => moreHoursReason = v),
                    buildSlider(
                      "Overall Job Satisfaction",
                      (v) => satisfaction = v,
                      satisfaction,
                    ),
                  ],
                ],
              ),
            ),

            // STEP 3: Professional Skills
            Step(
              title: const Text("Professional Skills"),
              content: Wrap(
                children: skills.map((skill) {
                  return CheckboxListTile(
                    title: Text(skill),
                    value: selectedSkills.contains(skill),
                    onChanged: (v) {
                      setState(() {
                        v!
                            ? selectedSkills.add(skill)
                            : selectedSkills.remove(skill);
                      });
                    },
                  );
                }).toList(),
              ),
            ),

            // STEP 4: Further Studies
            Step(
              title: const Text("Further Studies"),
              content: Column(
                children: [
                  buildDropdown("Enrolled in Further Study?", [
                    "Yes",
                    "No",
                  ], (v) => furtherStudy = v),
                  buildText("Program", studyProgramController),
                  buildText("Institution", studyInstitutionController),
                  buildDropdown("Study Type", [
                    "Certificate",
                    "MIT/MIS",
                    "PhD/DIT/DBMIS",
                    "Others",
                  ], (v) => studyType = v),
                  buildDropdown("Study Related to IT", [
                    "Yes",
                    "No",
                  ], (v) => studyRelated = v),
                  buildDropdown("Licensure Taken", [
                    "Yes",
                    "No",
                  ], (v) => licensureTaken = v),
                  buildDropdown("Licensure Result", [
                    "Passed",
                    "Did not pass",
                    "Pending",
                  ], (v) => licensureResult = v),
                  buildDropdown("CPD Attended", ["Yes", "No"], (v) => cpd = v),
                ],
              ),
            ),

            // STEP 5: PEO & Satisfaction
            Step(
              title: const Text("PEO & Satisfaction"),
              content: Column(
                children: [
                  buildSlider("PEO 1", (v) => peo1 = v, peo1),
                  buildSlider("PEO 2", (v) => peo2 = v, peo2),
                  buildSlider("PEO 3", (v) => peo3 = v, peo3),
                  buildSlider("Curriculum", (v) => curriculum = v, curriculum),
                  buildSlider("Faculty", (v) => faculty = v, faculty),
                  buildSlider("Practicum", (v) => practicum = v, practicum),
                  buildSlider("Resources", (v) => resources = v, resources),
                  buildSlider("Guidance", (v) => guidance = v, guidance),
                  buildSlider(
                    "Career Services",
                    (v) => careerServices = v,
                    careerServices,
                  ),
                  buildSlider(
                    "Admin Services",
                    (v) => adminServices = v,
                    adminServices,
                  ),
                  buildSlider(
                    "Overall Satisfaction",
                    (v) => overall = v,
                    overall,
                  ),
                ],
              ),
            ),

            // STEP 6: Institution + Feedback
            Step(
              title: const Text("Institution + Feedback"),
              content: Column(
                children: [
                  buildSlider(
                    "Recommendation (0–10)",
                    (v) => recommendation = v,
                    recommendation,
                    max: 10,
                  ),
                  buildDropdown("Institution Reputation", [
                    "Very negative",
                    "Negative",
                    "Neutral",
                    "Positive",
                    "Very positive",
                  ], (v) => reputation = v),
                  buildDropdown("Alumni Participation", [
                    "Yes",
                    "No",
                  ], (v) => alumniParticipation = v),
                  buildText("Competencies to strengthen", feedback1Controller),
                  buildText(
                    "Field instruction improvement",
                    feedback2Controller,
                  ),
                  buildText("Career support suggestion", feedback3Controller),
                ],
              ),
            ),

            // STEP 7: Consent & Signature
            Step(
              title: const Text("Consent & Signature"),
              content: Column(
                children: [
                  CheckboxListTile(
                    value: isAgreed,
                    onChanged: (v) => setState(() => isAgreed = v!),
                    title: const Text(
                      "I voluntarily agree to Data Privacy & QA purposes",
                    ),
                  ),
                  buildText("Date", dateController),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Signature(controller: signature),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: submitBSITTracer,
                    child: const Text("Submit"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildText(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget buildDropdown(
    String label,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => setState(() => onChanged(v)),
        validator: (v) => v == null ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget buildSlider(
    String label,
    Function(double) onChanged,
    double value, {
    double max = 5,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label (${value.round()})"),
        Slider(
          value: value,
          min: 1,
          max: max,
          divisions: max.toInt() - 1,
          onChanged: (v) => setState(() => onChanged(v)),
        ),
      ],
    );
  }

  Future<void> submitBSITTracer() async {
    if (!_formKey.currentState!.validate() || !isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete all required fields")),
      );
      return;
    }

    if (signature.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Signature required")));
      return;
    }

    final url = ApiService.uri('submit_tracer.php');

    final data = {
      "user_id": widget.userId,
      "program": "BSIT",
      "name": nameController.text,
      "sex": sex ?? "",
      "age": ageController.text,
      "civil_status": civilStatus ?? "",
      "address": addressController.text,
      "contact": contactController.text,
      "year_graduated": yearGradController.text,
      "honors_awards": honorsController.text,
      "pre_grad_exp": preGradExperience ?? "",
      "study_mode": studyMode ?? "",
      "employment_status": employmentStatus ?? "",
      "unemployed_reason": unemployedReason ?? "",
      "time_to_first_job": timeFirstJob ?? "",
      "first_job_related": firstJobRelated ?? "",
      "job_type": jobType ?? "",
      "job_title": jobTitleController.text,
      "employer": companyController.text,
      "sector": sector ?? "",
      "country": country ?? "",
      "monthly_income": income ?? "",
      "related_job": relatedJob ?? "",
      "underutilized_reason": underutilizedReason ?? "",
      "employment_classification": employmentClassification ?? "",
      "recommendation": recommendation,
      "reputation": reputation ?? "",
      "alumni_participation": alumniParticipation ?? "",
      "feedback_1": feedback1Controller.text,
      "feedback_2": feedback2Controller.text,
      "feedback_3": feedback3Controller.text,
      "is_agreed": isAgreed ? "Yes" : "No",
      "date_submitted": dateController.text,
      "skills": selectedSkills,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      final resData = _parseJsonResponse(response);
      if (resData['success']) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("BSIT tracer submitted successfully")),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Submission failed: ${resData['message']}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
