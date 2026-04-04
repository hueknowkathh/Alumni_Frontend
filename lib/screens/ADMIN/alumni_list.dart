import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/activity_service.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../services/csv_export_service.dart';
import '../../services/filter_options_service.dart';
import '../widgets/luxury_module_banner.dart';
import 'user_history_page.dart';

class AlumniList extends StatefulWidget {
  const AlumniList({super.key});

  @override
  State<AlumniList> createState() => _AlumniListState();
}

class _AlumniListState extends State<AlumniList> {
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE0E0E0);
  final Color accentGold = const Color(0xFFC5A046);
  final Color cardBorder = const Color(0xFFE5E7EB);
  final Color softRose = const Color(0xFFF8F1F4);

  List<dynamic> allAlumni = [];
  List<dynamic> filteredAlumni = [];
  bool isLoading = true;
  Timer? _autoRefreshTimer;

  String searchQuery = "";
  String selectedProgram = "All Programs";
  String selectedYear = "All Years";
  List<String> _programOptions = const ['All Programs'];
  List<String> _yearOptions = const ['All Years'];

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    fetchAlumni();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => fetchAlumni(showLoader: false),
    );
  }

  Future<void> _loadFilterOptions() async {
    try {
      final options = await FilterOptionsService.fetch();
      if (!mounted) return;
      setState(() {
        _programOptions = ['All Programs', ...options.programs];
        _yearOptions = ['All Years', ...options.years];
        if (!_programOptions.contains(selectedProgram)) {
          selectedProgram = _programOptions.first;
        }
        if (!_yearOptions.contains(selectedYear)) {
          selectedYear = _yearOptions.first;
        }
      });
    } catch (_) {
      // Keep existing fallback selections when dynamic filters are unavailable.
    }
  }

  // ✅ FETCH: Get all verified alumni
  Future<void> fetchAlumni({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => isLoading = true);
    }
    try {
      final response = await http.get(ApiService.uri('get_alumni_list.php'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          allAlumni = data;
          _applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Error connecting to server", Colors.red);
      setState(() => isLoading = false);
    }
  }

  String _resolveEmploymentStatus(Map<String, dynamic> user) {
    final candidates = [
      user['employment_status'],
      user['employmentStatus'],
      user['tracer_status'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isEmpty) continue;

      final lower = value.toLowerCase();
      if (lower == 'approved' ||
          lower == 'pending' ||
          lower == 'rejected' ||
          lower == 'verified') {
        continue;
      }

      return value;
    }

    return 'Not Submitted';
  }

  // ✅ DELETE: Remove user from DB
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _deleteAlumni(String id, String name) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text(
          "Are you sure you want to remove $name? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.post(
          ApiService.uri('delete_alumni.php'),
          body: {"id": id.toString()},
        );
        final result = json.decode(response.body);
        if (result['success']) {
          await ActivityService.logImportantFlow(
            action: 'delete_user',
            title: 'Admin deleted alumni record for $name',
            type: 'User Management',
            targetId: id,
            targetType: 'alumni',
            description: 'Deleted alumni record for $name.',
            metadata: {'deleted_user_id': id, 'deleted_user_name': name},
          );
          _showSnackBar("Alumni $name deleted.", Colors.green);
          fetchAlumni();
        }
      } catch (e) {
        _showSnackBar("Failed to delete.", Colors.red);
      }
    }
  }

  // ✅ VIEW: Show Detail Popup
  void _viewAlumni(Map<String, dynamic> user) {
    final employmentStatus = _resolveEmploymentStatus(user);

    showDialog(
      context: context,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;
        final height = MediaQuery.of(context).size.height;
        final isCompact = width < 560;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isCompact ? 18 : 28,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: height * 0.88,
            ),
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
                border: Border.all(
                  color: primaryMaroon.withValues(alpha: 0.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryMaroon.withValues(alpha: 0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 18 : 22,
                      isCompact ? 18 : 22,
                      isCompact ? 18 : 22,
                      isCompact ? 16 : 18,
                    ),
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
                    child: isCompact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileDialogHeader(
                                user,
                                isCompact: true,
                              ),
                            ],
                          )
                        : _buildProfileDialogHeader(
                            user,
                            isCompact: false,
                          ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isCompact ? 18 : 22,
                        18,
                        isCompact ? 18 : 22,
                        isCompact ? 18 : 20,
                      ),
                      child: Column(
                        children: [
                          _buildProfileInfoCard(
                            'Personal Details',
                            Icons.badge_outlined,
                            [
                              _buildProfileInfoTile(
                                'Full Name',
                                user['name']?.toString(),
                              ),
                              _buildProfileInfoTile(
                                'Email Address',
                                user['email']?.toString(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildProfileInfoCard(
                            'Academic & Career Snapshot',
                            Icons.insights_outlined,
                            [
                              _buildProfileInfoTile(
                                'Program',
                                user['program']?.toString(),
                              ),
                              _buildProfileInfoTile(
                                'Graduation Year',
                                user['year']?.toString(),
                              ),
                              _buildProfileInfoTile(
                                'Employment Status',
                                employmentStatus,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: primaryMaroon,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _viewUserHistory(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) =>
          AdminUserHistoryDialog(user: Map<String, dynamic>.from(user)),
    );
  }

  Future<void> _handleActionSelection(
    String action,
    Map<String, dynamic> user,
  ) async {
    switch (action) {
      case 'view':
        _viewAlumni(user);
        break;
      case 'history':
        _viewUserHistory(user);
        break;
      case 'delete':
        await _deleteAlumni(user['id'].toString(), user['name']);
        break;
    }
  }

  void _applyFilters() {
    setState(() {
      filteredAlumni = allAlumni.where((alumni) {
        final name = (alumni['name'] ?? "").toString().toLowerCase();
        final email = (alumni['email'] ?? "").toString().toLowerCase();
        final matchesSearch =
            name.contains(searchQuery.toLowerCase()) ||
            email.contains(searchQuery.toLowerCase());
        final matchesProgram =
            selectedProgram == "All Programs" ||
            alumni['program'] == selectedProgram;
        final matchesYear =
            selectedYear == "All Years" ||
            alumni['year'].toString() == selectedYear;
        return matchesSearch && matchesProgram && matchesYear;
      }).toList();
    });
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final path = await CsvExportService.exportRows(
        filename:
            'alumni_list_${DateTime.now().millisecondsSinceEpoch}.csv',
        headers: const ['Name', 'Email', 'Program', 'Year', 'Status'],
        rows: filteredAlumni
            .map(
              (user) => [
                (user['name'] ?? 'N/A').toString(),
                (user['email'] ?? 'N/A').toString(),
                (user['program'] ?? 'N/A').toString(),
                (user['year'] ?? 'N/A').toString(),
                (user['status'] ?? 'N/A').toString(),
              ],
            )
            .toList(),
      );
      if (!mounted) return;
      _showSnackBar('CSV exported: $path', Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Failed to export CSV.', Colors.red);
    }
  }

  Widget _buildProfileDialogBadge() {
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accentGold.withValues(alpha: 0.34)),
      ),
      child: Icon(Icons.person_outline_rounded, color: accentGold, size: 34),
    );
  }

  Widget _buildProfileDialogHeader(
    Map<String, dynamic> user, {
    required bool isCompact,
  }) {
    final name = user['name']?.toString().trim();
    final program = user['program']?.toString().trim();
    final year = user['year']?.toString().trim();
    final summaryText = [
      if (program != null && program.isNotEmpty) program,
      if (year != null && year.isNotEmpty) 'Batch $year',
    ].join(' • ');

    final displayName =
        (name == null || name.isEmpty) ? 'Unnamed Alumni' : name;
    final profileChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        'ALUMNI PROFILE',
        style: TextStyle(
          color: accentGold,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );

    if (isCompact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileDialogBadge(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(alignment: Alignment.centerRight, child: profileChip),
                const SizedBox(height: 10),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                if (summaryText.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      summaryText,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildProfileDialogBadge(),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
        ),
        const SizedBox(width: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              profileChip,
              if (summaryText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  summaryText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfoCard(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: softRose,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: primaryMaroon),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileInfoTile(String label, String? value) {
    final normalized = value?.trim();
    final displayValue =
        (normalized == null || normalized.isEmpty) ? 'N/A' : normalized;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFCF8F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor.withValues(alpha: 0.9)),
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
            const SizedBox(height: 6),
            Text(
              displayValue,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 920;
    return Container(
      color: bgLight,
      child: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryMaroon))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isNarrow ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFilterBar(),
                  const SizedBox(height: 24),
                  _buildTableContainer(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final width = MediaQuery.of(context).size.width;
    final isStacked = width < 980;
    return LuxuryModuleBanner(
      title: 'Alumni List',
      description:
          'Review verified graduates, browse their records, and access user history in a cleaner management layout.',
      icon: Icons.groups_2_outlined,
      compact: isStacked,
      actions: [
        LuxuryBannerAction(
          icon: Icons.refresh_rounded,
          label: 'Refresh',
          onPressed: fetchAlumni,
        ),
        LuxuryBannerAction(
          icon: Icons.table_view_outlined,
          label: 'Export CSV',
          onPressed: filteredAlumni.isEmpty ? null : _exportCsv,
          filled: true,
          enabled: filteredAlumni.isNotEmpty,
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final isNarrow = MediaQuery.of(context).size.width < 920;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
      ),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildDropdown(
                  selectedProgram,
                  _programOptions,
                  (val) {
                    setState(() {
                      selectedProgram = val!;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildDropdown(
                  selectedYear,
                  _yearOptions,
                  (val) {
                    setState(() {
                      selectedYear = val!;
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
                    selectedProgram,
                    _programOptions,
                    (val) {
                      setState(() {
                        selectedProgram = val!;
                        _applyFilters();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    selectedYear,
                    _yearOptions,
                    (val) {
                      setState(() {
                        selectedYear = val!;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (val) {
        searchQuery = val;
        _applyFilters();
      },
      decoration: InputDecoration(
        hintText: "Search name or email...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryMaroon),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String val,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTableContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minTableWidth = constraints.maxWidth < 940
              ? 940.0
              : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minTableWidth),
              child: DataTable(
                columnSpacing: 24,
                headingRowColor: WidgetStateProperty.all(bgLight),
                columns: const [
                  DataColumn(label: Text("NAME")),
                  DataColumn(label: Text("PROGRAM")),
                  DataColumn(label: Text("YEAR")),
                  DataColumn(label: Text("STATUS")),
                  DataColumn(label: Text("ACTIONS")),
                ],
                rows: filteredAlumni
                    .map(
                      (user) => DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 240,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    user['name'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    user['email'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 160,
                              child: Text(
                                user['program'] ?? 'N/A',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(user['year']?.toString() ?? 'N/A')),
                          DataCell(_statusBadge(user['status'] ?? 'N/A')),
                          DataCell(
                            SizedBox(
                              width: 72,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: PopupMenuButton<String>(
                                  tooltip: 'More actions',
                                  icon: Icon(
                                    Icons.more_vert_rounded,
                                    color: primaryMaroon,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  onSelected: (value) =>
                                      _handleActionSelection(value, user),
                                  itemBuilder: (context) => const [
                                    PopupMenuItem<String>(
                                      value: 'view',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.visibility_outlined,
                                            color: Colors.blue,
                                            size: 18,
                                          ),
                                          SizedBox(width: 10),
                                          Text('View profile'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'history',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.history_outlined,
                                            color: Color(0xFF4A152C),
                                            size: 18,
                                          ),
                                          SizedBox(width: 10),
                                          Text('Show history'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                          SizedBox(width: 10),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = status == "Employed"
        ? Colors.green
        : (status == "Unemployed" ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
