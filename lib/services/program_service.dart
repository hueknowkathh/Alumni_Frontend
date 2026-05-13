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

class ProgramService {
  static Future<List<AlumniProgram>> fetch({bool activeOnly = false}) async {
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
    if (programs is! List) return const [];
    return programs
        .whereType<Map>()
        .map((item) => AlumniProgram.fromJson(Map<String, dynamic>.from(item)))
        .toList();
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
}
