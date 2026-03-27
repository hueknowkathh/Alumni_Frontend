import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BSSWTracerPage extends StatefulWidget {
  const BSSWTracerPage({super.key});

  @override
  State<BSSWTracerPage> createState() => _BSSWTracerPageState();
}

class _BSSWTracerPageState extends State<BSSWTracerPage> {
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool isSubmitted = false;
  bool isAgreed = false;

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

  final sectorController = TextEditingController();
  final countryController = TextEditingController();
  final incomeController = TextEditingController();
  final notRelatedReasonController = TextEditingController();
  final durationController = TextEditingController();
  final moreReasonController = TextEditingController();

  String? sex, civil;
  String? employment, unemploymentReason;
  String? firstJob, firstRelated, empType;
  String? jobRelated;
  String? moreHours;
  String? classification;
  String? furtherStudy, studyRelated, licensureTaken, licensureResult, cpd;

  double satisfaction = 3;
  double recommendation = 5;

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
    "ICT tools for social work"
  ];

  List<double> peo = List.generate(11, (_) => 3);

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
    feedback1.dispose();
    feedback2.dispose();
    feedback3.dispose();
    sectorController.dispose();
    countryController.dispose();
    incomeController.dispose();
    notRelatedReasonController.dispose();
    durationController.dispose();
    moreReasonController.dispose();
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
        Uri.parse("http://localhost/alumni_php/submit_tracer.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name.text,
          "age": age.text,
          "sex": sex,
          "civil": civil,
          "address": address.text,
          "contact": contact.text,
          "year": yearGrad.text,
          "honors": honors.text,
          "employment": employment,
          "unemployment_reason": unemploymentReason,
          "first_job_timing": firstJob,
          "first_job_related": firstRelated,
          "employment_type": empType,
          "job_title": jobTitle.text,
          "company": company.text,
          "sector": sectorController.text,
          "country": countryController.text,
          "income_range": incomeController.text,
          "job_related": jobRelated,
          "not_related_reason": notRelatedReasonController.text,
          "job_duration": durationController.text,
          "want_more_hours": moreHours,
          "more_hours_reason": moreReasonController.text,
          "skills": selectedSkills,
          "classification": classification,
          "further_study": furtherStudy,
          "study_related": studyRelated,
          "licensure_taken": licensureTaken,
          "licensure_result": licensureResult,
          "cpd": cpd,
          "peo": peo,
          "satisfaction": satisfaction,
          "recommendation": recommendation,
          "feedback1": feedback1.text,
          "feedback2": feedback2.text,
          "feedback3": feedback3.text,
          "consent": isAgreed ? 1 : 0,
          "signature": base64Signature
        }),
      );

      final data = jsonDecode(res.body);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _headerCard(),

                        buildSection("Personal Information", [
                          buildRow(
                            buildText("Name", name),
                            buildText("Age", age),
                          ),
                          buildRow(
                            buildDropdown("Sex", ["Male", "Female"], (v) => sex = v),
                            buildDropdown("Civil Status",
                                ["Single", "Married", "Widowed", "Separated"],
                                (v) => civil = v),
                          ),
                          buildText("Address", address),
                          buildRow(
                            buildText("Contact", contact),
                            buildText("Year Graduated", yearGrad),
                          ),
                          buildText("Honors", honors),
                        ]),

                        buildSection("Employment Information", [
                          buildDropdown("Employment Status",
                              ["Employed", "Unemployed"],
                              (v) => setState(() => employment = v)),
                          if (employment == "Unemployed")
                            buildDropdown("Reason",
                                ["Further study", "Health", "No jobs", "Relocation"],
                                (v) => unemploymentReason = v),

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
                            buildDropdown("Job Related", ["Yes", "No"],
                                (v) => jobRelated = v),
                            if (jobRelated == "No")
                              buildText("Reason", notRelatedReasonController),
                          ]
                        ]),

                        buildSection("Skills Assessment", [
                          Wrap(
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
                          )
                        ]),

                        buildSection("Program Educational Outcomes", [
                          ...List.generate(
                            11,
                            (i) => buildSlider("PEO ${i + 1}", (v) => peo[i] = v, peo[i]),
                          )
                        ]),

                        buildSection("Feedback", [
                          buildText("Competencies to improve", feedback1, maxLines: 2),
                          buildText("Field instruction improvements", feedback2, maxLines: 2),
                          buildText("Support suggestions", feedback3, maxLines: 2),
                        ]),

                        buildSection("Consent & Signature", [
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
                        ]),

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
                        )
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _headerCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          children: [
            Text(
              "Bachelor of Science in Social Work",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text("Graduate Tracer Survey"),
          ],
        ),
      ),
    );
  }

  Widget buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ...children,
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget buildDropdown(
      String label, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField(
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget buildSlider(
      String label, Function(double) onChanged, double value,
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
}