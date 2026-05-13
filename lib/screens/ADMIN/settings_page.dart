import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/activity_service.dart';
import '../../services/api_service.dart';
import '../../services/program_service.dart';
import '../../state/user_store.dart';
import '../widgets/luxury_module_banner.dart';

class AdminSettings extends StatefulWidget {
  const AdminSettings({super.key});

  @override
  State<AdminSettings> createState() => _AdminSettingsState();
}

class _AdminSettingsState extends State<AdminSettings> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _provisionFormKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _newUserFirstNameController;
  late final TextEditingController _newUserLastNameController;
  late final TextEditingController _newUserEmailController;
  late final TextEditingController _newUserPasswordController;

  List<Map<String, dynamic>> _privilegedUsers = [];
  List<String> _programOptions = const ['BSIT', 'BSSW'];
  final Set<int> _deletingPrivilegedUserIds = <int>{};
  bool _emailAnnouncements = true;
  bool _emailReminders = true;
  bool _eventInvitations = false;
  bool _isSavingProfile = false;
  bool _isSavingSettings = false;
  bool _isSavingPassword = false;
  bool _isCreatingUser = false;
  bool _isLoadingPrivilegedUsers = false;
  String _provisionRole = 'dean';
  String _provisionProgram = 'BSIT';

  final Color bgLight = const Color(0xFFF8F9FA);
  final Color borderColor = const Color(0xFFE5E7EB);
  final Color fieldFillColor = const Color(0xFFF1F3F4);
  final Color darkButtonColor = const Color(0xFF0D0D1D);
  final Color accentGold = const Color(0xFFC5A046);

  Map<String, dynamic> get _user =>
      UserStore.value ?? const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: _readValue(['firstName', 'first_name']),
    );
    _lastNameController = TextEditingController(
      text: _readValue(['lastName', 'last_name']),
    );
    _emailController = TextEditingController(text: _readValue(['email']));
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _newUserFirstNameController = TextEditingController();
    _newUserLastNameController = TextEditingController();
    _newUserEmailController = TextEditingController();
    _newUserPasswordController = TextEditingController();
    _fetchPrivilegedUsers();
    _fetchProgramOptions();

    _emailAnnouncements =
        _boolFromUser(
          'emailAnnouncements',
          fallbackKey: 'email_announcements',
        ) ??
        true;
    _emailReminders =
        _boolFromUser('emailReminders', fallbackKey: 'email_reminders') ?? true;
    _eventInvitations =
        _boolFromUser('eventInvitations', fallbackKey: 'event_invitations') ??
        false;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newUserFirstNameController.dispose();
    _newUserLastNameController.dispose();
    _newUserEmailController.dispose();
    _newUserPasswordController.dispose();
    super.dispose();
  }

  String _readValue(List<String> keys) {
    for (final key in keys) {
      final value = _user[key];
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }

  bool? _boolFromUser(String primaryKey, {String? fallbackKey}) {
    final value =
        _user[primaryKey] ?? (fallbackKey == null ? null : _user[fallbackKey]);
    if (value is bool) return value;
    if (value is num) return value == 1;
    final text = value?.toString().trim().toLowerCase() ?? '';
    if (text.isEmpty) return null;
    return text == '1' || text == 'true' || text == 'yes';
  }

  int get _userId => int.tryParse((_user['id'] ?? '').toString()) ?? 0;

  int _toInt(dynamic value) => int.tryParse((value ?? '').toString()) ?? 0;

  Map<String, dynamic> _normalizePrivilegedHistoryItem(
    Map<String, dynamic> item,
  ) {
    final metadata = item['metadata'] is Map
        ? (item['metadata'] as Map).map((key, value) => MapEntry('$key', value))
        : const <String, dynamic>{};
    final targetId = _toInt(item['target_id'] ?? metadata['target_id']);
    final createdRole =
        (metadata['created_role'] ?? item['target_type'] ?? item['role'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

    return {
      'id': targetId,
      'name':
          (metadata['target_user_name'] ??
                  item['target_name'] ??
                  item['title'] ??
                  'Created account')
              .toString(),
      'email': (metadata['email'] ?? item['user_email'] ?? '').toString(),
      'role': createdRole,
      'program': (metadata['program'] ?? '').toString(),
      'created_at': (item['occurred_at'] ?? item['created_at'] ?? '')
          .toString(),
      'user_name': (item['user_name'] ?? metadata['actor_name'] ?? '')
          .toString(),
      'metadata': metadata,
      'source_type': 'activity',
      'can_delete': targetId > 0,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchPrivilegedUsersFromActivity() async {
    final response = await http.get(
      ApiService.uri('get_full_activity.php'),
      headers: ApiService.authHeaders(),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200 || decoded is! List) {
      throw Exception('Activity history unavailable.');
    }

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) {
          final metadata = item['metadata'] is Map
              ? (item['metadata'] as Map).map(
                  (key, value) => MapEntry('$key', value),
                )
              : const <String, dynamic>{};
          final createdRole = (metadata['created_role'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          final action = (item['action'] ?? '').toString().trim().toLowerCase();
          return action == 'create_user' &&
              (createdRole == 'admin' || createdRole == 'dean');
        })
        .map(_normalizePrivilegedHistoryItem)
        .where((item) => _toInt(item['id']) > 0)
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchPrivilegedUserHistory(
    Map<String, dynamic> account,
  ) async {
    final accountId = _toInt(account['id']);
    final role = (account['role'] ?? '').toString().trim().toLowerCase();
    if (accountId <= 0) {
      throw Exception('Missing privileged account ID.');
    }

    final response = await http.get(
      ApiService.uri(
        'get_privileged_user_history.php',
        queryParameters: {
          'user_id': accountId,
          if (role.isNotEmpty) 'role': role,
        },
      ),
      headers: ApiService.authHeaders(),
    );

    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200 &&
        decoded is Map<String, dynamic> &&
        decoded['status'] == 'success' &&
        decoded['history'] is List) {
      return (decoded['history'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception('Unable to load privileged account history.');
  }

  String _historyEventSubtitle(Map<String, dynamic> entry) {
    final parts = <String>[
      (entry['description'] ?? '').toString().trim(),
      (entry['type'] ?? '').toString().trim(),
      (entry['program'] ?? '').toString().trim().isEmpty
          ? ''
          : 'Program: ${(entry['program'] ?? '').toString().trim()}',
      (entry['user_name'] ?? '').toString().trim().isEmpty
          ? ''
          : 'Actor: ${(entry['user_name'] ?? '').toString().trim()}',
    ].where((value) => value.isNotEmpty).toList();

    return parts.join(' | ');
  }

  Future<void> _showPrivilegedUserHistory(Map<String, dynamic> account) async {
    final accountName = (account['name'] ?? 'Privileged account').toString();
    final accountRole = (account['role'] ?? '').toString().toUpperCase();
    final accountEmail = (account['email'] ?? '').toString();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760, maxHeight: 620),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              accountName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              [
                                if (accountEmail.trim().isNotEmpty)
                                  accountEmail,
                                if (accountRole.trim().isNotEmpty) accountRole,
                              ].join(' | '),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchPrivilegedUserHistory(account),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Unable to load this account history right now.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          );
                        }

                        final history = snapshot.data ?? const [];
                        if (history.isEmpty) {
                          return Center(
                            child: Text(
                              'No history found for this account yet.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          );
                        }

                        return ListView.separated(
                          itemCount: history.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final entry = history[index];
                            final title = (entry['title'] ?? 'Activity')
                                .toString();
                            final subtitle = _historyEventSubtitle(entry);
                            final time =
                                (entry['time'] ??
                                        entry['occurred_at'] ??
                                        entry['created_at'] ??
                                        '')
                                    .toString();

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: fieldFillColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  if (time.trim().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      time,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
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

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    if (_userId <= 0 || _isSavingProfile) return;

    setState(() => _isSavingProfile = true);

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = [
      firstName,
      lastName,
    ].where((value) => value.isNotEmpty).join(' ');
    final email = _emailController.text.trim();

    try {
      final response = await http.post(
        ApiService.uri('update_profile.php'),
        headers: ApiService.jsonHeaders(),
        body: jsonEncode({
          'userId': _userId,
          'firstName': firstName,
          'lastName': lastName,
          'name': fullName,
          'email': email,
          'phone': _readValue(['phone']),
          'address': _readValue(['address']),
          'status': _readValue(['civilStatus', 'civil_status']),
          'gradYear': _readValue([
            'gradYear',
            'year_graduated',
            'graduation_year',
          ]),
          'degree': _readValue(['degree', 'program']),
          'major': _readValue(['major', 'program']),
          'program': _readValue(['program', 'degree']),
        }),
      );

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      if (!mounted) return;

      if (response.statusCode == 200 && data['status'] == 'success') {
        final updatedUser = data['user'] is Map
            ? Map<String, dynamic>.from(data['user'] as Map)
            : <String, dynamic>{};
        UserStore.patch({
          'name': fullName,
          'firstName': firstName,
          'first_name': firstName,
          'lastName': lastName,
          'last_name': lastName,
          'email': email,
          ...updatedUser,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin profile updated successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ?? 'Failed to update admin profile.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating admin profile.')),
      );
      debugPrint('Admin profile update error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _saveNotificationSettings() async {
    if (_userId <= 0 || _isSavingSettings) return;
    setState(() => _isSavingSettings = true);

    try {
      final response = await http.post(
        ApiService.uri('update_settings.php'),
        headers: ApiService.jsonHeaders(),
        body: jsonEncode({
          'userId': _userId,
          'emailAnnouncements': _emailAnnouncements,
          'emailReminders': _emailReminders,
          'eventInvitations': _eventInvitations,
        }),
      );

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      if (!mounted) return;

      if (response.statusCode == 200 && data['status'] == 'success') {
        final settings = data['settings'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['settings'])
            : <String, dynamic>{};
        UserStore.patch({
          ...settings,
          'email_announcements': settings['emailAnnouncements'],
          'email_reminders': settings['emailReminders'],
          'event_invitations': settings['eventInvitations'],
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings updated.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ?? 'Failed to update settings.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating notification settings.')),
      );
      debugPrint('Admin settings update error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSavingSettings = false);
      }
    }
  }

  Future<void> _updatePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    if (_userId <= 0 || _isSavingPassword) return;

    setState(() => _isSavingPassword = true);

    try {
      final response = await http.post(
        ApiService.uri('change_password.php'),
        headers: ApiService.jsonHeaders(),
        body: jsonEncode({
          'userId': _userId,
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      if (!mounted) return;

      if (response.statusCode == 200 && data['status'] == 'success') {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ?? 'Password updated successfully.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ?? 'Failed to update password.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error updating password.')));
      debugPrint('Admin password update error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSavingPassword = false);
      }
    }
  }

  Future<void> _createPrivilegedUser() async {
    if (!_provisionFormKey.currentState!.validate()) return;
    if (_isCreatingUser) return;

    setState(() => _isCreatingUser = true);

    final firstName = _newUserFirstNameController.text.trim();
    final lastName = _newUserLastNameController.text.trim();
    final fullName = [
      firstName,
      lastName,
    ].where((value) => value.isNotEmpty).join(' ');
    final role = _provisionRole;
    final program = role == 'dean' ? _provisionProgram : '';

    try {
      final response = await http.post(
        ApiService.uri('admin_create_user.php'),
        headers: ApiService.jsonHeaders(),
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'name': fullName,
          'email': _newUserEmailController.text.trim(),
          'password': _newUserPasswordController.text,
          'role': role,
          'program': program,
        }),
      );

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      if (!mounted) return;

      if (response.statusCode == 200 && data['status'] == 'success') {
        await ActivityService.logImportantFlow(
          action: 'create_user',
          title:
              'Admin created a ${role == 'dean' ? 'Dean' : 'Admin'} account for $fullName',
          type: 'User Management',
          targetId: (data['user'] as Map?)?['id']?.toString() ?? '',
          targetType: role,
          description: role == 'dean'
              ? 'Assigned program: $program'
              : 'Privileged account created by admin.',
          metadata: {
            'program': program,
            'created_role': role,
            'email': _newUserEmailController.text.trim(),
            'target_user_name': fullName,
          },
        );

        if (!mounted) return;

        _newUserFirstNameController.clear();
        _newUserLastNameController.clear();
        _newUserEmailController.clear();
        _newUserPasswordController.clear();
        setState(() {
          _provisionRole = 'dean';
          _provisionProgram = 'BSIT';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ?? 'Privileged account created.',
            ),
          ),
        );
        _fetchPrivilegedUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ?? 'Failed to create user.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating privileged account.')),
      );
      debugPrint('Admin create user error: $e');
    } finally {
      if (mounted) {
        setState(() => _isCreatingUser = false);
      }
    }
  }

  Future<void> _fetchProgramOptions() async {
    try {
      final programs = await ProgramService.fetch(activeOnly: true);
      if (!mounted || programs.isEmpty) return;
      final options = programs.map((program) => program.code).toList();
      setState(() {
        _programOptions = options;
        if (!_programOptions.contains(_provisionProgram)) {
          _provisionProgram = _programOptions.first;
        }
      });
    } catch (_) {
      // Keep the built-in defaults if the program directory is unavailable.
    }
  }

  Future<void> _fetchPrivilegedUsers() async {
    if (_isLoadingPrivilegedUsers) return;
    setState(() => _isLoadingPrivilegedUsers = true);

    try {
      List<Map<String, dynamic>> rawUsers = const <Map<String, dynamic>>[];
      var loadedFromDirectory = false;

      try {
        final response = await http.get(
          ApiService.uri('get_privileged_users.php'),
          headers: ApiService.authHeaders(),
        );
        final decoded = jsonDecode(response.body);
        if (response.statusCode == 200 &&
            decoded is Map<String, dynamic> &&
            decoded['status'] == 'success' &&
            decoded['users'] is List) {
          rawUsers = (decoded['users'] as List)
              .whereType<Map>()
              .map(
                (item) => {
                  ...Map<String, dynamic>.from(item),
                  'source_type': 'directory',
                  'can_delete': false,
                },
              )
              .toList();
          loadedFromDirectory = true;
        }
      } catch (_) {
        loadedFromDirectory = false;
      }

      if (!loadedFromDirectory) {
        rawUsers = await _fetchPrivilegedUsersFromActivity();
      }

      if (!mounted) return;

      setState(() {
        _privilegedUsers = rawUsers;
      });

      if (!loadedFromDirectory && rawUsers.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Loaded privileged account history from activity logs.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading privileged account history.'),
        ),
      );
      debugPrint('Privileged account history fetch error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPrivilegedUsers = false);
      }
    }
  }

  Future<void> _deletePrivilegedUser(Map<String, dynamic> account) async {
    final accountId = int.tryParse((account['id'] ?? '').toString()) ?? 0;
    if (accountId <= 0 || _deletingPrivilegedUserIds.contains(accountId)) {
      return;
    }

    final role = (account['role'] ?? 'user').toString().trim().toLowerCase();
    final accountName = (account['name'] ?? 'This account').toString().trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Text(
            'Remove ${accountName.isEmpty ? 'this account' : accountName} from privileged access? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingPrivilegedUserIds.add(accountId);
    });

    try {
      final response = await http.post(
        ApiService.uri('delete_privileged_user.php'),
        headers: ApiService.jsonHeaders(),
        body: jsonEncode({'id': accountId}),
      );

      final decoded = jsonDecode(response.body);
      final data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};

      if (!mounted) return;

      if (response.statusCode == 200 && data['status'] == 'success') {
        await ActivityService.logImportantFlow(
          action: 'delete_user',
          title:
              'Admin removed a ${role == 'dean' ? 'Dean' : 'Admin'} account for ${accountName.isEmpty ? 'a user' : accountName}',
          type: 'User Management',
          targetId: '$accountId',
          targetType: role,
          description: 'Privileged account deleted by admin.',
          metadata: {
            'deleted_role': role,
            'email': (account['email'] ?? '').toString(),
            'target_user_name': accountName,
          },
        );

        if (!mounted) return;

        setState(() {
          _privilegedUsers.removeWhere(
            (item) => int.tryParse((item['id'] ?? '').toString()) == accountId,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ?? 'Privileged account deleted.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ?? 'Failed to delete the account.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting privileged account.')),
      );
      debugPrint('Privileged account delete error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _deletingPrivilegedUserIds.remove(accountId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = (_user['role'] ?? 'admin').toString();
    final isCompact = MediaQuery.of(context).size.width < 720;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF7F8FA), Color(0xFFF4F1F2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      width: double.infinity,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 16 : 32,
          isCompact ? 16 : 24,
          isCompact ? 16 : 32,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(),
            const SizedBox(height: 32),
            _buildSectionCard(
              title: 'Profile Information',
              icon: Icons.person_outline,
              child: Form(
                key: _profileFormKey,
                child: Column(
                  children: [
                    isCompact
                        ? Column(
                            children: [
                              _buildTextField(
                                'First Name',
                                controller: _firstNameController,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                'Last Name',
                                controller: _lastNameController,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  'First Name',
                                  controller: _firstNameController,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildTextField(
                                  'Last Name',
                                  controller: _lastNameController,
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Email Address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Role', initialValue: role, enabled: false),
                    const SizedBox(height: 24),
                    _buildSolidButton(
                      _isSavingProfile ? 'Saving...' : 'Save Profile',
                      Icons.save_outlined,
                      _isSavingProfile ? null : _saveProfile,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Security',
              icon: Icons.lock_outline,
              child: Form(
                key: _passwordFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      'Current Password',
                      controller: _currentPasswordController,
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),
                    isCompact
                        ? Column(
                            children: [
                              _buildTextField(
                                'New Password',
                                controller: _newPasswordController,
                                isPassword: true,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                'Confirm New Password',
                                controller: _confirmPasswordController,
                                isPassword: true,
                                validator: (value) {
                                  if ((value ?? '').isEmpty) {
                                    return 'Required';
                                  }
                                  if (value != _newPasswordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  'New Password',
                                  controller: _newPasswordController,
                                  isPassword: true,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _buildTextField(
                                  'Confirm New Password',
                                  controller: _confirmPasswordController,
                                  isPassword: true,
                                  validator: (value) {
                                    if ((value ?? '').isEmpty) {
                                      return 'Required';
                                    }
                                    if (value != _newPasswordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 8),
                    const Text(
                      'Password must be at least 6 characters long.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    _buildSolidButton(
                      _isSavingPassword ? 'Updating...' : 'Update Password',
                      Icons.key_outlined,
                      _isSavingPassword ? null : _updatePassword,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionCard(
              title: 'Notification Preferences',
              icon: Icons.notifications_outlined,
              child: Column(
                children: [
                  _buildSwitchRow(
                    'Email Announcements',
                    'Receive system and alumni announcement updates by email.',
                    _emailAnnouncements,
                    (value) => setState(() => _emailAnnouncements = value),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow(
                    'Email Reminders',
                    'Receive reminders about pending reviews and follow-ups.',
                    _emailReminders,
                    (value) => setState(() => _emailReminders = value),
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchRow(
                    'Event Invitations',
                    'Receive invitation alerts for alumni and campus events.',
                    _eventInvitations,
                    (value) => setState(() => _eventInvitations = value),
                  ),
                  const SizedBox(height: 24),
                  _buildSolidButton(
                    _isSavingSettings ? 'Saving...' : 'Save Preferences',
                    Icons.notifications_active_outlined,
                    _isSavingSettings ? null : _saveNotificationSettings,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (isCompact)
              Column(
                children: [
                  _buildUserProvisioningCard(isCompact),
                  const SizedBox(height: 24),
                  _buildPrivilegedUserManagementCard(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildUserProvisioningCard(false)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildPrivilegedUserManagementCard()),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    final isCompact = MediaQuery.of(context).size.width < 760;
    return LuxuryModuleBanner(
      compact: isCompact,
      title: 'Settings',
      description:
          'Manage your administrator account, password, and notification preferences in a cleaner and more presentable settings layout.',
      icon: Icons.shield_outlined,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black87),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    TextEditingController? controller,
    String? initialValue,
    bool enabled = true,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final effectiveValidator =
        validator ??
        (enabled
            ? (String? value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Required';
                }
                return null;
              }
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          enabled: enabled,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: effectiveValidator,
          style: TextStyle(color: enabled ? Colors.black87 : Colors.grey),
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldFillColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (selected) {
            if ((selected ?? '').trim().isEmpty) {
              return 'Required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSwitchRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final isCompact = MediaQuery.of(context).size.width < 380;
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.black,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildSolidButton(
    String label,
    IconData icon,
    VoidCallback? onPressed,
  ) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: onPressed == null ? Colors.grey.shade500 : darkButtonColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProvisioningCard(bool isCompact) {
    return _buildSectionCard(
      title: 'User Provisioning',
      icon: Icons.admin_panel_settings_outlined,
      child: Form(
        key: _provisionFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create admin or dean accounts without affecting alumni registration. Dean accounts must be assigned to one program.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 20),
            isCompact
                ? Column(
                    children: [
                      _buildTextField(
                        'First Name',
                        controller: _newUserFirstNameController,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Last Name',
                        controller: _newUserLastNameController,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'First Name',
                          controller: _newUserFirstNameController,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTextField(
                          'Last Name',
                          controller: _newUserLastNameController,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 16),
            _buildTextField(
              'Email Address',
              controller: _newUserEmailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = (value ?? '').trim();
                if (email.isEmpty) return 'Required';
                final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!pattern.hasMatch(email)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Temporary Password',
              controller: _newUserPasswordController,
              isPassword: true,
              validator: (value) {
                if ((value ?? '').isEmpty) return 'Required';
                if ((value ?? '').length < 8) {
                  return 'Minimum 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            isCompact
                ? Column(
                    children: [
                      _buildDropdownField(
                        label: 'Role',
                        value: _provisionRole,
                        items: const ['dean', 'admin'],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _provisionRole = value);
                        },
                      ),
                      if (_provisionRole == 'dean') ...[
                        const SizedBox(height: 16),
                        _buildDropdownField(
                          label: 'Assigned Program',
                          value: _provisionProgram,
                          items: _programOptions,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _provisionProgram = value);
                          },
                        ),
                      ],
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Role',
                          value: _provisionRole,
                          items: const ['dean', 'admin'],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _provisionRole = value);
                          },
                        ),
                      ),
                      if (_provisionRole == 'dean') ...[
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildDropdownField(
                            label: 'Assigned Program',
                            value: _provisionProgram,
                            items: _programOptions,
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _provisionProgram = value);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
            const SizedBox(height: 24),
            _buildSolidButton(
              _isCreatingUser ? 'Creating...' : 'Create Account',
              Icons.person_add_alt_1_outlined,
              _isCreatingUser ? null : _createPrivilegedUser,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivilegedUserManagementCard() {
    return _buildSectionCard(
      title: 'Privileged Account Management',
      icon: Icons.history_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review the admin and dean history from this settings workspace. Delete is only available for accounts that were created by admin from this workspace.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _isLoadingPrivilegedUsers
                  ? null
                  : _fetchPrivilegedUsers,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ),
          if (_isLoadingPrivilegedUsers)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_privilegedUsers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: fieldFillColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('No admin or dean history found yet.'),
            )
          else
            Column(
              children: _privilegedUsers.map((event) {
                final metadata = event['metadata'] is Map
                    ? (event['metadata'] as Map).map(
                        (key, value) => MapEntry('$key', value),
                      )
                    : const <String, dynamic>{};
                final createdName =
                    (event['name'] ??
                            metadata['target_user_name'] ??
                            event['target_name'] ??
                            event['title'] ??
                            'Created account')
                        .toString();
                final role =
                    (event['role'] ??
                            metadata['created_role'] ??
                            event['target_type'] ??
                            '')
                        .toString()
                        .toUpperCase();
                final actorName =
                    (event['user_name'] ??
                            metadata['actor_name'] ??
                            _readValue(['name']) ??
                            'Administrator')
                        .toString();
                final email =
                    (event['email'] ??
                            metadata['email'] ??
                            event['user_email'] ??
                            '')
                        .toString();
                final program = (event['program'] ?? metadata['program'] ?? '')
                    .toString();
                final time =
                    (event['time'] ??
                            event['occurred_at'] ??
                            event['created_at'] ??
                            '')
                        .toString();
                final accountId =
                    int.tryParse((event['id'] ?? '').toString()) ?? 0;
                final isCurrentUser = accountId > 0 && accountId == _userId;
                final canDelete =
                    event['can_delete'] == true &&
                    accountId > 0 &&
                    !isCurrentUser;
                final isDeleting = _deletingPrivilegedUserIds.contains(
                  accountId,
                );
                final subtitle = [
                  if (email.trim().isNotEmpty) email,
                  'Created by: $actorName',
                  if (program.trim().isNotEmpty) 'Program: $program',
                  if (time.trim().isNotEmpty) time,
                ].where((value) => value.trim().isNotEmpty).join(' • ');

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: fieldFillColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              createdName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentGold.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              role.isEmpty ? 'USER' : role,
                              style: TextStyle(
                                color: accentGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => _showPrivilegedUserHistory(event),
                            icon: const Icon(Icons.history_rounded, size: 18),
                            label: const Text('View history'),
                            style: TextButton.styleFrom(
                              foregroundColor: darkButtonColor,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(width: 18),
                          if (isCurrentUser)
                            Text(
                              'Current account',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else if (!canDelete)
                            Text(
                              'History only',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            TextButton.icon(
                              onPressed: isDeleting
                                  ? null
                                  : () => _deletePrivilegedUser(event),
                              icon: isDeleting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline, size: 18),
                              label: Text(
                                isDeleting ? 'Deleting...' : 'Delete account',
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
