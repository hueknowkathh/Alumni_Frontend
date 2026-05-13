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
  static const String _sharedTracerSubtitle =
      'Aligned with CHED QA Indicators, AUN-QA, ISO 9001:2015, and QILT GOS-L Benchmarks';

  final _formKey = GlobalKey<FormState>();
  final _templateFormKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _templateCodeController = TextEditingController();
  final _templateLabelController = TextEditingController();
  final _templateTitleController = TextEditingController();
  final _templateJobRelatedController = TextEditingController();
  final _templateLicensureLabelController = TextEditingController();
  final _templateLicensureTypeController = TextEditingController();
  final _templateLicensureResultController = TextEditingController();
  final _templateCurriculumController = TextEditingController();
  final _templateRecommendationController = TextEditingController();
  final _templateReputationController = TextEditingController();
  final _templateFeedbackController = TextEditingController();
  final List<TextEditingController> _studyTypeControllers = [];
  final List<TextEditingController> _skillControllers = [];
  final List<TextEditingController> _peoControllers = [];

  List<AlumniProgram> _programs = const [];
  List<TracerTemplateConfig> _templates = const [];
  List<TracerFormTypeOption> _tracerFormTypes = const [
    TracerFormTypeOption(code: 'BSIT', label: 'BSIT Tracer Form'),
    TracerFormTypeOption(code: 'BSSW', label: 'BSSW Tracer Form'),
    TracerFormTypeOption(code: 'GENERIC', label: 'Generic Tracer Form'),
  ];
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSavingTemplate = false;
  int _editingId = 0;
  int _editingTemplateId = 0;
  String _selectedTracerFormType = 'GENERIC';
  bool _isActive = true;
  bool _isTemplateActive = true;

  @override
  void initState() {
    super.initState();
    _replaceControllers(_studyTypeControllers, const []);
    _replaceControllers(_skillControllers, const []);
    _replaceControllers(_peoControllers, const []);
    _fetchPrograms();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _templateCodeController.dispose();
    _templateLabelController.dispose();
    _templateTitleController.dispose();
    _templateJobRelatedController.dispose();
    _templateLicensureLabelController.dispose();
    _templateLicensureTypeController.dispose();
    _templateLicensureResultController.dispose();
    _templateCurriculumController.dispose();
    _templateRecommendationController.dispose();
    _templateReputationController.dispose();
    _templateFeedbackController.dispose();
    _disposeControllers(_studyTypeControllers);
    _disposeControllers(_skillControllers);
    _disposeControllers(_peoControllers);
    super.dispose();
  }

  Future<void> _fetchPrograms() async {
    setState(() => _isLoading = true);
    try {
      final directory = await ProgramService.fetchDirectory();
      final templates = await ProgramService.fetchTracerTemplates();
      if (!mounted) return;
      setState(() {
        _programs = directory.programs;
        _templates = templates;
        if (directory.tracerFormTypes.isNotEmpty) {
          _tracerFormTypes = directory.tracerFormTypes;
        }
        if (!_tracerTypeLabels.containsKey(_selectedTracerFormType)) {
          _selectedTracerFormType = _tracerFormTypes.first.code;
        }
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
          : _tracerFormTypes.first.code;
      _isActive = program.isActive;
    });
  }

  void _clearForm() {
    setState(() {
      _editingId = 0;
      _codeController.clear();
      _nameController.clear();
      _selectedTracerFormType = _tracerFormTypes.first.code;
      _isActive = true;
    });
  }

  Future<void> _saveTemplate() async {
    if (!_templateFormKey.currentState!.validate() || _isSavingTemplate) {
      return;
    }
    if (_controllerValues(_peoControllers).isEmpty) {
      _showSnack('Add at least one PEO statement.', Colors.red);
      return;
    }

    setState(() => _isSavingTemplate = true);
    try {
      final templates = await ProgramService.saveTracerTemplate(
        TracerTemplateConfig(
          id: _editingTemplateId,
          code: _templateCodeController.text.trim().toUpperCase(),
          label: _templateLabelController.text.trim(),
          programTitle: _templateTitleController.text.trim(),
          programSubtitle: _sharedTracerSubtitle,
          currentJobRelatedLabel: _templateJobRelatedController.text.trim(),
          studyTypeOptions: _controllerValues(_studyTypeControllers),
          licensureLabel: _templateLicensureLabelController.text.trim(),
          licensureTypeLabel: _templateLicensureTypeController.text.trim(),
          licensureResultLabel: _templateLicensureResultController.text.trim(),
          skillsOptions: _controllerValues(_skillControllers),
          peoStatements: _controllerValues(_peoControllers),
          curriculumSatisfactionLabel: _templateCurriculumController.text
              .trim(),
          recommendationLabel: _templateRecommendationController.text.trim(),
          reputationLabel: _templateReputationController.text.trim(),
          feedbackCompetenciesLabel: _templateFeedbackController.text.trim(),
          isActive: _isTemplateActive,
        ),
      );
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _tracerFormTypes = templates
            .where((template) => template.isActive)
            .map(
              (template) => TracerFormTypeOption(
                code: template.code,
                label: template.label,
              ),
            )
            .toList();
        _isSavingTemplate = false;
      });
      _clearTemplateForm();
      _showSnack('Tracer template saved successfully.', Colors.green);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingTemplate = false);
      _showSnack('Failed to save template: $e', Colors.red);
    }
  }

  List<String> _controllerValues(List<TextEditingController> controllers) {
    return controllers
        .map((controller) => controller.text.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }

  void _disposeControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.dispose();
    }
    controllers.clear();
  }

  void _replaceControllers(
    List<TextEditingController> controllers,
    List<String> values,
  ) {
    _disposeControllers(controllers);
    final cleanValues = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    for (final value in cleanValues.isEmpty ? [''] : cleanValues) {
      controllers.add(TextEditingController(text: value));
    }
  }

  void _addListItem(List<TextEditingController> controllers) {
    setState(() {
      controllers.add(TextEditingController());
    });
  }

  void _removeListItem(List<TextEditingController> controllers, int index) {
    if (index < 0 || index >= controllers.length) return;
    setState(() {
      final controller = controllers.removeAt(index);
      controller.dispose();
      if (controllers.isEmpty) {
        controllers.add(TextEditingController());
      }
    });
  }

  void _editTemplate(TracerTemplateConfig template) {
    setState(() {
      _editingTemplateId = template.id;
      _templateCodeController.text = template.code;
      _templateLabelController.text = template.label;
      _templateTitleController.text = template.programTitle;
      _templateJobRelatedController.text = template.currentJobRelatedLabel;
      _replaceControllers(_studyTypeControllers, template.studyTypeOptions);
      _templateLicensureLabelController.text = template.licensureLabel;
      _templateLicensureTypeController.text = template.licensureTypeLabel;
      _templateLicensureResultController.text = template.licensureResultLabel;
      _replaceControllers(_skillControllers, template.skillsOptions);
      _replaceControllers(_peoControllers, template.peoStatements);
      _templateCurriculumController.text = template.curriculumSatisfactionLabel;
      _templateRecommendationController.text = template.recommendationLabel;
      _templateReputationController.text = template.reputationLabel;
      _templateFeedbackController.text = template.feedbackCompetenciesLabel;
      _isTemplateActive = template.isActive;
    });
  }

  void _clearTemplateForm() {
    setState(() {
      _editingTemplateId = 0;
      _templateCodeController.clear();
      _templateLabelController.clear();
      _templateTitleController.clear();
      _templateJobRelatedController.clear();
      _templateLicensureLabelController.clear();
      _templateLicensureTypeController.clear();
      _templateLicensureResultController.clear();
      _templateCurriculumController.clear();
      _templateRecommendationController.clear();
      _templateReputationController.clear();
      _templateFeedbackController.clear();
      _replaceControllers(_studyTypeControllers, const []);
      _replaceControllers(_skillControllers, const []);
      _replaceControllers(_peoControllers, const []);
      _isTemplateActive = true;
    });
  }

  Map<String, String> get _tracerTypeLabels => {
    for (final type in _tracerFormTypes) type.code: type.label,
  };

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
                  const SizedBox(height: 24),
                  _buildTemplateManager(isNarrow),
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
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
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
              items: _tracerFormTypes
                  .map(
                    (type) => DropdownMenuItem(
                      value: type.code,
                      child: Text(type.label),
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

  Widget _buildTemplateManager(bool isNarrow) {
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
          Row(
            children: [
              const Icon(Icons.dynamic_form_outlined, color: primaryMaroon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _editingTemplateId == 0
                      ? 'Tracer Form Templates'
                      : 'Edit Tracer Template',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_templates.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _templates
                  .map(
                    (template) => ActionChip(
                      label: Text(template.label),
                      avatar: Icon(
                        template.isActive
                            ? Icons.check_circle_outline
                            : Icons.pause_circle_outline,
                        size: 18,
                      ),
                      onPressed: () => _editTemplate(template),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 18),
          Form(
            key: _templateFormKey,
            child: Column(
              children: [
                _buildResponsiveFieldGroup(
                  isNarrow: isNarrow,
                  children: _templateCoreFields(),
                ),
                const SizedBox(height: 18),
                _buildTextField(
                  label: 'Current Job Related Label',
                  controller: _templateJobRelatedController,
                  hintText: '21. Is your current job related to ...?',
                  validator: (_) => null,
                ),
                const SizedBox(height: 22),
                _buildResponsiveFieldGroup(
                  isNarrow: isNarrow,
                  children: _templateLicensureFields(),
                ),
                const SizedBox(height: 22),
                _buildDynamicListSection(
                  title: 'Study Type Options',
                  itemLabelPrefix: 'Option',
                  controllers: _studyTypeControllers,
                  addLabel: 'Add Study Type',
                  hintText: 'Certificate',
                ),
                const SizedBox(height: 16),
                _buildDynamicListSection(
                  title: 'Skills Options',
                  itemLabelPrefix: 'Skill',
                  controllers: _skillControllers,
                  addLabel: 'Add Skill',
                  hintText: 'Communication Skills',
                ),
                const SizedBox(height: 16),
                _buildDynamicListSection(
                  title: 'PEO Statements',
                  itemLabelPrefix: 'PEO',
                  controllers: _peoControllers,
                  addLabel: 'Add PEO',
                  hintText: 'Demonstrate professional competence...',
                  multiline: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Curriculum Satisfaction Label',
                  controller: _templateCurriculumController,
                  hintText: 'Curriculum relevance to ... practice',
                  validator: (_) => null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Recommendation Label',
                  controller: _templateRecommendationController,
                  hintText: '56. How likely are you to recommend...',
                  validator: (_) => null,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Reputation Label',
                  controller: _templateReputationController,
                  hintText: '57. How would you describe...',
                  validator: (_) => null,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Feedback Competencies Label',
                  controller: _templateFeedbackController,
                  hintText: '59. What specific competencies...',
                  validator: (_) => null,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isTemplateActive,
                  onChanged: (value) =>
                      setState(() => _isTemplateActive = value),
                  activeThumbColor: primaryMaroon,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Active Template',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Active templates can be assigned to programs.',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSavingTemplate ? null : _saveTemplate,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryMaroon,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Icon(
                          _isSavingTemplate
                              ? Icons.hourglass_top
                              : Icons.save_outlined,
                          size: 18,
                        ),
                        label: Text(
                          _isSavingTemplate
                              ? 'Saving...'
                              : 'Save Tracer Template',
                        ),
                      ),
                    ),
                    if (_editingTemplateId != 0) ...[
                      const SizedBox(width: 12),
                      IconButton.outlined(
                        onPressed: _clearTemplateForm,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Cancel edit',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveFieldGroup({
    required bool isNarrow,
    required List<Widget> children,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();

    if (isNarrow) {
      return Column(
        children: [
          for (var index = 0; index < children.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == children.length - 1 ? 0 : 16,
              ),
              child: children[index],
            ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          Expanded(child: children[index]),
          if (index != children.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _buildDynamicListSection({
    required String title,
    required String itemLabelPrefix,
    required List<TextEditingController> controllers,
    required String addLabel,
    required String hintText,
    bool multiline = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              SizedBox(
                width: 260,
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: () => _addListItem(controllers),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(addLabel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(controllers.length, (index) {
            final controller = controllers[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == controllers.length - 1 ? 0 : 10,
              ),
              child: Row(
                crossAxisAlignment: multiline
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      minLines: multiline ? 2 : 1,
                      maxLines: multiline ? 4 : 1,
                      decoration: InputDecoration(
                        labelText: '$itemLabelPrefix ${index + 1}',
                        hintText: hintText,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: primaryMaroon),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: controllers.length <= 1
                        ? null
                        : () => _removeListItem(controllers, index),
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: 'Remove ${itemLabelPrefix.toLowerCase()}',
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _templateCoreFields() {
    return [
      _buildTextField(
        label: 'Template Code',
        controller: _templateCodeController,
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
      _buildTextField(
        label: 'Template Label',
        controller: _templateLabelController,
        hintText: 'BSCRIM Tracer Form',
        validator: (value) => (value ?? '').trim().isEmpty ? 'Required' : null,
      ),
      _buildTextField(
        label: 'Form Title',
        controller: _templateTitleController,
        hintText: 'BS Criminology Graduate Tracer Study Questionnaire',
        validator: (value) => (value ?? '').trim().isEmpty ? 'Required' : null,
      ),
    ];
  }

  List<Widget> _templateLicensureFields() {
    return [
      _buildTextField(
        label: 'Licensure Label',
        controller: _templateLicensureLabelController,
        hintText: '35. Did you take any board or licensure exam?',
        validator: (_) => null,
      ),
      _buildTextField(
        label: 'Licensure Type Label',
        controller: _templateLicensureTypeController,
        hintText: 'If yes, what is the type...',
        validator: (_) => null,
      ),
      _buildTextField(
        label: 'Licensure Result Label',
        controller: _templateLicensureResultController,
        hintText: 'If yes, result',
        validator: (_) => null,
      ),
    ];
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
