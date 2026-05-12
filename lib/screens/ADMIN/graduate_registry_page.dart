import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/activity_service.dart';
import '../../services/api_service.dart';
import '../../services/csv_export_service.dart';
import '../widgets/luxury_module_banner.dart';

class GraduateRegistryPage extends StatefulWidget {
  const GraduateRegistryPage({super.key});

  @override
  State<GraduateRegistryPage> createState() => _GraduateRegistryPageState();
}

class _GraduateRegistryPageState extends State<GraduateRegistryPage> {
  static const String _activeProgram = 'BSIT';
  static const Color primaryMaroon = Color(0xFF4A152C);
  static const Color accentGold = Color(0xFFC5A046);
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color borderColor = Color(0xFFE5E7EB);

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allGraduates = const [];
  List<Map<String, dynamic>> _filteredGraduates = const [];
  Map<String, dynamic> _summary = const {
    'total_graduates': 0,
    'registered_alumni': 0,
    'tracer_respondents': 0,
    'unregistered_graduates': 0,
  };

  bool _isLoading = true;
  bool _isUploading = false;
  Timer? _refreshTimer;

  String _selectedProgram = 'All Programs';
  String _selectedYear = 'All Batches';
  List<String> _programOptions = const ['All Programs'];
  List<String> _yearOptions = const ['All Batches'];

  int get _totalGraduates => _allGraduates.length;

