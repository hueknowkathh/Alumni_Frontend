import 'package:flutter/material.dart';

import '../../services/program_service.dart';
import '../widgets/luxury_module_banner.dart';

class ProgramsPage extends StatefulWidget {
  const ProgramsPage({super.key});

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> {
  static const Color primaryMaroon = Color(0xFF4A152C);
  static const Color accentGold = Color(0xFFC5A046);
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color borderColor = Color(0xFFE5E7EB);

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  List<AlumniProgram> _programs = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  int _editingId = 0;
  String _selectedTracerFormType = 'BSIT';
  bool _isActive = true;

  static const Map<String, String> _tracerTypeLabels = {
    'BSIT': 'BSIT Tracer Form',
    'BSSW': 'BSSW Tracer Form',
    'GENERIC': 'Generic Placeholder',
  };

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrograms() async {
    setState(() => _isLoading = true);
    try {
      final programs = await ProgramService.fetch();
      if (!mounted) return;
      setState(() {
        _programs = programs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Failed to load programs: $e', Colors.red);
    }
  }

  Future<void> _saveProgram() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final updatedPrograms = await ProgramService.save(
        AlumniProgram(
          id: _editingId,
          code: _codeController.text.trim().toUpperCase(),
          name: _nameController.text.trim(),
          tracerFormType: _selectedTracerFormType,
          isActive: _isActive,
        ),
      );
      if (!mounted) return;
      setState(() {
        _programs = updatedPrograms;
        _isSaving = false;
      });
      _clearForm();
      _showSnack('Program saved successfully.', Colors.green);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('Failed to save program: $e', Colors.red);
    }
  }

  void _editProgram(AlumniProgram program) {
    setState(() {
      _editingId = program.id;
      _codeController.text = program.code;
      _nameController.text = program.name;
      _selectedTracerFormType =
          _tracerTypeLabels.containsKey(program.tracerFormType)
          ? program.tracerFormType
          : 'BSIT';
      _isActive = program.isActive;
    });
  }

  void _clearForm() {
    setState(() {
      _editingId = 0;
      _codeController.clear();
      _nameController.clear();
      _selectedTracerFormType = 'BSIT';
      _isActive = true;
    });
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
    final isNarrow = MediaQuery.of(context).size.width < 920;

    return Container(
      color: bgLight,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryMaroon))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isNarrow ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LuxuryModuleBanner(
                    title: 'Programs',
                    description:
                        'Add academic programs and assign which tracer form each program should use. Dean and alumni-specific routing can build from these mappings later.',
                    icon: Icons.account_tree_outlined,
                    compact: isNarrow,
                    actions: [
                      LuxuryBannerAction(
                        icon: Icons.refresh_rounded,
                        label: 'Refresh',
                        onPressed: _fetchPrograms,
                        iconOnly: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (isNarrow)
                    Column(
                      children: [
                        _buildFormCard(),
                        const SizedBox(height: 20),
                        _buildProgramsTable(),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 390, child: _buildFormCard()),
                        const SizedBox(width: 20),
                        Expanded(child: _buildProgramsTable()),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_outlined, color: primaryMaroon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _editingId == 0 ? 'Add Program' : 'Edit Program',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildTextField(
              label: 'Program Code',
              controller: _codeController,
              hintText: 'Example: BSCRIM',
              validator: (value) {
                final code = (value ?? '').trim();
                if (code.isEmpty) return 'Required';
                if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(code)) {
                  return 'Use letters, numbers, dash, or underscore only';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Program Name',
              controller: _nameController,
              hintText: 'Bachelor of Science in ...',
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            _buildTracerDropdown(),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeThumbColor: primaryMaroon,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Active',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Active programs appear in assignment lists.',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProgram,
                    style: FilledButton.styleFrom(
                      backgroundColor: accentGold,
                      foregroundColor: primaryMaroon,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      _isSaving ? Icons.hourglass_top : Icons.save_outlined,
                      size: 18,
                    ),
                    label: Text(_isSaving ? 'Saving...' : 'Save Program'),
                  ),
                ),
                if (_editingId != 0) ...[
                  const SizedBox(width: 12),
                  IconButton.outlined(
                    onPressed: _clearForm,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Cancel edit',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: bgLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
              borderSide: BorderSide(color: primaryMaroon),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTracerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assigned Tracer Form',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: bgLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTracerFormType,
              isExpanded: true,
              items: _tracerTypeLabels.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedTracerFormType = value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgramsTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Program Directory',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          if (_programs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No programs configured yet.')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 26,
                headingRowColor: WidgetStateProperty.all(bgLight),
                columns: const [
                  DataColumn(label: Text('CODE')),
                  DataColumn(label: Text('PROGRAM')),
                  DataColumn(label: Text('TRACER FORM')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTION')),
                ],
                rows: _programs.map((program) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          program.code,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 280,
                          child: Text(
                            program.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _tracerTypeLabels[program.tracerFormType] ??
                              program.tracerFormType,
                        ),
                      ),
                      DataCell(_statusBadge(program.isActive)),
                      DataCell(
                        TextButton.icon(
                          onPressed: () => _editProgram(program),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool isActive) {
    final color = isActive ? Colors.green : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
