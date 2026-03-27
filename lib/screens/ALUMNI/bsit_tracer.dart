import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BSITTracerPage extends StatefulWidget {
  const BSITTracerPage({super.key});

  @override
  State<BSITTracerPage> createState() => _BSITTracerPageState();
}

class _BSITTracerPageState extends State<BSITTracerPage> {
  final _formKey = GlobalKey<FormState>();
  int currentStep = 0;

  final name = TextEditingController();
  final age = TextEditingController();
  final address = TextEditingController();
  final contact = TextEditingController();
  final yearGrad = TextEditingController();
  final honors = TextEditingController();
  final jobTitle = TextEditingController();
  final company = TextEditingController();
  final feedback1 = TextEditingController();
  final feedback2 = TextEditingController();
  final feedback3 = TextEditingController();
  final date = TextEditingController();
  final otherCountry = TextEditingController();
  final studyProgram = TextEditingController();
  final studyInstitution = TextEditingController();

  String? sex, civil, studyMode, preGrad;

  String? employment;
  String? unemploymentReason;
  String? firstJob;
  String? firstRelated;

  String? empType;
  String? sector;
  String? country;
  String? income;
  String? jobRelated;
  String? notRelatedReason;
  String? classification;
  String? currentDuration;
  String? promoted;
  String? wantMoreHours;
  String? moreHoursReason;

  String? furtherStudy, studyType, studyRelated;
  String? licensureTaken, licensureResult, cpd;
  String? reputation, alumniParticipation;

  double satisfaction = 3;
  double recommendation = 5;

  double peo1 = 3;
  double peo2 = 3;
  double peo3 = 3;

