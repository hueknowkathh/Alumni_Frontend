import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class AlumniProgram {
  const AlumniProgram({
    required this.id,
    required this.code,
    required this.name,
    required this.tracerFormType,
    required this.isActive,
  });

  final int id;
  final String code;
  final String name;
  final String tracerFormType;
  final bool isActive;

  factory AlumniProgram.fromJson(Map<String, dynamic> json) {
    return AlumniProgram(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      tracerFormType: (json['tracer_form_type'] ?? 'BSIT').toString(),
      isActive:
          json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_active']?.toString() == '1',
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (id > 0) 'id': id,
      'code': code,
      'name': name,
      'tracer_form_type': tracerFormType,
      'is_active': isActive,
    };
  }
}

class TracerFormTypeOption {
  const TracerFormTypeOption({required this.code, required this.label});

  final String code;
  final String label;

  factory TracerFormTypeOption.fromJson(Map<String, dynamic> json) {
    return TracerFormTypeOption(
      code: (json['code'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
    );
  }
}

class TracerTemplateConfig {
  const TracerTemplateConfig({
    required this.id,
    required this.code,
    required this.label,
    required this.programTitle,
    required this.programSubtitle,
    required this.currentJobRelatedLabel,
    required this.studyTypeOptions,
    required this.licensureLabel,
    required this.licensureTypeLabel,
    required this.licensureResultLabel,
    required this.skillsOptions,
    required this.peoStatements,
    required this.curriculumSatisfactionLabel,
    required this.recommendationLabel,
    required this.reputationLabel,
    required this.feedbackCompetenciesLabel,
    required this.isActive,
  });

  final int id;
  final String code;
  final String label;
  final String programTitle;
  final String programSubtitle;
  final String currentJobRelatedLabel;
  final List<String> studyTypeOptions;
  final String licensureLabel;
  final String licensureTypeLabel;
  final String licensureResultLabel;
  final List<String> skillsOptions;
  final List<String> peoStatements;
  final String curriculumSatisfactionLabel;
  final String recommendationLabel;
  final String reputationLabel;
  final String feedbackCompetenciesLabel;
  final bool isActive;

  factory TracerTemplateConfig.fromJson(Map<String, dynamic> json) {
    List<String> readList(String key) {
      final value = json[key];
      if (value is List) {
        return value
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      if (value is String && value.trim().isNotEmpty) {
        return value
            .split(RegExp(r'\r\n|\r|\n'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      return const [];
    }

    return TracerTemplateConfig(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      code: (json['code'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      programTitle: (json['program_title'] ?? '').toString(),
      programSubtitle: (json['program_subtitle'] ?? '').toString(),
      currentJobRelatedLabel: (json['current_job_related_label'] ?? '')
          .toString(),
      studyTypeOptions: readList('study_type_options'),
      licensureLabel: (json['licensure_label'] ?? '').toString(),
      licensureTypeLabel: (json['licensure_type_label'] ?? '').toString(),
      licensureResultLabel: (json['licensure_result_label'] ?? '').toString(),
      skillsOptions: readList('skills_options'),
      peoStatements: readList('peo_statements'),
      curriculumSatisfactionLabel: (json['curriculum_satisfaction_label'] ?? '')
          .toString(),
      recommendationLabel: (json['recommendation_label'] ?? '').toString(),
      reputationLabel: (json['reputation_label'] ?? '').toString(),
      feedbackCompetenciesLabel: (json['feedback_competencies_label'] ?? '')
          .toString(),
      isActive:
          json['is_active'] == true ||
          json['is_active'] == 1 ||
          json['is_active']?.toString() == '1',
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (id > 0) 'id': id,
      'code': code,
      'label': label,
      'program_title': programTitle,
      'program_subtitle': programSubtitle,
      'current_job_related_label': currentJobRelatedLabel,
      'study_type_options': studyTypeOptions,
      'licensure_label': licensureLabel,
      'licensure_type_label': licensureTypeLabel,
      'licensure_result_label': licensureResultLabel,
      'skills_options': skillsOptions,
      'peo_statements': peoStatements,
      'curriculum_satisfaction_label': curriculumSatisfactionLabel,
      'recommendation_label': recommendationLabel,
      'reputation_label': reputationLabel,
      'feedback_competencies_label': feedbackCompetenciesLabel,
      'is_active': isActive,
    };
  }
}

class ProgramDirectory {
  const ProgramDirectory({
    required this.programs,
    required this.tracerFormTypes,
  });

  final List<AlumniProgram> programs;
  final List<TracerFormTypeOption> tracerFormTypes;
}

class ProgramService {
  static Future<ProgramDirectory> fetchDirectory({
    bool activeOnly = false,
  }) async {
    final response = await http.get(
      ApiService.uri(
        'get_programs.php',
        queryParameters: {if (activeOnly) 'active_only': '1'},
      ),
      headers: ApiService.authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load programs (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected programs response format.');
    }

    final programs = decoded['programs'];
    final tracerFormTypes = decoded['tracer_form_types'];
    return ProgramDirectory(
      programs: programs is List
          ? programs
                .whereType<Map>()
                .map(
                  (item) =>
                      AlumniProgram.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      tracerFormTypes: tracerFormTypes is List
          ? tracerFormTypes
                .whereType<Map>()
                .map(
                  (item) => TracerFormTypeOption.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where((item) => item.code.trim().isNotEmpty)
                .toList()
          : const [],
    );
  }

  static Future<List<AlumniProgram>> fetch({bool activeOnly = false}) async {
    final directory = await fetchDirectory(activeOnly: activeOnly);
    return directory.programs;
  }

  static Future<List<AlumniProgram>> save(AlumniProgram program) async {
    final response = await http.post(
      ApiService.uri('save_program.php'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode(program.toPayload()),
    );

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    if (response.statusCode != 200 || data['status'] != 'success') {
      throw Exception(data['message']?.toString() ?? 'Program save failed.');
    }

    final programs = data['programs'];
    if (programs is! List) return const [];
    return programs
        .whereType<Map>()
        .map((item) => AlumniProgram.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<List<TracerTemplateConfig>> fetchTracerTemplates({
    bool activeOnly = false,
  }) async {
    final response = await http.get(
      ApiService.uri(
        'get_tracer_templates.php',
        queryParameters: {if (activeOnly) 'active_only': '1'},
      ),
      headers: ApiService.authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load tracer templates (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected tracer template response format.');
    }

    final templates = decoded['templates'];
    if (templates is! List) return const [];
    return templates
        .whereType<Map>()
        .map(
          (item) =>
              TracerTemplateConfig.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static Future<TracerTemplateConfig?> fetchTracerTemplate(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty) return null;

    final response = await http.get(
      ApiService.uri(
        'get_tracer_templates.php',
        queryParameters: {'code': normalizedCode, 'active_only': '1'},
      ),
      headers: ApiService.authHeaders(),
    );

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load tracer template (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['template'] is! Map) {
      throw Exception('Unexpected tracer template response format.');
    }

    return TracerTemplateConfig.fromJson(
      Map<String, dynamic>.from(decoded['template'] as Map),
    );
  }

  static Future<List<TracerTemplateConfig>> saveTracerTemplate(
    TracerTemplateConfig template,
  ) async {
    final response = await http.post(
      ApiService.uri('save_tracer_template.php'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode(template.toPayload()),
    );

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    if (response.statusCode != 200 || data['status'] != 'success') {
      throw Exception(data['message']?.toString() ?? 'Template save failed.');
    }

    final templates = data['templates'];
    if (templates is! List) return const [];
    return templates
        .whereType<Map>()
        .map(
          (item) =>
              TracerTemplateConfig.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
