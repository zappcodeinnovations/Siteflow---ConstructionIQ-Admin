import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_date_picker_dialog.dart';
import 'timesheet_controller.dart';
import 'package:geolocator/geolocator.dart';

class AddAttendanceDialog extends StatefulWidget {
  final TimesheetController controller;

  const AddAttendanceDialog({super.key, required this.controller});

  @override
  State<AddAttendanceDialog> createState() => _AddAttendanceDialogState();
}

class _AddAttendanceDialogState extends State<AddAttendanceDialog> {
  String? _selectedOperatorId;
  String? _selectedProjectId;
  String? _selectedJobId;
  String? _selectedSiteContact;
  final List<String> _selectedTaskSheets = [];
  Map<String, dynamic> _siteContactsByProject = {};
  List<Map<String, dynamic>> _eligibleSiteContacts = [];
  bool _clockInOnly = false;
  double? _acquiredLat;
  double? _acquiredLon;
  bool _isAcquiringLocation = false;

  List<Map<String, dynamic>> _projectTasks = [];
  List<Map<String, dynamic>> _projectTaskSheets = [];
  bool _isLoadingTasks = false;

  // Flat job list from /timesheets/entry-options/ (each tagged with its
  // operator_id/project_id, a "JOB-no - reference" label and form names) -
  // the same data the web's Add Attendance modal cascades from.
  List<Map<String, dynamic>> _entryJobs = [];
  bool _entryJobsLoaded = false;