  double curriculum = 3;
  double faculty = 3;
  double practicum = 3;
  double resources = 3;
  double guidance = 3;
  double careerServices = 3;
  double adminServices = 3;
  double overall = 3;

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
    "AI / Data Analytics"
  ];

  final signature = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

  bool get isEmployed =>
      employment == "Employed" ||
      employment == "Self-Employed" ||
      employment == "Employer";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BSIT Graduate Tracer Study")),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: currentStep,
          onStepContinue: () {
            if (currentStep < 6) setState(() => currentStep++);
          },
          onStepCancel: () {
            if (currentStep > 0) setState(() => currentStep--);
          },
          steps: [

            /// STEP 1
            Step(
              title: const Text("Graduate Profile"),
              content: Column(
                children: [
                  buildText("Name", name),
                  buildText("Age", age),

                  buildDropdown("Sex",
                      ["Male", "Female", "Prefer not to say"], (v) => sex = v),

                  buildDropdown("Civil Status",
                      ["Single", "Married", "Widowed", "Separated"],
                      (v) => civil = v),

                  buildText("Permanent Address", address),
                  buildText("Contact Number / Email", contact),
                  buildText("Year Graduated", yearGrad),
                  buildText("Honors or Awards", honors),

                  buildDropdown("Pre-graduation Employment Experience",
                      ["None", "Internship", "Part-time", "Full-time"],
                      (v) => preGrad = v),

                  buildDropdown("Study Mode",
                      ["Regular", "Distance/Online", "Mixed"],
                      (v) => studyMode = v),
                ],
              ),
            ),

            /// STEP 2
            Step(
              title: const Text("Employment Status & Career Path"),
              content: Column(
                children: [

                  buildDropdown("Current Employment Status", [
                    "Employed",
                    "Self-Employed",
                    "Employer",
                    "Unemployed",
                    "Studying Full-Time"
                  ], (v) {
                    setState(() {
                      employment = v;
                      unemploymentReason = null;
                      firstJob = null;
                      firstRelated = null;
                    });
                  }),

                  if (employment == "Unemployed")
                    buildDropdown("Reason for Unemployment", [
                      "Further study",
                      "Family/health reasons",
                      "Lack of job opportunities",
                      "Relocation",
                      "Others"
                    ], (v) => unemploymentReason = v),

                  if (isEmployed) ...[

                    const Divider(),

                    buildDropdown("Time to First Employment After Graduation", [
                      "<1 month",
                      "1–3 months",
                      "4–6 months",
                      "7–12 months",
                      ">1 year"
                    ], (v) => firstJob = v),

                    buildDropdown("First Job Related to Degree?", [
                      "Yes",
                      "Partly",
                      "No"
                    ], (v) => firstRelated = v),

                    buildDropdown("Present Employment Type", [
                      "Full-time",
                      "Part-time",
                      "Project-based",
                      "Freelance"
                    ], (v) => empType = v),

                    buildText("Job Title / Position", jobTitle),
                    buildText("Employer / Company", company),

                    buildDropdown("Sector", [
                      "Government",
                      "Private",
                      "NGO",
                      "Academic",
                      "Overseas"
                    ], (v) => sector = v),

                    buildDropdown(
                        "Country of Work", ["Philippines", "Other"],
                        (v) => country = v),

                    if (country == "Other")
                      buildText("Specify Country", otherCountry),

                    buildDropdown("Monthly Income (₱)", [
                      "<15k",
                      "15–25k",
                      "25–35k",
                      "35–50k",
                      "50–75k",
                      ">75k"
                    ], (v) => income = v),

                    buildDropdown("Is your current job related to IT?", [
                      "Yes",
                      "Somewhat",
                      "No"
                    ], (v) => jobRelated = v),

                    if (jobRelated == "No")
                      buildDropdown("Reason job is NOT related", [
                        "No jobs in field",
                        "Better pay elsewhere",
                        "Lack of experience",
                        "Location limits",
                        "Job satisfaction in another field"
                      ], (v) => notRelatedReason = v),

                    buildDropdown("Duration in Current Job", [
                      "<6 months",
                      "6–12 months",
                      "1–2 years",
                      "3+ years"
                    ], (v) => currentDuration = v),

                    buildDropdown("Promoted since first job?",
                        ["Yes", "No"], (v) => promoted = v),

                    buildDropdown("Want more working hours?",
                        ["Yes", "No"], (v) => wantMoreHours = v),

                    if (wantMoreHours == "Yes")
                      buildDropdown("Reason for wanting more hours", [
                        "No available hours",
                        "Studying",
                        "Family obligations",
                        "Lack of local opportunities"
                      ], (v) => moreHoursReason = v),

                    buildDropdown("Employment Classification", [
                      "Rank-and-file",
                      "Supervisory",
                      "Managerial",
                      "Executive"
                    ], (v) => classification = v),

                    buildSlider("Overall Job Satisfaction",
                        (v) => satisfaction = v, satisfaction),
                  ]
                ],
              ),
            ),

            /// STEP 3
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

            /// STEP 4
            Step(
              title: const Text("Further Studies"),
              content: Column(
                children: [

                  buildDropdown("Enrolled in Further Study?",
                      ["Yes", "No"], (v) => furtherStudy = v),

                  buildText("Program", studyProgram),
                  buildText("Institution", studyInstitution),

                  buildDropdown("Study Type", [
                    "Certificate",
                    "MIT/MIS",
                    "PhD/DIT/DBMIS",
                    "Others"
                  ], (v) => studyType = v),

                  buildDropdown("Study Related to IT",
                      ["Yes", "No"], (v) => studyRelated = v),

                  buildDropdown("Licensure Taken",
                      ["Yes", "No"], (v) => licensureTaken = v),

                  buildDropdown("Licensure Result",
                      ["Passed", "Did not pass", "Pending"],
                      (v) => licensureResult = v),

                  buildDropdown("CPD Attended",
                      ["Yes", "No"], (v) => cpd = v),
                ],
              ),
            ),

            /// STEP 5
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
                  buildSlider("Career Services",
                      (v) => careerServices = v, careerServices),
                  buildSlider("Admin Services",
                      (v) => adminServices = v, adminServices),

                  buildSlider("Overall Satisfaction",
                      (v) => overall = v, overall),
                ],
              ),
            ),

            /// STEP 6
            Step(
              title: const Text("Institution + Feedback"),
              content: Column(
                children: [

                  buildSlider("Recommendation (0–10)",
                      (v) => recommendation = v,
                      recommendation,
                      max: 10),

                  buildDropdown("Institution Reputation", [
                    "Very negative",
                    "Negative",
                    "Neutral",
                    "Positive",
                    "Very positive"
                  ], (v) => reputation = v),

                  buildDropdown("Alumni Participation",
                      ["Yes", "No"],
                      (v) => alumniParticipation = v),

                  buildText("Competencies to strengthen", feedback1),
                  buildText("Field instruction improvement", feedback2),
                  buildText("Career support suggestion", feedback3),
                ],
              ),
            ),

            /// STEP 7
            Step(
              title: const Text("Consent & Signature"),
              content: Column(
                children: [

                  CheckboxListTile(
                    value: isAgreed,
                    onChanged: (v) =>
                        setState(() => isAgreed = v!),
                    title: const Text(
                        "I voluntarily agree to Data Privacy & QA purposes"),
                  ),

                  buildText("Date", date),

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
                    onPressed: submit,
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

  Widget buildText(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget buildDropdown(
      String label, List<String> items, Function(String?) onChanged) {
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
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget buildSlider(
      String label,
      Function(double) onChanged,
      double value,
      {double max = 5}) {
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

 Future<void> submit() async {
  if (!_formKey.currentState!.validate() || !isAgreed) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Complete all required fields")),
    );
    return;
  }

  if (signature.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Signature required")),
    );
    return;
  }

  final url = Uri.parse("http://localhost/alumni_php/submit_bsit_tracer.php");

  final data = {
    "name": name.text,
    "age": age.text,
    "sex": sex ?? "",
    "civil_status": civil ?? "",
    "address": address.text,
    "contact": contact.text,
    "year_graduated": yearGrad.text,
    "honors": honors.text,
    "pre_graduation_experience": preGrad ?? "",
    "study_mode": studyMode ?? "",
    "employment_status": employment ?? "",
    "unemployment_reason": unemploymentReason ?? "",
    "time_first_job": firstJob ?? "",
    "first_job_related": firstRelated ?? "",
    "employment_type": empType ?? "",
    "job_title": jobTitle.text,
    "company": company.text,
    "sector": sector ?? "",
    "country": country ?? "",
    "income": income ?? "",
    "job_related": jobRelated ?? "",
    "not_related_reason": notRelatedReason ?? "",
    "current_job_duration": currentDuration ?? "",
    "promoted": promoted ?? "",
    "want_more_hours": wantMoreHours ?? "",
    "more_hours_reason": moreHoursReason ?? "",
    "classification": classification ?? "",
    "job_satisfaction": satisfaction,
    "further_study": furtherStudy ?? "",
    "study_program": studyProgram.text,
    "study_institution": studyInstitution.text,
    "study_type": studyType ?? "",
    "study_related": studyRelated ?? "",
    "licensure_taken": licensureTaken ?? "",
    "licensure_result": licensureResult ?? "",
    "cpd_attended": cpd ?? "",
    "peo1": peo1,
    "peo2": peo2,
    "peo3": peo3,
    "curriculum": curriculum,
    "faculty": faculty,
    "practicum": practicum,
    "resources": resources,
    "guidance": guidance,
    "career_services": careerServices,
    "admin_services": adminServices,
    "overall_satisfaction": overall,
    "recommendation": recommendation,
    "institution_reputation": reputation ?? "",
    "alumni_participation": alumniParticipation ?? "",
    "feedback_competencies": feedback1.text,
    "feedback_instruction": feedback2.text,
    "feedback_career": feedback3.text,
    "consent_agreed": isAgreed ? "Yes" : "No",
    "date_submitted": date.text,
    "skills": selectedSkills
  };

  try {
    print("SENDING DATA:");
    print(jsonEncode(data));

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode(data),
    );

    print("RESPONSE:");
    print(response.body);

    final result = jsonDecode(response.body);

    if (result["status"] == "success") {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tracer submitted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Unknown error")),
      );
    }
  } catch (e) {
    print("ERROR: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
 }
}