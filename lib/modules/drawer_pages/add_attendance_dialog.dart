import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_date_picker_dialog.dart';
import 'timesheet_controller.dart';

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
  final List<String> _selectedTaskSheets = [];

  List<Map<String, dynamic>> _projectTasks = [];
  List<Map<String, dynamic>> _projectTaskSheets = [];
  bool _isLoadingTasks = false;

  DateTime? _clockIn;
  DateTime? _clockOut;

  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _clockIn = DateTime(now.year, now.month, now.day, 8, 0);
    _clockOut = now.hour >= 8
        ? DateTime(now.year, now.month, now.day, now.hour, now.minute)
        : DateTime(now.year, now.month, now.day, 16, 3);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _signatureController.dispose();
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
        if (allSheets.isEmpty) {
          allSheets.addAll([
            {'id': 'drilling', 'name': 'Drilling Form'},
            {'id': 'daily_diary', 'name': 'Daily Diary'},
            {'id': 'fire_stopping', 'name': 'Fire Stopping Form'},
            {'id': 'general_works', 'name': 'General Works Form'},
          ]);
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
    if (_selectedOperatorId == null || _clockIn == null || _clockOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields.")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final payload = {
      "operator": int.parse(_selectedOperatorId!),
      "project": _selectedProjectId != null
          ? int.tryParse(_selectedProjectId!)
          : null,
      "job": _selectedJobId != null ? int.tryParse(_selectedJobId!) : null,
      if (_selectedTaskSheets.isNotEmpty) "task_sheets": _selectedTaskSheets,
      "clock_in": _clockIn!.toIso8601String().split('.').first,
      "clock_out": _clockOut!.toIso8601String().split('.').first,
      "location_latitude": "51.5074", // Default Dublin/London
      "location_longitude": "-0.1278",
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
    final projects = (options['projects'] as List?) ?? [];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final iconBgColor = isDark ? Colors.white24 : Colors.grey.shade100;
    final iconColor = isDark ? Colors.white : Colors.black54;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Add Attendance",
                  style: TextStyle(
                    fontSize: 20,
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
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Operative & Project (Cascading)
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
                                : "Select option",
                            isEnabled: _selectedOperatorId != null,
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
                              setState(() {
                                _selectedProjectId = val;
                              });
                              if (val != null) {
                                _fetchProjectTasksAndSheets(val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Task Name (Job)
                    _buildPremiumDropdown(
                      labelWidget: _buildFieldLabel("Task Name (Job)", isRequired: true),
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
                        final taskName = (t['name'] ??
                                t['title'] ??
                                t['task_name'] ??
                                t['job_name'] ??
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
                      onChanged: (val) => setState(() => _selectedJobId = val),
                    ),
                    const SizedBox(height: 16),

                    // Task Sheet Multi-Select
                    _buildTaskSheetsField(),
                    const SizedBox(height: 16),

                    // Date & Time Fields
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
                    const SizedBox(height: 16),

                    // Location Action Button & Helper text
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Current location acquired successfully."),
                              ),
                            );
                          },
                          icon: Icon(
                            IconlyLight.location,
                            size: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          label: Text(
                            "Use Current Location",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
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
            Row(
              children: [
                Expanded(
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
                  flex: 2,
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
          ],
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
                Text(
                  value != null ? _formatDateTime(value) : 'dd-mm-yyyy hh:mm',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: value != null ? textColor : hintColor,
                  ),
                ),
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
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBgColor = isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black87;
    final textColor = isDark ? Colors.white : Colors.black87;

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
