import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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

class BSSWTracerPage extends StatefulWidget {
  final int userId; // pass the logged-in user id
  const BSSWTracerPage({super.key, required this.userId});

  @override
  State<BSSWTracerPage> createState() => _BSSWTracerPageState();
}

class _BSSWTracerPageState extends State<BSSWTracerPage> {
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool isSubmitted = false;
  bool isAgreed = false;
  int currentStep = 0;

  // Basic info
  final name = TextEditingController();
  final age = TextEditingController();
  final address = TextEditingController();
  final contact = TextEditingController();
  final yearGrad = TextEditingController();
  final honors = TextEditingController();

  // Employment info
  final jobTitle = TextEditingController();
  final company = TextEditingController();
  final sectorController = TextEditingController();
  final countryController = TextEditingController();
  final incomeController = TextEditingController();
  final notRelatedReasonController = TextEditingController();
  final durationController = TextEditingController();
  final moreReasonController = TextEditingController();

  // Feedback
  final feedback1 = TextEditingController();
  final feedback2 = TextEditingController();
  final feedback3 = TextEditingController();

  // Dropdowns / selections
  String? sex, civil;
  String? employment, unemploymentReason;
  String? firstJob, firstRelated, empType;
  String? jobRelated;
  String? moreHours;
  String? classification;
  String? furtherStudy, studyRelated, licensureTaken, licensureResult, cpd;

  // Skills & PEO
  List<String> selectedSkills = [];
  final skills = [
    "Casework and counseling",
    "Community organizing",
    "Social policy analysis",
    "Advocacy and networking",
    "Research and evaluation",
    "Ethical decision-making",
    "Documentation and reporting",
    "Supervision and mentoring",
    "ICT tools for social work",
  ];
  List<double> peo = List.generate(11, (_) => 3);

  // Satisfaction / recommendation
  double satisfaction = 3;
  double recommendation = 5;