  @override
  void initState() {
    super.initState();
    _fetchGraduateRegistry();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _fetchGraduateRegistry(showLoader: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGraduateRegistry({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await http.get(
        ApiService.uri(
          'get_graduate_registry.php',
          queryParameters: {'program': _activeProgram},
        ),
        headers: ApiService.authHeaders(),
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception('Request failed: ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }

      final graduates = ((decoded['graduates'] ?? const []) as List)
          .whereType<Map>()
          .map((row) => row.map((key, value) => MapEntry('$key', value)))
          .where((row) => _isActiveProgram(row['program']))
          .toList();

      final years =
          graduates
              .map((row) => (row['year_graduated'] ?? '').toString().trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

      setState(() {
        _allGraduates = graduates;
        _summary = Map<String, dynamic>.from(decoded['summary'] ?? const {});
        _programOptions = const ['All Programs', _activeProgram];
        _yearOptions = ['All Batches', ...years];

        if (!_programOptions.contains(_selectedProgram)) {
          _selectedProgram = _programOptions.first;
        }
        if (!_yearOptions.contains(_selectedYear)) {
          _selectedYear = _yearOptions.first;
        }

        _applyFilters();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Failed to load graduate registry: $error', Colors.red);
    }
  }

  void _applyFilters() {
    final search = _searchController.text.trim().toLowerCase();
    _filteredGraduates = _allGraduates.where((row) {
      final name = (row['full_name'] ?? '').toString().toLowerCase();
      final email = (row['email'] ?? '').toString().toLowerCase();
      final studentNumber = (row['student_number'] ?? '')
          .toString()
          .toLowerCase();
      final program = (row['program'] ?? '').toString();
      final year = (row['year_graduated'] ?? '').toString();

      final matchesSearch =
          search.isEmpty ||
          name.contains(search) ||
          email.contains(search) ||
          studentNumber.contains(search);
      final matchesActiveProgram = _isActiveProgram(program);
      final matchesProgram =
          _selectedProgram == 'All Programs' || program == _selectedProgram;
      final matchesYear =
          _selectedYear == 'All Batches' || year == _selectedYear;

      return matchesActiveProgram && matchesSearch && matchesProgram && matchesYear;
    }).toList();
  }

  bool _isActiveProgram(dynamic program) {
    return program?.toString().trim().toUpperCase() == _activeProgram;
  }

  Future<void> _pickAndUploadFile() async {
    if (_isUploading) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx'],
      withData: true,
      withReadStream: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    Uint8List? fileBytes = file.bytes;

    if ((fileBytes == null || fileBytes.isEmpty) && file.readStream != null) {
      final collected = <int>[];
      await for (final chunk in file.readStream!) {
        collected.addAll(chunk);
      }
      if (collected.isNotEmpty) {
        fileBytes = Uint8List.fromList(collected);
      }
    }

    if (fileBytes == null || fileBytes.isEmpty) {
      _showSnack('Unable to read the selected file.', Colors.red);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        ApiService.uri('upload_graduate_registry.php'),
      );
      request.headers.addAll(ApiService.authHeaders());
      request.files.add(
        http.MultipartFile.fromBytes(
          'graduate_file',
          fileBytes,
          filename: file.name,
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(response.body);

      if (response.statusCode != 200) {
        final message = decoded is Map<String, dynamic>
            ? (decoded['message'] ?? 'Graduate upload failed.')
            : 'Graduate upload failed.';
        throw Exception(message);
      }

      final message = decoded is Map<String, dynamic>
          ? 'Processed ${decoded['processed'] ?? 0} records. Inserted ${decoded['inserted'] ?? 0}, updated ${decoded['updated'] ?? 0}.'
          : 'Graduate list uploaded successfully.';

      await ActivityService.logImportantFlow(
        action: 'graduate_registry_upload',
        title: 'Admin uploaded a graduates file',
        type: 'Graduates',
        targetType: 'graduate_registry',
        description: 'Uploaded ${file.name} to the graduates module.',
        metadata: {'file_name': file.name, 'file_size_bytes': fileBytes.length},
      );

      if (!mounted) return;
      _showSnack(message, Colors.green);
      await _fetchGraduateRegistry(showLoader: false);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Upload failed: $error', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      final path = await CsvExportService.exportRows(
        filename: 'graduate_registry_template.csv',
        headers: const [
          'full_name',
          'program',
          'year_graduated',
        ],
        rows: const [
          [
            'Juan Santos Dela Cruz',
            'BSIT',
            '2021',
          ],
        ],
      );

      if (!mounted) return;
      _showSnack('Template exported: $path', Colors.green);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to export template.', Colors.red);
    }
  }

  Future<void> _exportFilteredGraduates() async {
    try {
      final path = await CsvExportService.exportRows(
        filename:
            'graduates_export_${DateTime.now().millisecondsSinceEpoch}.csv',
        headers: const [
          'full_name',
          'program',
          'year_graduated',
          'batch_label',
          'email',
          'student_number',
          'is_registered',
          'has_tracer_submission',
          'employment_status',
          'source_file_name',
        ],
        rows: _filteredGraduates
            .map(
              (row) => [
                (row['full_name'] ?? '').toString(),
                (row['program'] ?? '').toString(),
                (row['year_graduated'] ?? '').toString(),
                (row['batch_label'] ?? '').toString(),
                (row['email'] ?? '').toString(),
                (row['student_number'] ?? '').toString(),
                (row['is_registered'] ?? false) == true ? 'Yes' : 'No',
                (row['has_tracer_submission'] ?? false) == true ? 'Yes' : 'No',
                (row['employment_status'] ?? 'Not Submitted').toString(),
                (row['source_file_name'] ?? '').toString(),
              ],
            )
            .toList(),
      );

      if (!mounted) return;
      _showSnack('Graduates exported: $path', Colors.green);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Failed to export graduates.', Colors.red);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 960;

    return Container(
      color: bgLight,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryMaroon))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isNarrow ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isNarrow),
                  const SizedBox(height: 24),
                  _buildAnalysisCard(),
                  const SizedBox(height: 24),
                  _buildFilterBar(isNarrow),
                  const SizedBox(height: 24),
                  _buildTableCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(bool compact) {
    return LuxuryModuleBanner(
      title: 'Graduates',
      description:
          'Upload your official graduate list from Excel, organize batches automatically by year graduated, and monitor how many graduates belong to each current program.',
      icon: Icons.upload_file_outlined,
      compact: compact,
      trailing: [_buildHeaderActions(compact)],
    );
  }

  Widget _buildHeaderActions(bool compact) {
    final secondaryStyle = FilledButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: primaryMaroon,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: 15,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      minimumSize: const Size(0, 52),
    );
    final primaryStyle = FilledButton.styleFrom(
      backgroundColor: accentGold,
      foregroundColor: primaryMaroon,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: 15,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      minimumSize: const Size(0, 52),
    );

    final buttons = [
      FilledButton.icon(
        onPressed: _downloadTemplate,
        style: secondaryStyle,
        icon: const Icon(Icons.download_outlined, size: 18),
        label: const Text('Download Template'),
      ),
      FilledButton.icon(
        onPressed: _isUploading ? null : _pickAndUploadFile,
        style: primaryStyle,
        icon: Icon(
          _isUploading ? Icons.hourglass_top : Icons.upload_rounded,
          size: 18,
        ),
        label: Text(_isUploading ? 'Uploading...' : 'Upload Graduate List'),
      ),
    ];

    if (compact) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: buttons,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          buttons[i],
        ],
      ],
    );
  }

  Widget _buildAnalysisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final cards = [
                _buildAnalysisMetricCard(
                  'Total BSIT Graduates',
                  '$_totalGraduates',
                  Icons.groups_2_outlined,
                  Colors.blue,
                  availableWidth,
                ),
                _buildAnalysisMetricCard(
                  'Registered Alumni',
                  '${_summary['registered_alumni'] ?? 0}',
                  Icons.verified_user_outlined,
                  Colors.green,
                  availableWidth,
                ),
                _buildAnalysisMetricCard(
                  'Tracer Respondents',
                  '${_summary['tracer_respondents'] ?? 0}',
                  Icons.assignment_turned_in_outlined,
                  accentGold,
                  availableWidth,
                ),
                _buildAnalysisMetricCard(
                  'Not Yet Registered',
                  '${_summary['unregistered_graduates'] ?? 0}',
                  Icons.person_add_alt_1_outlined,
                  Colors.deepOrange,
                  availableWidth,
                ),
              ];

              return Wrap(spacing: 16, runSpacing: 16, children: cards);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double availableWidth,
  ) {
    final cardWidth = availableWidth >= 620
        ? (availableWidth - 16) / 2
        : availableWidth;

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2A2024),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF2A2024),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(bool isNarrow) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilterActions(compact: true),
                const SizedBox(height: 12),
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildDropdown(
                  value: _selectedProgram,
                  items: _programOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedProgram = value!;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdown(
                  value: _selectedYear,
                  items: _yearOptions,
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value!;
                      _applyFilters();
                    });
                  },
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: _buildSearchField()),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    value: _selectedProgram,
                    items: _programOptions,
                    onChanged: (value) {
                      setState(() {
                        _selectedProgram = value!;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    value: _selectedYear,
                    items: _yearOptions,
                    onChanged: (value) {
                      setState(() {
                        _selectedYear = value!;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                _buildFilterActions(compact: false),
              ],
            ),
    );
  }

  Widget _buildFilterActions({required bool compact}) {
    return FilledButton.icon(
      onPressed: _filteredGraduates.isEmpty ? null : _exportFilteredGraduates,
      style: FilledButton.styleFrom(
        backgroundColor: accentGold,
        foregroundColor: primaryMaroon,
        minimumSize: Size(compact ? double.infinity : 0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.table_view_outlined, size: 18),
      label: const Text('Export Graduates'),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(_applyFilters),
      decoration: InputDecoration(
        hintText: 'Search graduate name, email, or student number...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: primaryMaroon),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTableCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minWidth = constraints.maxWidth < 1180
              ? 1180.0
              : constraints.maxWidth;

          if (_filteredGraduates.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No graduate records matched the current filters.'),
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minWidth),
              child: DataTable(
                columnSpacing: 24,
                headingRowColor: WidgetStateProperty.all(bgLight),
                columns: const [
                  DataColumn(label: Text('GRADUATE')),
                  DataColumn(label: Text('PROGRAM')),
                  DataColumn(label: Text('BATCH')),
                  DataColumn(label: Text('REGISTERED')),
                  DataColumn(label: Text('TRACER')),
                  DataColumn(label: Text('EMPLOYMENT')),
                  DataColumn(label: Text('SOURCE FILE')),
                ],
                rows: _filteredGraduates.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(
                       SizedBox(
                         width: 260,
                          child: Text(
                            (row['full_name'] ?? 'N/A').toString(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text((row['program'] ?? 'N/A').toString())),
                      DataCell(
                        Text(
                          (row['batch_label'] ?? 'Unassigned Batch').toString(),
                        ),
                      ),
                      DataCell(
                        _booleanBadge(
                          (row['is_registered'] ?? false) == true,
                          positive: 'Registered',
                          negative: 'Not Yet',
                        ),
                      ),
                      DataCell(
                        _booleanBadge(
                          (row['has_tracer_submission'] ?? false) == true,
                          positive: 'With Response',
                          negative: 'No Response',
                        ),
                      ),
                      DataCell(
                        _statusBadge(
                          (row['employment_status'] ?? 'Not Submitted')
                              .toString(),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Text(
                            (row['source_file_name'] ?? 'N/A').toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _booleanBadge(
    bool value, {
    required String positive,
    required String negative,
  }) {
    final color = value ? Colors.green : Colors.deepOrange;
    final label = value ? positive : negative;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'employed' || 'self-employed' || 'employer' => Colors.green,
      'unemployed' => Colors.red,
      'draft saved' || 'draft' => accentGold,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
