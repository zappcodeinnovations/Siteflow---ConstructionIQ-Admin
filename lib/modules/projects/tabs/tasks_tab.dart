import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class TasksTab extends StatefulWidget {
  final List<dynamic> tasks;
  final VoidCallback? onChanged;

  const TasksTab({super.key, required this.tasks, this.onChanged});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  String _selectedStatus = 'Status: All';

  static const List<String> _statusOptions = [
    'Status: All',
    'Awaiting',
    'In Progress',
    'Completed',
  ];

  List<String> get _statusDropdownOptions => _statusOptions;

  String _formatTaskDate(dynamic raw) {
    if (raw == null) return "N/A";
    final str = raw.toString().trim();
    if (str.isEmpty || str == 'null' || str == '-') return "N/A";

    final dMonYPattern = RegExp(r'^\d{1,2}\s+[A-Za-z]{3}\s+\d{4}$');
    if (dMonYPattern.hasMatch(str)) {
      return str;
    }

    try {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) {
        return DateFormat('dd MMM yyyy').format(parsed.toLocal());
      }
    } catch (_) {}

    final formats = [
      'yyyy-MM-dd',
      'yyyy-MM-dd HH:mm:ss',
      'yyyy-MM-ddTHH:mm:ssZ',
      'yyyy-MM-ddTHH:mm:ss.SSSZ',
      'dd/MM/yyyy',
      'dd-MM-yyyy',
      'dd/MM/yyyy HH:mm:ss',
      'dd-MM-yyyy HH:mm:ss',
      'MM/dd/yyyy',
      'MMM dd, yyyy',
      'dd MMM yyyy',
    ];

    for (final fmt in formats) {
      try {
        final d = DateFormat(fmt, 'en_US').parseLoose(str);
        return DateFormat('dd MMM yyyy').format(d);
      } catch (_) {}
    }

    return str;
  }

  String _getTaskDate(dynamic task) {
    if (task is Map) {
      final raw = task['date'] ??
          task['task_date'] ??
          task['scheduled_date'] ??
          task['submission_date'] ??
          task['assigned_date'] ??
          task['created_at'] ??
          task['created'] ??
          task['created_date'] ??
          task['timestamp'];
      return _formatTaskDate(raw);
    }
    return "N/A";
  }

  String _normalizeStatus(dynamic task) {
    if (task is Map) {
      final raw = (task['status'] ?? task['status_label'] ?? task['state'] ?? task['status_display'] ?? '')
          .toString()
          .trim()
          .toLowerCase()
          .replaceAll('-', '_')
          .replaceAll(' ', '_');

      if (raw == 'in_progress' || raw == 'open' || raw == 'active') {
        return 'in_progress';
      }
      if (raw == 'awaiting' || raw == 'pending') {
        return 'awaiting';
      }
      if (raw == 'completed' || raw == 'closed' || raw == 'done' || raw == 'finished' || raw == 'approved' ||
          task['is_closed'] == true || task['is_completed'] == true) {
        return 'completed';
      }
      return raw;
    }
    return '';
  }

  List<dynamic> get _filteredTasks {
    if (_selectedStatus == 'Status: All') {
      return widget.tasks;
    }
    if (_selectedStatus == 'Awaiting') {
      return widget.tasks.where((t) => _normalizeStatus(t) == 'awaiting').toList();
    }
    if (_selectedStatus == 'In Progress') {
      return widget.tasks.where((t) => _normalizeStatus(t) == 'in_progress').toList();
    }
    if (_selectedStatus == 'Completed') {
      return widget.tasks.where((t) => _normalizeStatus(t) == 'completed').toList();
    }
    return widget.tasks;
  }

  void _openFiltersBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Filter Tasks",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = 'Status: All';
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text("Reset All"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Status",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statusDropdownOptions.map((opt) {
                  final isSelected = _selectedStatus == opt;
                  return ChoiceChip(
                    label: Text(opt.startsWith('Status: ') ? opt.replaceFirst('Status: ', '') : opt),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0D6EFD),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStatus = opt;
                        });
                        Navigator.pop(ctx);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = _statusDropdownOptions;
    if (!options.contains(_selectedStatus)) {
      _selectedStatus = 'Status: All';
    }
    final displayedTasks = _filteredTasks;

    return Column(
      children: [
        // Filter Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 12,
                  children: [
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                          value: _selectedStatus,
                          items: options
                              .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black87))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedStatus = val;
                              });
                            }
                          },
                          icon: Icon(IconlyLight.arrow_down_2,
                              color: isDark ? Colors.white70 : Colors.black54, size: 18),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white10 : Colors.white,
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          elevation: 0,
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: _openFiltersBottomSheet,
                        icon: Icon(IconlyLight.filter, size: 16, color: isDark ? Colors.white : Colors.black87),
                        label: const Text("Filters",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                Text("Total: ${displayedTasks.length}",
                    style: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),

        // Tasks List
        Expanded(
          child: displayedTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.document,
                          size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("No tasks found",
                          style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  itemCount: displayedTasks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final task = displayedTasks[index];
                    return _buildTaskCard(
                      context,
                      task: task,
                      taskNo: task['task_no']?.toString() ?? "N/A",
                      reference: task['reference']?.toString() ?? "N/A",
                      status: task['status']?.toString() ?? "N/A",
                      operativeName:
                          task['operative_name']?.toString() ?? "N/A",
                      form: task['form']?.toString() ?? "N/A",
                      sheets: task['sheets']?.toString() ?? "N/A",
                      date: _getTaskDate(task),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(
    BuildContext context, {
    required dynamic task,
    required String taskNo,
    required String reference,
    required String status,
    required String operativeName,
    required String form,
    required String sheets,
    required String date,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final normStatus = status.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    final isCompleted = normStatus == 'completed' || normStatus == 'closed' || normStatus == 'done';
    final isAwaiting = normStatus == 'awaiting' || normStatus == 'pending';
    
    Color statusColor = const Color(0xFF0D6EFD);
    Color statusBgColor = isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50;
    String displayStatus = status.replaceAll('_', ' ').replaceAll('-', ' ').toUpperCase();

    if (isCompleted) {
      statusColor = Colors.green;
      statusBgColor = isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green.shade50;
      displayStatus = 'COMPLETED';
    } else if (isAwaiting) {
      statusColor = Colors.orange.shade700;
      statusBgColor = isDark ? Colors.orange.withValues(alpha: 0.2) : Colors.orange.shade50;
      displayStatus = 'AWAITING';
    } else if (normStatus == 'in_progress' || normStatus == 'open') {
      statusColor = const Color(0xFF0D6EFD);
      statusBgColor = isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50;
      displayStatus = 'IN PROGRESS';
    }

    return Container(
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(IconlyLight.document,
                        color: isDark ? Colors.white : const Color(0xFF0D6EFD), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Task #$taskNo",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor)),
                      const SizedBox(height: 2),
                      Text(reference,
                          style: TextStyle(
                              color: textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayStatus,
                      style: TextStyle(
                        color: isDark ? Colors.white : statusColor.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),

          // Body Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _buildInfoColumn(
                    context, "OPERATIVE", operativeName, IconlyLight.profile),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: _buildInfoColumn(context, "FORM", form, IconlyLight.paper),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildInfoColumn(context, "SHEETS", sheets, IconlyLight.paper),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Date Row
          Row(
            children: [
              Icon(IconlyLight.calendar, size: 14, color: textSecondary),
              const SizedBox(width: 6),
              Text(
                "Date: ",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Footer Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _confirmAndDeleteTask(context, task),
                icon: const Icon(IconlyLight.delete,
                    size: 16, color: Colors.red),
                label: const Text("Delete",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white10 : Colors.white,
                  foregroundColor: isDark ? Colors.white : const Color(0xFF0D6EFD),
                  side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFF0D6EFD)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onPressed: () => _showTaskDetails(context, task),
                child: const Text("View Details",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteTask(BuildContext context, dynamic task) async {
    final taskId = task is Map ? task['id'] : null;
    if (taskId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to delete this task? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final response = await ApiClient.delete(
        ApiEndpoints.baseUrl + ApiEndpoints.adminTaskDelete(taskId is int ? taskId : int.parse(taskId.toString())),
      );
      if (!context.mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task deleted"), backgroundColor: Colors.green),
        );
        widget.onChanged?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete task (${response.statusCode})"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete task: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _showTaskDetails(BuildContext context, dynamic task) {
    final map = task is Map ? task : <String, dynamic>{};
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Task #${map['task_no'] ?? 'N/A'}"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow("Date", _getTaskDate(map)),
              _detailRow("Reference", map['reference']?.toString()),
              _detailRow("Status", map['status']?.toString()),
              _detailRow("Operative", map['operative_name']?.toString()),
              _detailRow("Form", map['form']?.toString()),
              _detailRow("Sheets", map['sheets']?.toString()),
              _detailRow("Site Contact", map['site_contact']?.toString()),
              _detailRow("Instructions", map['instructions']?.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    if (value == null || value.isEmpty || value == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: textSecondary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textSecondary,
                    letterSpacing: 0.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
              height: 1.25),
          softWrap: true,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