  DateTime? _clockIn;
  DateTime? _clockOut;

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();
  final TextEditingController _newTaskReferenceController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _clockIn = DateTime(now.year, now.month, now.day, 8, 0);
    _clockOut = now.hour >= 8
        ? DateTime(now.year, now.month, now.day, now.hour, now.minute)
        : DateTime(now.year, now.month, now.day, 16, 3);
    _loadEntryJobs();
  }

  Future<void> _loadEntryJobs() async {
    setState(() => _isLoadingTasks = true);
    try {
      final res = await ApiClient.get('${ApiEndpoints.baseUrl}/timesheets/entry-options/');
      final decoded = jsonDecode(res.body);
      if (res.statusCode == 200 && decoded is Map && decoded['status'] == true) {
        final jobs = (decoded['data']?['jobs'] as List? ?? const [])
            .whereType<Map>()
            .map((j) => j.cast<String, dynamic>())
            .toList();
        final rawContacts = (decoded['data']?['site_contacts'] as Map? ?? {});
        if (mounted) {
          setState(() {
            _entryJobs = jobs;
            _siteContactsByProject = rawContacts.cast<String, dynamic>();
            _entryJobsLoaded = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching attendance entry options: $e");
    } finally {
      if (mounted) setState(() => _isLoadingTasks = false);
    }
  }

  /// Projects the selected operative has tasks on (operative -> project
  /// cascade, as on the web). Falls back to every project only if the entry
  /// options could not be loaded at all.
  List<Map<String, dynamic>> _projectsForSelectedOperator(List allProjects) {
    if (_selectedOperatorId == null) return const [];
    if (!_entryJobsLoaded) {
      return allProjects.whereType<Map>().map((p) => p.cast<String, dynamic>()).toList();
    }
    final seen = <String>{};
    final projects = <Map<String, dynamic>>[];
    for (final job in _entryJobs) {
      if (job['operator_id']?.toString() != _selectedOperatorId) continue;
      final id = job['project_id']?.toString();
      if (id == null || !seen.add(id)) continue;
      projects.add({'id': id, 'name': (job['project_name'] ?? 'Project').toString()});
    }
    projects.sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
    return projects;
  }

  void _selectProject(String projectId) {
    final tasks = _entryJobs
        .where((job) =>
            job['operator_id']?.toString() == _selectedOperatorId &&
            job['project_id']?.toString() == projectId)
        .map((job) => <String, dynamic>{
              'id': job['id'].toString(),
              'name': (job['label'] ?? 'Task').toString(),
              'form_names': job['form_names'] ?? const [],
            })
        .toList();

    final contactsList = (_siteContactsByProject[projectId] as List? ?? [])
        .whereType<Map>()
        .map((c) => c.cast<String, dynamic>())
        .toList();

    setState(() {
      _selectedProjectId = projectId;
      _selectedJobId = null;
      _selectedTaskSheets.clear();
      _projectTasks = tasks;
      _projectTaskSheets = [];
      _eligibleSiteContacts = contactsList;
      _selectedSiteContact = contactsList.isNotEmpty ? contactsList.first['id']?.toString() : null;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isAcquiringLocation = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location services are disabled on your device.")),
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location permission is required to acquire current location.")),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() {
        _acquiredLat = pos.latitude;
        _acquiredLon = pos.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Location acquired: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error acquiring location: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isAcquiringLocation = false);
    }
  }

  void _selectJob(String? jobId) {
    final job = _projectTasks.firstWhere((t) => t['id'] == jobId, orElse: () => const {});
    // The backend submits the task's own sheets (job.selected_forms) - show
    // exactly those, pre-selected, instead of a generic/mock form list.
    final sheets = ((job['form_names'] as List?) ?? const [])
        .map((name) => <String, dynamic>{'id': name.toString(), 'name': name.toString()})
        .toList();
    setState(() {
      _selectedJobId = jobId;
      _projectTaskSheets = sheets;
      _selectedTaskSheets
        ..clear()
        ..addAll(sheets.map((s) => s['id'].toString()));
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _signatureController.dispose();
    _newTaskReferenceController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _fetchProjectTasksAndSheets(String projectId) async {
    setState(() {
      _isLoadingTasks = true;
      _selectedJobId = null;
      _selectedTaskSheets.clear();
      _projectTasks = [];
      _projectTaskSheets = [];
    });

    try {
      final res = await ApiClient.get(
        '${ApiEndpoints.baseUrl}${ApiEndpoints.projectAllInOneDetails(int.parse(projectId))}',
      );
      final decoded = jsonDecode(res.body);

      if (res.statusCode == 200 && decoded['status'] == true) {
        final data = decoded['data'] ?? {};
        final tasksList = (data['tasks'] as List? ?? []);
        final sheetsList = (data['job_sheets'] as List? ?? []);
        final formsList = (data['project_setup']?['forms'] as List? ?? []);

        final allSheets = <Map<String, dynamic>>[];
        for (final s in sheetsList) {
          if (s is Map) {
            allSheets.add({
              'id': (s['id'] ?? s['form_id'] ?? s['form_name']).toString(),
              'name': (s['form_name'] ?? s['name'] ?? s['title'] ?? 'Task Sheet')
                  .toString(),
            });
          }
        }
        for (final f in formsList) {
          if (f is Map) {
            final id = (f['id'] ?? f['form_id'] ?? f['name']).toString();
            if (!allSheets.any((e) => e['id'] == id)) {
              allSheets.add({
                'id': id,
                'name': (f['name'] ?? f['title'] ?? 'Form').toString(),
              });
            }
          }
        }
        if (mounted) {
          setState(() {
            _projectTasks = tasksList
                .map((t) => t is Map
                    ? t.cast<String, dynamic>()
                    : {'id': t.toString(), 'name': t.toString()})
                .toList();
            _projectTaskSheets = allSheets;
          });
        }
      } else {
        // Fallback to /admin/tasks/?project=$projectId
        final tRes = await ApiClient.get(
          '${ApiEndpoints.baseUrl}/admin/tasks/?project=$projectId',
        );
        final tDecoded = jsonDecode(tRes.body);
        if (tRes.statusCode == 200 && tDecoded['status'] == true) {
          final list = (tDecoded['data'] as List? ?? []);
          if (mounted) {
            setState(() {
              _projectTasks = list
                  .map((t) => t is Map
                      ? t.cast<String, dynamic>()
                      : {'id': t.toString(), 'name': t.toString()})
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching project tasks: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTasks = false;
        });
      }
    }
  }

  Future<void> _selectDateTime(bool isClockIn) async {
    final initialDate = isClockIn ? (_clockIn ?? DateTime.now()) : (_clockOut ?? DateTime.now());
    final pickedDate = await CustomDatePickerDialog.showCustomDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final initialTime = TimeOfDay(hour: initialDate.hour, minute: initialDate.minute);
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (pickedTime != null) {
        final dt = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          if (isClockIn) {
            _clockIn = dt;
          } else {
            _clockOut = dt;
          }
        });
      }
    }
  }

  void _openTaskSheetsPicker() {
    if (_selectedProjectId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkSurface
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Select Task Sheets",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          IconlyLight.close_square,
                          color: isDark ? Colors.white70 : Colors.grey,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Select one or more task sheets.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (_projectTaskSheets.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No task sheets available for this project."),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _projectTaskSheets.length,
                        itemBuilder: (context, index) {
                          final sheet = _projectTaskSheets[index];
                          final id = sheet['id'].toString();
                          final name = sheet['name'].toString();
                          final isSelected = _selectedTaskSheets.contains(id);
                          return CheckboxListTile(
                            title: Text(
                              name,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                            value: isSelected,
                            activeColor: const Color(0xFF0D6EFD),
                            onChanged: (bool? val) {
                              setModalState(() {
                                if (val == true) {
                                  _selectedTaskSheets.add(id);
                                } else {
                                  _selectedTaskSheets.remove(id);
                                }
                              });
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "Done",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _submit() async {
    if (_selectedOperatorId == null || _clockIn == null || (!_clockInOnly && _clockOut == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields.")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final payload = <String, dynamic>{
      "operator": int.parse(_selectedOperatorId!),
      "project": _selectedProjectId != null
          ? int.tryParse(_selectedProjectId!)
          : null,
      "job": _selectedJobId != null ? int.tryParse(_selectedJobId!) : null,
      if (_selectedTaskSheets.isNotEmpty) "task_sheets": _selectedTaskSheets,
      "clock_in": _clockIn!.toIso8601String().split('.').first,
      if (!_clockInOnly && _clockOut != null)
        "clock_out": _clockOut!.toIso8601String().split('.').first,
      if (_acquiredLat != null && _acquiredLon != null) ...{
        "location_latitude": _acquiredLat!.toStringAsFixed(7),
        "location_longitude": _acquiredLon!.toStringAsFixed(7),
      },
      if (_selectedSiteContact != null && _selectedSiteContact!.isNotEmpty)
        "site_contact": _selectedSiteContact,
      if (_newTaskReferenceController.text.trim().isNotEmpty)
        "new_task_reference": _newTaskReferenceController.text.trim(),
      if (_instructionsController.text.trim().isNotEmpty)
        "instructions": _instructionsController.text.trim(),
      "notes": _notesController.text,
      "signature_text": _signatureController.text,
    };

    final result = await widget.controller.addAttendance(payload);

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFieldLabel(
    String label, {
    bool isRequired = false,
    bool isDoubleRequired = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black87;

    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: labelColor,
        ),
        children: [
          if (isDoubleRequired)
            const TextSpan(
              text: ' **',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            )
          else if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.controller.data?.filterOptions ?? {};
    final operators = (options['operators'] as List?) ?? [];
    final projects = _projectsForSelectedOperator((options['projects'] as List?) ?? []);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final iconBgColor = isDark ? Colors.white24 : Colors.grey.shade100;
    final iconColor = isDark ? Colors.white : Colors.black54;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: screenHeight - keyboardHeight - 48,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 380 ? 16 : 24,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 460;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Add Attendance",
                          style: TextStyle(
                            fontSize: screenWidth < 360 ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              IconlyLight.close_square,
                              size: 18,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Operative & Project (Cascading)
                            if (isNarrow) ...[
                              _buildPremiumDropdown(
                                labelWidget: _buildFieldLabel("Operative", isDoubleRequired: true),
                                value: _selectedOperatorId,
                                hintText: "Select an Operative",
                                isEnabled: true,
                                items: operators.map((o) {
                                  return DropdownMenuItem(
                                    value: o['id'].toString(),
                                    child: Text(
                                      o['name'].toString(),
                                      maxLines: 2,
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedOperatorId = val;
                                    _selectedProjectId = null;
                                    _selectedJobId = null;
                                    _selectedTaskSheets.clear();
                                    _projectTasks = [];
                                    _projectTaskSheets = [];
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildPremiumDropdown(
                                labelWidget: _buildFieldLabel("Project"),
                                value: _selectedProjectId,
                                hintText: _selectedOperatorId == null
                                    ? "Select operative first"
                                    : projects.isEmpty
                                        ? "No assigned projects"
                                        : "Select option",
                                isEnabled: _selectedOperatorId != null && projects.isNotEmpty,
                                items: projects.map((p) {
                                  return DropdownMenuItem(
                                    value: p['id'].toString(),
                                    child: Text(
                                      p['name'].toString(),
                                      maxLines: 2,
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  if (_entryJobsLoaded) {
                                    _selectProject(val);
                                  } else {
                                    setState(() => _selectedProjectId = val);
                                    _fetchProjectTasksAndSheets(val);
                                  }
                                },
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPremiumDropdown(
                                      labelWidget: _buildFieldLabel("Operative", isDoubleRequired: true),
                                      value: _selectedOperatorId,
                                      hintText: "Select an Operative",
                                      isEnabled: true,
                                      items: operators.map((o) {
                                        return DropdownMenuItem(
                                          value: o['id'].toString(),
                                          child: Text(
                                            o['name'].toString(),
                                            maxLines: 2,
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedOperatorId = val;
                                          _selectedProjectId = null;
                                          _selectedJobId = null;
                                          _selectedTaskSheets.clear();
                                          _projectTasks = [];
                                          _projectTaskSheets = [];
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildPremiumDropdown(
                                      labelWidget: _buildFieldLabel("Project"),
                                      value: _selectedProjectId,
                                      hintText: _selectedOperatorId == null
                                          ? "Select operative first"
                                          : projects.isEmpty
                                              ? "No assigned projects"
                                              : "Select option",
                                      isEnabled: _selectedOperatorId != null && projects.isNotEmpty,
                                      items: projects.map((p) {
                                        return DropdownMenuItem(
                                          value: p['id'].toString(),
                                          child: Text(
                                            p['name'].toString(),
                                            maxLines: 2,
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val == null) return;
                                        if (_entryJobsLoaded) {
                                          _selectProject(val);
                                        } else {
                                          setState(() => _selectedProjectId = val);
                                          _fetchProjectTasksAndSheets(val);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),

                            // Existing Task Sheet (Job)
                    _buildPremiumDropdown(
                      labelWidget: _buildFieldLabel("Existing Task Sheet"),
                      value: _selectedJobId,
                      hintText: _selectedProjectId == null
                          ? "Select project first"
                          : _isLoadingTasks
                              ? "Loading tasks..."
                              : _projectTasks.isEmpty
                                  ? "No tasks found for project"
                                  : "Select option",
                      isEnabled: _selectedProjectId != null &&
                          !_isLoadingTasks &&
                          _projectTasks.isNotEmpty,
                      items: _projectTasks.map((t) {
                        final displayNo = (t['task_display_no'] ?? t['job_display_no'] ?? t['task_no'])?.toString();
                        final reference = t['reference']?.toString();
                        final taskName = (t['name'] ??
                                t['label'] ??
                                (displayNo != null
                                    ? [displayNo, if (reference != null && reference.isNotEmpty) reference].join(' - ')
                                    : null) ??
                                t['title'] ??
                                'Task')
                            .toString();
                        final taskNum = t['task_number'] != null
                            ? "${t['task_number']} - "
                            : "";
                        return DropdownMenuItem(
                          value: t['id'].toString(),
                          child: Text(
                            "$taskNum$taskName",
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _selectJob,
                    ),
                    const SizedBox(height: 16),

                    // Or Create Task Sheet
                    _buildPremiumTextField(
                      "Or Create Task Sheet",
                      _newTaskReferenceController,
                      hintText: "Task description / reference",
                    ),
                    const SizedBox(height: 16),

                    // Task Sheet Multi-Select
                    _buildTaskSheetsField(),
                    const SizedBox(height: 16),

                    // Site Contact Dropdown
                    if (_selectedProjectId != null && _eligibleSiteContacts.isNotEmpty) ...[
                      _buildPremiumDropdown(
                        labelWidget: _buildFieldLabel("Site Contact"),
                        value: _selectedSiteContact,
                        hintText: "Select Site Contact",
                        isEnabled: true,
                        items: _eligibleSiteContacts.map((c) {
                          final name = (c['name'] ?? 'Contact').toString();
                          final role = (c['role_label'] ?? '').toString();
                          final label = role.isNotEmpty ? "$name ($role)" : name;
                          return DropdownMenuItem(
                            value: c['id'].toString(),
                            child: Text(
                              label,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedSiteContact = val);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Reference Details
                    _buildPremiumTextField(
                      "Reference Details",
                      _instructionsController,
                      hintText: "Instructions / reference notes",
                    ),
                    const SizedBox(height: 16),

                    // Daily Diary Notice
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.blue.shade50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(IconlyLight.document, color: Color(0xFF0D6EFD), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Daily Diary",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Daily Diary will open for completion at Clock Out.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey.shade400 : Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Attendance Mode Toggle (Clock In Only vs Full Shift)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Clock In Only (Active Session)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  "Operative will remain clocked in until clocked out from timesheets.",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _clockInOnly,
                            activeColor: const Color(0xFF0D6EFD),
                            onChanged: (val) {
                              setState(() => _clockInOnly = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date & Time Fields
                    if (_clockInOnly) ...[
                      _buildDateTimeField(
                        labelWidget: _buildFieldLabel("Clocked in", isRequired: true),
                        value: _clockIn,
                        onTap: () => _selectDateTime(true),
                      ),
                    ] else if (isNarrow) ...[
                      _buildDateTimeField(
                        labelWidget: _buildFieldLabel("Clocked in", isRequired: true),
                        value: _clockIn,
                        onTap: () => _selectDateTime(true),
                      ),
                      const SizedBox(height: 16),
                      _buildDateTimeField(
                        labelWidget: _buildFieldLabel("Clocked out", isRequired: true),
                        value: _clockOut,
                        onTap: () => _selectDateTime(false),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateTimeField(
                              labelWidget: _buildFieldLabel("Clocked in", isRequired: true),
                              value: _clockIn,
                              onTap: () => _selectDateTime(true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateTimeField(
                              labelWidget: _buildFieldLabel("Clocked out", isRequired: true),
                              value: _clockOut,
                              onTap: () => _selectDateTime(false),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Location Action Button & Helper text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _acquiredLat != null ? Colors.green : (isDark ? Colors.white24 : Colors.grey.shade300),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onPressed: _isAcquiringLocation ? null : _getCurrentLocation,
                          icon: _isAcquiringLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  IconlyLight.location,
                                  size: 16,
                                  color: _acquiredLat != null ? Colors.green : (isDark ? Colors.white : Colors.black87),
                                ),
                          label: Text(
                            _acquiredLat != null
                                ? "Location: ${_acquiredLat!.toStringAsFixed(4)}, ${_acquiredLon!.toStringAsFixed(4)}"
                                : "Use Current Location",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _acquiredLat != null ? Colors.green : (isDark ? Colors.white : Colors.black87),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Project location will be used if current location is not added.",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes & Signature Text
                    _buildPremiumTextField("Notes", _notesController, maxLines: 3),
                    const SizedBox(height: 16),
                    _buildPremiumTextField("Signature Text", _signatureController),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: isNarrow ? 1 : 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF0D6EFD),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Add Entry",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  ),
),
),
);
}

  Widget _buildTaskSheetsField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBgColor = isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white70 : Colors.grey;
    final isEnabled = _selectedProjectId != null;

    String displayText = "Select project first";
    if (isEnabled) {
      if (_selectedTaskSheets.isEmpty) {
        displayText = "Select task sheets";
      } else {
        final names = _selectedTaskSheets.map((id) {
          final found = _projectTaskSheets.firstWhere(
            (s) => s['id'] == id,
            orElse: () => {'name': id},
          );
          return found['name']?.toString() ?? id;
        }).toList();
        displayText = names.join(', ');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel("Task Sheet"),
        const SizedBox(height: 8),
        InkWell(
          onTap: isEnabled ? _openTaskSheetsPicker : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isEnabled
                  ? boxBgColor
                  : (isDark ? Colors.white10 : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14,
                      color: isEnabled
                          ? (_selectedTaskSheets.isNotEmpty
                              ? textColor
                              : (isDark ? Colors.grey.shade400 : Colors.black54))
                          : (isDark ? Colors.white38 : Colors.grey),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  IconlyLight.arrow_down_2,
                  size: 16,
                  color: isEnabled ? iconColor : Colors.grey,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Select one or more task sheets.",
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumDropdown({
    required Widget labelWidget,
    required String? value,
    required String hintText,
    required bool isEnabled,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBgColor = isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dropdownColor = isDark ? const Color(0xFF1F2E40) : Colors.white;
    final iconColor = isDark ? Colors.white70 : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelWidget,
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isEnabled
                ? boxBgColor
                : (isDark ? Colors.white10 : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: isEnabled ? value : null,
              hint: Text(
                hintText,
                style: TextStyle(
                  color: isEnabled
                      ? (isDark ? Colors.grey.shade400 : Colors.black54)
                      : (isDark ? Colors.white38 : Colors.grey),
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              icon: Icon(
                IconlyLight.arrow_down_2,
                color: isEnabled ? iconColor : Colors.grey,
              ),
              dropdownColor: dropdownColor,
              style: TextStyle(color: textColor, fontSize: 14),
              items: isEnabled ? items : [],
              onChanged: isEnabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField({
    required Widget labelWidget,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBgColor = isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white70 : Colors.grey;
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelWidget,
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: boxBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value != null ? _formatDateTime(value) : 'dd-mm-yyyy hh:mm',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: value != null ? textColor : hintColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(IconlyLight.calendar, size: 16, color: iconColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hintText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBgColor = isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black87;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white38 : Colors.grey.shade500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: hintColor, fontSize: 13),
            filled: true,
            fillColor: boxBgColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0D6EFD)),
            ),
          ),
        ),
      ],
    );
  }
}