  // Signature
  final signature = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );

  @override
  void dispose() {
    name.dispose();
    age.dispose();
    address.dispose();
    contact.dispose();
    yearGrad.dispose();
    honors.dispose();
    jobTitle.dispose();
    company.dispose();
    sectorController.dispose();
    countryController.dispose();
    incomeController.dispose();
    notRelatedReasonController.dispose();
    durationController.dispose();
    moreReasonController.dispose();
    feedback1.dispose();
    feedback2.dispose();
    feedback3.dispose();
    signature.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate() || !isAgreed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete required fields + consent")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final sign = await signature.toPngBytes();
      final base64Signature = sign != null ? base64Encode(sign) : "";

      final res = await http.post(
        ApiService.uri('submit_tracer.php'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "program": "BSSW",
          "name": name.text,
          "sex": sex,
          "age": age.text,
          "civil_status": civil,
          "address": address.text,
          "contact": contact.text,
          "year_graduated": yearGrad.text,
          "honors_awards": honors.text,
          "pre_grad_exp": "", // optional field
          "study_mode": "", // optional field
          "employment_status": employment,
          "unemployed_reason": unemploymentReason,
          "time_to_first_job": firstJob,
          "first_job_related": firstRelated,
          "job_type": empType,
          "job_title": jobTitle.text,
          "employer": company.text,
          "sector": sectorController.text,
          "country": countryController.text,
          "monthly_income": incomeController.text,
          "related_job": jobRelated,
          "underutilized_reason": notRelatedReasonController.text,
          "employment_classification": classification,
          "recommendation": recommendation.toString(),
          "reputation": "", // optional field
          "alumni_participation": "", // optional field
          "feedback_1": feedback1.text,
          "feedback_2": feedback2.text,
          "feedback_3": feedback3.text,
          "is_agreed": isAgreed ? 1 : 0,
          "date_submitted": DateTime.now().toIso8601String(),
          "signature": base64Signature,
        }),
      );

      final data = _parseJsonResponse(res);

      if (data["success"] == true) {
        if (!mounted) return;
        setState(() {
          isSubmitted = true;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Submission failed")),
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4A152C);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text("BSSW Alumni Tracer Study Form"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isSubmitted
          ? const Center(child: Text("Submitted Successfully!"))
          : Form(
              key: _formKey,
              child: Stepper(
                currentStep: currentStep,
                onStepContinue: () {
                  if (currentStep < 5) setState(() => currentStep++);
                },
                onStepCancel: () {
                  if (currentStep > 0) setState(() => currentStep--);
                },
                steps: [
                  /// STEP 1: Graduate Profile
                  Step(
                    title: const Text("Graduate Profile"),
                    content: Column(
                      children: [
                        buildRow(
                          buildText("Name", name),
                          buildText("Age", age),
                        ),
                        buildRow(
                          buildDropdown("Sex", [
                            "Male",
                            "Female",
                          ], (v) => sex = v),
                          buildDropdown("Civil Status", [
                            "Single",
                            "Married",
                            "Widowed",
                            "Separated",
                          ], (v) => civil = v),
                        ),
                        buildText("Address", address),
                        buildRow(
                          buildText("Contact", contact),
                          buildText("Year Graduated", yearGrad),
                        ),
                        buildText("Honors", honors),
                      ],
                    ),
                  ),

                  /// STEP 2: Employment Status & Career Path
                  Step(
                    title: const Text("Employment Status & Career Path"),
                    content: Column(
                      children: [
                        buildDropdown("Employment Status", [
                          "Employed",
                          "Unemployed",
                        ], (v) => setState(() => employment = v)),
                        if (employment == "Unemployed")
                          buildDropdown("Reason", [
                            "Further study",
                            "Health",
                            "No jobs",
                            "Relocation",
                          ], (v) => unemploymentReason = v),
                        if (employment == "Employed") ...[
                          buildRow(
                            buildText("Job Title", jobTitle),
                            buildText("Company", company),
                          ),
                          buildRow(
                            buildText("Sector", sectorController),
                            buildText("Country", countryController),
                          ),
                          buildText("Income Range", incomeController),
                          buildDropdown("Job Related", [
                            "Yes",
                            "No",
                          ], (v) => jobRelated = v),
                          if (jobRelated == "No")
                            buildText("Reason", notRelatedReasonController),
                          buildText("Job Duration", durationController),
                          buildDropdown("Want More Hours", [
                            "Yes",
                            "No",
                          ], (v) => moreHours = v),
                          if (moreHours == "Yes")
                            buildText("Reason", moreReasonController),
                          buildDropdown("Classification", [
                            "Regular",
                            "Contractual",
                            "Others",
                          ], (v) => classification = v),
                        ],
                      ],
                    ),
                  ),

                  /// STEP 3: Professional Skills
                  Step(
                    title: const Text("Professional Skills"),
                    content: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: skills.map((s) {
                        return SizedBox(
                          width: 300,
                          child: CheckboxListTile(
                            value: selectedSkills.contains(s),
                            onChanged: (v) {
                              setState(() {
                                v!
                                    ? selectedSkills.add(s)
                                    : selectedSkills.remove(s);
                              });
                            },
                            title: Text(s),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  /// STEP 4: Further Studies & Satisfaction
                  Step(
                    title: const Text("Further Studies & Satisfaction"),
                    content: Column(
                      children: [
                        buildDropdown("Further Study", [
                          "Yes",
                          "No",
                        ], (v) => furtherStudy = v),
                        buildDropdown("Study Related", [
                          "Yes",
                          "No",
                        ], (v) => studyRelated = v),
                        buildDropdown("Licensure Taken", [
                          "Yes",
                          "No",
                        ], (v) => licensureTaken = v),
                        buildDropdown("Licensure Result", [
                          "Passed",
                          "Failed",
                          "Pending",
                        ], (v) => licensureResult = v),
                        buildDropdown("CPD Attended", [
                          "Yes",
                          "No",
                        ], (v) => cpd = v),
                        buildSlider(
                          "Job Satisfaction",
                          (v) => satisfaction = v,
                          satisfaction,
                        ),
                        buildSlider(
                          "Recommendation",
                          (v) => recommendation = v,
                          recommendation,
                          max: 10,
                        ),
                      ],
                    ),
                  ),

                  /// STEP 5: Program Educational Outcomes
                  Step(
                    title: const Text("Program Educational Outcomes"),
                    content: Column(
                      children: [
                        ...List.generate(
                          11,
                          (i) => buildSlider(
                            "PEO ${i + 1}",
                            (v) => peo[i] = v,
                            peo[i],
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// STEP 6: Feedback & Consent
                  Step(
                    title: const Text("Feedback & Consent"),
                    content: Column(
                      children: [
                        buildText(
                          "Competencies to improve",
                          feedback1,
                          maxLines: 2,
                        ),
                        buildText(
                          "Field instruction improvements",
                          feedback2,
                          maxLines: 2,
                        ),
                        buildText(
                          "Support suggestions",
                          feedback3,
                          maxLines: 2,
                        ),
                        CheckboxListTile(
                          value: isAgreed,
                          onChanged: (v) => setState(() => isAgreed = v!),
                          title: const Text("I agree to Data Privacy"),
                        ),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Signature(controller: signature),
                        ),
                        TextButton(
                          onPressed: () => signature.clear(),
                          child: const Text("Clear Signature"),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text("Submit Form"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildRow(Widget left, Widget right) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget buildText(String label, TextEditingController c, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
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
      child: DropdownButtonFormField(
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
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
}
