import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/services/auth_service.dart';
import '../../models/job_sheet_model.dart';
import '../drawer_pages/job_sheet_controller.dart';
import '../drawer_pages/job_sheet_details_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final JobSheetController _controller = JobSheetController();
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearchVisible = true;
  String _selectedStatus = "Status: All";
  String _selectedProject = "All Projects";
  String _selectedClient = "All Clients";
  String _selectedOperative = "All Operatives";
  String _selectedForm = "All Forms";

  bool _canCreate = true;
  bool _canEdit = true;
  bool _canDelete = true;

  final List<String> _statusOptions = [
    'Status: All',
    'Completed',
    'Awaiting',
    'In Progress',
    'Pending',
    'Draft',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    _controller.fetchJobSheets();
    _loadPermissions();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _verticalScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPermissions() async {
    try {
      final access = await Future.wait([
        AuthService.can('tasks', action: 'create'),
        AuthService.can('tasks', action: 'edit'),
        AuthService.can('tasks', action: 'delete'),
      ]);
      if (!mounted) return;
      setState(() {
        _canCreate = access[0];
        _canEdit = access[1];
        _canDelete = access[2];
      });
    } catch (_) {}
  }

  List<String> get _projectOptions {
    final projects = <String>{'All Projects'};
    if (_controller.filterOptions['projects'] is List) {
      for (final p in _controller.filterOptions['projects']) {
        if (p != null && p.toString().trim().isNotEmpty) {
          projects.add(p.toString().trim());
        }
      }
    }
    for (final task in _controller.jobSheets) {
      if (task.projectName.trim().isNotEmpty) {
        projects.add(task.projectName.trim());
      }
    }
    return projects.toList();
  }

  List<String> get _clientOptions {
    final clients = <String>{'All Clients'};
    if (_controller.filterOptions['clients'] is List) {
      for (final c in _controller.filterOptions['clients']) {
        if (c != null && c.toString().trim().isNotEmpty) {
          clients.add(c.toString().trim());
        }
      }
    }
    for (final task in _controller.jobSheets) {
      if (task.clientName.trim().isNotEmpty) {
        clients.add(task.clientName.trim());
      }
    }
    return clients.toList();
  }

  List<String> get _operativeOptions {
    final operatives = <String>{'All Operatives'};
    if (_controller.filterOptions['operatives'] is List) {
      for (final o in _controller.filterOptions['operatives']) {
        if (o != null && o.toString().trim().isNotEmpty) {
          operatives.add(o.toString().trim());
        }
      }
    }
    for (final task in _controller.jobSheets) {
      if (task.operative.trim().isNotEmpty) {
        operatives.add(task.operative.trim());
      }
    }
    return operatives.toList();
  }

  List<String> get _formOptions {
    final forms = <String>{'All Forms'};
    if (_controller.filterOptions['forms'] is List) {
      for (final f in _controller.filterOptions['forms']) {
        if (f != null && f.toString().trim().isNotEmpty) {
          forms.add(f.toString().trim());
        }
      }
    }
    for (final task in _controller.jobSheets) {
      if (task.form.trim().isNotEmpty) {
        forms.add(task.form.trim());
      }
    }
    return forms.toList();
  }

  List<JobSheet> get _filteredTasks {
    final query = _searchController.text.trim().toLowerCase();

    return _controller.jobSheets.where((task) {
      // 1. Status Filter
      if (_selectedStatus != 'Status: All') {
        final targetStatus = _selectedStatus.replaceAll('Status: ', '').toLowerCase().replaceAll(' ', '_');
        final taskStatus = task.status.toLowerCase().replaceAll(' ', '_');
        final taskStatusLabel = task.statusLabel.toLowerCase().replaceAll(' ', '_');

        final matchesStatus = taskStatus == targetStatus ||
            taskStatusLabel == targetStatus ||
            (targetStatus == 'awaiting' && (taskStatus.contains('await') || taskStatusLabel.contains('await'))) ||
            (targetStatus == 'in_progress' && (taskStatus.contains('progress') || taskStatusLabel.contains('progress'))) ||
            (targetStatus == 'completed' && (taskStatus.contains('complete') || taskStatusLabel.contains('complete'))) ||
            (targetStatus == 'pending' && (taskStatus.contains('pend') || taskStatusLabel.contains('pend')));

        if (!matchesStatus) return false;
      }

      // 2. Project Filter
      if (_selectedProject != 'All Projects') {
        if (task.projectName.trim().toLowerCase() != _selectedProject.trim().toLowerCase()) {
          return false;
        }
      }

      // 3. Client Filter
      if (_selectedClient != 'All Clients') {
        if (task.clientName.trim().toLowerCase() != _selectedClient.trim().toLowerCase()) {
          return false;
        }
      }

      // 4. Operative Filter
      if (_selectedOperative != 'All Operatives') {
        if (task.operative.trim().toLowerCase() != _selectedOperative.trim().toLowerCase()) {
          return false;
        }
      }

      // 5. Form Filter
      if (_selectedForm != 'All Forms') {
        if (task.form.trim().toLowerCase() != _selectedForm.trim().toLowerCase()) {
          return false;
        }
      }

      // 6. Search Query Filter
      if (query.isNotEmpty) {
        final taskNo = (task.jobNo.isNotEmpty ? task.jobNo : task.sheetNo).toLowerCase();
        final sheetNo = task.sheetNo.toLowerCase();
        final project = task.projectName.toLowerCase();
        final client = task.clientName.toLowerCase();
        final operative = task.operative.toLowerCase();
        final form = task.form.toLowerCase();

        final matches = taskNo.contains(query) ||
            sheetNo.contains(query) ||
            project.contains(query) ||
            client.contains(query) ||
            operative.contains(query) ||
            form.contains(query);

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = 'Status: All';
      _selectedProject = 'All Projects';
      _selectedClient = 'All Clients';
      _selectedOperative = 'All Operatives';
      _selectedForm = 'All Forms';
    });
    _controller.clearFilters();
  }

  void _showFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF162A42) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final inputBg = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50;

    String tempStatus = _selectedStatus;
    String tempProject = _selectedProject;
    String tempClient = _selectedClient;
    String tempOperative = _selectedOperative;
    String tempForm = _selectedForm;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: isDark ? const BorderSide(color: Colors.white24) : BorderSide.none,
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return SafeArea(
                  child: Column(
                    children: [
                      // Header & drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 6),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textSecondary.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(IconlyLight.filter, color: Color(0xFF0D6EFD), size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  "Filter Tasks",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setSheetState(() {
                                      tempStatus = 'Status: All';
                                      tempProject = 'All Projects';
                                      tempClient = 'All Clients';
                                      tempOperative = 'All Operatives';
                                      tempForm = 'All Forms';
                                    });
                                  },
                                  child: const Text("Reset All", style: TextStyle(color: Color(0xFF0D6EFD), fontWeight: FontWeight.w600)),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: textSecondary, size: 22),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Scrollable Filter Form Controls
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          children: [
                            // 1. Status Selection Chips
                            Text(
                              "STATUS",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _statusOptions.map((status) {
                                final isSelected = tempStatus == status;
                                final label = status.replaceAll('Status: ', '');
                                return ChoiceChip(
                                  label: Text(label),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF0D6EFD),
                                  backgroundColor: inputBg,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : textColor,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF0D6EFD) : borderColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setSheetState(() => tempStatus = status);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),

                            // 2. Project Dropdown
                            Text(
                              "PROJECT",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: inputBg,
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _projectOptions.contains(tempProject) ? tempProject : 'All Projects',
                                  isExpanded: true,
                                  dropdownColor: bgColor,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  icon: Icon(IconlyLight.arrow_down_2, size: 16, color: textSecondary),
                                  items: _projectOptions
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e, overflow: TextOverflow.ellipsis),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() => tempProject = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 3. Client Dropdown
                            Text(
                              "CLIENT",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: inputBg,
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _clientOptions.contains(tempClient) ? tempClient : 'All Clients',
                                  isExpanded: true,
                                  dropdownColor: bgColor,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  icon: Icon(IconlyLight.arrow_down_2, size: 16, color: textSecondary),
                                  items: _clientOptions
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e, overflow: TextOverflow.ellipsis),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() => tempClient = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 4. Operative Dropdown
                            Text(
                              "OPERATIVE",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: inputBg,
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _operativeOptions.contains(tempOperative) ? tempOperative : 'All Operatives',
                                  isExpanded: true,
                                  dropdownColor: bgColor,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  icon: Icon(IconlyLight.arrow_down_2, size: 16, color: textSecondary),
                                  items: _operativeOptions
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e, overflow: TextOverflow.ellipsis),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() => tempOperative = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 5. Form Type Dropdown
                            Text(
                              "FORM TYPE",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: inputBg,
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _formOptions.contains(tempForm) ? tempForm : 'All Forms',
                                  isExpanded: true,
                                  dropdownColor: bgColor,
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  icon: Icon(IconlyLight.arrow_down_2, size: 16, color: textSecondary),
                                  items: _formOptions
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e, overflow: TextOverflow.ellipsis),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() => tempForm = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Action Buttons filling container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border(top: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  _resetFilters();
                                  Navigator.pop(context);
                                },
                                child: Text("Clear All", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D6EFD),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedStatus = tempStatus;
                                    _selectedProject = tempProject;
                                    _selectedClient = tempClient;
                                    _selectedOperative = tempOperative;
                                    _selectedForm = tempForm;
                                  });
                                  Navigator.pop(context);
                                },
                                child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showTaskDetailsBottomSheet(JobSheet task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF162A42) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final sectionBg = isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC);

    final taskNo = task.jobNo.isNotEmpty ? task.jobNo : task.sheetNo;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: isDark ? const BorderSide(color: Colors.white24) : BorderSide.none,
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: textSecondary.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFE8F2FF),
                          child: const Icon(IconlyLight.document, color: Color(0xFF0D6EFD), size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            taskNo,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(task.status, task.statusLabel),
                ],
              ),
              const SizedBox(height: 16),

              // Section: Project & Client
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sectionBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _bottomSheetRow(
                      icon: IconlyLight.folder,
                      label: "Project",
                      value: task.projectName.isNotEmpty ? task.projectName : "General Project",
                      textColor: textColor,
                      secondaryColor: textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _bottomSheetRow(
                      icon: IconlyLight.work,
                      label: "Client",
                      value: task.clientName.isNotEmpty ? task.clientName : "Euroside",
                      textColor: textColor,
                      secondaryColor: textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Section: Operative & Form
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sectionBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _bottomSheetRow(
                      icon: IconlyLight.profile,
                      label: "Operative",
                      value: task.operative.isNotEmpty ? task.operative : "-",
                      textColor: textColor,
                      secondaryColor: textSecondary,
                    ),
                    const SizedBox(height: 10),
                    _bottomSheetRow(
                      icon: IconlyLight.paper,
                      label: "Form Type",
                      value: task.form.isNotEmpty ? task.form : "-",
                      textColor: textColor,
                      secondaryColor: textSecondary,
                      valueColor: const Color(0xFF0D6EFD),
                    ),
                    if (task.created.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _bottomSheetRow(
                        icon: IconlyLight.time_circle,
                        label: "Created",
                        value: task.created,
                        textColor: textColor,
                        secondaryColor: textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text("Close", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _viewDetails(task);
                      },
                      icon: const Icon(IconlyLight.show, size: 16, color: Colors.white),
                      label: const Text("Full Details & Form", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomSheetRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color secondaryColor,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: secondaryColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: TextStyle(color: secondaryColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateTaskDialog() {
    final taskNoController = TextEditingController(
      text: "JOB ${_controller.jobSheets.length + 100}",
    );
    final projectController = TextEditingController();
    final clientController = TextEditingController();
    final operativeController = TextEditingController();
    final formController = TextEditingController();
    String selectedStatus = "Pending";

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppTheme.corporateBlue : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isDark ? const BorderSide(color: Colors.white24) : BorderSide.none,
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Create Task",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Task / Job Number",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: taskNoController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "e.g. JOB 14242326",
                          hintStyle: TextStyle(color: textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Project Name",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: projectController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "e.g. Second testing project (Euro009)",
                          hintStyle: TextStyle(color: textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Client Name",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: clientController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "e.g. Zaapkode Solutions",
                          hintStyle: TextStyle(color: textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Operative",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: operativeController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "e.g. Haemanpreet Tester",
                          hintStyle: TextStyle(color: textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Form Type",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: formController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "e.g. Diamond Drilling / Daywork",
                          hintStyle: TextStyle(color: textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Status",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStatus,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF162A42) : Colors.white,
                            style: TextStyle(color: textColor, fontSize: 14),
                            items: ['Pending', 'In Progress', 'Completed', 'Awaiting', 'Draft']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedStatus = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final taskNo = taskNoController.text.trim().isNotEmpty
                        ? taskNoController.text.trim()
                        : "JOB ${_controller.jobSheets.length + 100}";
                    final project = projectController.text.trim().isNotEmpty
                        ? projectController.text.trim()
                        : "General Project";
                    final client = clientController.text.trim().isNotEmpty
                        ? clientController.text.trim()
                        : "Euroside";
                    final operative = operativeController.text.trim();
                    final form = formController.text.trim();

                    final newJobSheet = JobSheet(
                      id: DateTime.now().millisecondsSinceEpoch,
                      sheetNo: taskNo,
                      status: selectedStatus.toLowerCase(),
                      statusLabel: selectedStatus,
                      jobNo: taskNo,
                      jobReference: taskNo,
                      projectName: project,
                      clientName: client,
                      operative: operative,
                      operativeCode: '',
                      form: form,
                      location: '',
                      comments: '',
                      materialCost: '',
                      charge: '',
                      globalDetailApiUrl: '',
                      created: DateTime.now().toString().split(' ')[0],
                      submitted: '',
                      lastUpdated: '',
                      formHtmlUrl: '',
                      viewFormInBrowserUrl: '',
                    );

                    setState(() {
                      _controller.jobSheets.insert(0, newJobSheet);
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Task $taskNo created successfully!")),
                    );
                  },
                  child: const Text("Create Task", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTaskDialog(JobSheet task) {
    final taskNoController = TextEditingController(text: task.jobNo.isNotEmpty ? task.jobNo : task.sheetNo);
    final projectController = TextEditingController(text: task.projectName);
    final clientController = TextEditingController(text: task.clientName);
    String selectedStatus = task.statusLabel.isNotEmpty ? task.statusLabel : "Pending";

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppTheme.corporateBlue : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isDark ? const BorderSide(color: Colors.white24) : BorderSide.none,
              ),
              title: Text(
                "Edit Task",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Task / Job Number",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: taskNoController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Project Name",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: projectController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Client Name",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: clientController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Status",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: ['Pending', 'In Progress', 'Completed', 'Awaiting', 'Draft'].contains(selectedStatus)
                                ? selectedStatus
                                : 'Pending',
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF162A42) : Colors.white,
                            style: TextStyle(color: textColor, fontSize: 14),
                            items: ['Pending', 'In Progress', 'Completed', 'Awaiting', 'Draft']
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => selectedStatus = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final index = _controller.jobSheets.indexOf(task);
                    if (index != -1) {
                      final updated = JobSheet(
                        id: task.id,
                        sheetNo: taskNoController.text.trim().isNotEmpty ? taskNoController.text.trim() : task.sheetNo,
                        status: selectedStatus.toLowerCase(),
                        statusLabel: selectedStatus,
                        jobNo: taskNoController.text.trim().isNotEmpty ? taskNoController.text.trim() : task.jobNo,
                        jobReference: task.jobReference,
                        projectName: projectController.text.trim().isNotEmpty ? projectController.text.trim() : task.projectName,
                        clientName: clientController.text.trim().isNotEmpty ? clientController.text.trim() : task.clientName,
                        operative: task.operative,
                        operativeCode: task.operativeCode,
                        form: task.form,
                        location: task.location,
                        comments: task.comments,
                        materialCost: task.materialCost,
                        charge: task.charge,
                        globalDetailApiUrl: task.globalDetailApiUrl,
                        created: task.created,
                        submitted: task.submitted,
                        lastUpdated: task.lastUpdated,
                        formHtmlUrl: task.formHtmlUrl,
                        viewFormInBrowserUrl: task.viewFormInBrowserUrl,
                      );
                      setState(() {
                        _controller.jobSheets[index] = updated;
                      });
                    }
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Task updated successfully!")),
                    );
                  },
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTask(JobSheet task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppTheme.corporateBlue : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final taskNo = task.jobNo.isNotEmpty ? task.jobNo : task.sheetNo;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isDark ? const BorderSide(color: Colors.white24) : BorderSide.none,
          ),
          title: Text("Delete Task", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
          content: Text(
            "Are you sure you want to delete $taskNo?",
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                setState(() {
                  _controller.jobSheets.remove(task);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Task deleted successfully")),
                );
              },
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _viewDetails(JobSheet task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobSheetDetailsScreen(jobSheet: task),
      ),
    );
  }

  Widget _buildStatusBadge(String status, String statusLabel) {
    final label = statusLabel.isNotEmpty ? statusLabel : status;
    final lower = label.toLowerCase();

    Color bgColor = const Color(0xFFF1F5F9);
    Color textColor = const Color(0xFF475569);
    Color dotColor = const Color(0xFF64748B);
    IconData icon = Icons.circle;

    if (lower.contains('complete') || lower == 'completed') {
      bgColor = const Color(0xFFECFDF5);
      textColor = const Color(0xFF047857);
      dotColor = const Color(0xFF10B981);
      icon = Icons.check_circle_outline;
    } else if (lower.contains('await') || lower == 'awaiting') {
      bgColor = const Color(0xFFFFF7ED);
      textColor = const Color(0xFFC2410C);
      dotColor = const Color(0xFFF97316);
      icon = Icons.access_time_rounded;
    } else if (lower.contains('progress') || lower == 'in progress') {
      bgColor = const Color(0xFFEFF6FF);
      textColor = const Color(0xFF1D4ED8);
      dotColor = const Color(0xFF3B82F6);
      icon = Icons.sync_alt;
    } else if (lower.contains('pend') || lower == 'pending') {
      bgColor = const Color(0xFFFFFBEB);
      textColor = const Color(0xFFB45309);
      dotColor = const Color(0xFFF59E0B);
      icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dotColor.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.corporateBlue : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF162A42) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundStripesPainter(isDark: isDark),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              await _controller.fetchJobSheets();
            },
            child: Scrollbar(
              controller: _verticalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Create Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => setState(
                                  () => _isSearchVisible = !_isSearchVisible,
                                ),
                                icon: Icon(
                                  IconlyLight.search,
                                  color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                                ),
                                tooltip: "Toggle Search & Filters",
                              ),
                              Text(
                                "Tasks",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _showFilterBottomSheet,
                                icon: const Icon(IconlyLight.filter, color: Color(0xFF0D6EFD)),
                                tooltip: "Filter Options",
                              ),
                              if (_canCreate)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D6EFD),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: _showCreateTaskDialog,
                                  icon: const Icon(IconlyLight.plus, size: 16, color: Colors.white),
                                  label: const Text(
                                    "Create Task",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Filter Bar (Matching Web Interface)
                      if (_isSearchVisible)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Controls: Status Dropdown, Project Dropdown, Filter & Reset buttons
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Status Dropdown
                                  Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: borderColor),
                                      borderRadius: BorderRadius.circular(6),
                                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedStatus,
                                        dropdownColor: isDark ? const Color(0xFF162A42) : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        style: TextStyle(fontSize: 13, color: textColor),
                                        items: _statusOptions
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(
                                                  e,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: e == _selectedStatus ? FontWeight.w600 : FontWeight.normal,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _selectedStatus = val);
                                          }
                                        },
                                        icon: Icon(IconlyLight.arrow_down_2, size: 14, color: textSecondary),
                                      ),
                                    ),
                                  ),

                                  // Project Dropdown
                                  Container(
                                    height: 38,
                                    constraints: const BoxConstraints(maxWidth: 180),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: borderColor),
                                      borderRadius: BorderRadius.circular(6),
                                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _projectOptions.contains(_selectedProject) ? _selectedProject : 'All Projects',
                                        isExpanded: true,
                                        dropdownColor: isDark ? const Color(0xFF162A42) : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        style: TextStyle(fontSize: 13, color: textColor),
                                        items: _projectOptions
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(
                                                  e,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: e == _selectedProject ? FontWeight.w600 : FontWeight.normal,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() => _selectedProject = val);
                                          }
                                        },
                                        icon: Icon(IconlyLight.arrow_down_2, size: 14, color: textSecondary),
                                      ),
                                    ),
                                  ),

                                  // Filter Button (Opens full Filter Modal)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D6EFD),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    onPressed: _showFilterBottomSheet,
                                    icon: const Icon(IconlyLight.filter, size: 14, color: Colors.white),
                                    label: const Text(
                                      "Filter",
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),

                                  // Reset Button
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF0D6EFD),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: _resetFilters,
                                    child: const Text(
                                      "Reset",
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Bottom Row: Search Box & Count Indicator
                              Row(
                                children: [
                                  // Search Field
                                  Expanded(
                                    child: SizedBox(
                                      height: 38,
                                      child: TextField(
                                        controller: _searchController,
                                        style: TextStyle(color: textColor, fontSize: 13),
                                        decoration: InputDecoration(
                                          hintText: "Search tasks, clients, projects...",
                                          hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                                          prefixIcon: Icon(IconlyLight.search, size: 16, color: textSecondary),
                                          suffixIcon: _searchController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: const Icon(Icons.clear, size: 16),
                                                  onPressed: () {
                                                    setState(() {
                                                      _searchController.clear();
                                                    });
                                                  },
                                                )
                                              : null,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            borderSide: BorderSide(color: borderColor),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(6),
                                            borderSide: BorderSide(color: borderColor),
                                          ),
                                          focusedBorder: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(6)),
                                            borderSide: BorderSide(color: Color(0xFF0D6EFD)),
                                          ),
                                        ),
                                        onChanged: (val) => setState(() {}),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Count Indicator (e.g. 1 - 37 of 37)
                                  Text(
                                    filteredTasks.isNotEmpty
                                        ? "1 - ${filteredTasks.length} of ${_controller.jobSheets.length}"
                                        : "0 of ${_controller.jobSheets.length}",
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Loading State
                      if (_controller.isLoading && _controller.jobSheets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60.0),
                          child: Center(
                            child: Column(
                              children: [
                                const CircularProgressIndicator(color: Color(0xFF0D6EFD)),
                                const SizedBox(height: 16),
                                Text("Loading tasks...", style: TextStyle(color: textSecondary)),
                              ],
                            ),
                          ),
                        )
                      // Error State
                      else if (_controller.errorMessage != null && _controller.jobSheets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60.0),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
                                const SizedBox(height: 12),
                                Text(
                                  _controller.errorMessage!,
                                  style: const TextStyle(color: Colors.redAccent),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D6EFD),
                                  ),
                                  onPressed: () => _controller.fetchJobSheets(),
                                  child: const Text("Retry", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        )
                      // Empty State
                      else if (filteredTasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(IconlyLight.document, size: 48, color: textSecondary.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  "No tasks found.",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Try adjusting your filters or search query.",
                                  style: TextStyle(color: textSecondary, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: _resetFilters,
                                  child: const Text("Reset Filters"),
                                ),
                              ],
                            ),
                          ),
                        )
                      // Task List
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredTasks.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final taskNo = task.jobNo.isNotEmpty ? task.jobNo : task.sheetNo;

                            return Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Row: Avatar badge, Task No, Status Badge, Menu
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: const Color(0xFFE8F2FF),
                                          child: Text(
                                            "${index + 1}",
                                            style: const TextStyle(
                                              color: Color(0xFF0D6EFD),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                taskNo,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: textColor,
                                                ),
                                              ),
                                              if (task.projectName.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  task.projectName,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        _buildStatusBadge(task.status, task.statusLabel),
                                        if (_canEdit || _canDelete)
                                          PopupMenuButton<String>(
                                            icon: Icon(
                                              IconlyLight.more_circle,
                                              color: textSecondary,
                                              size: 20,
                                            ),
                                            color: cardColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: isDark
                                                  ? const BorderSide(color: Colors.white24)
                                                  : BorderSide.none,
                                            ),
                                            onSelected: (val) {
                                              if (val == 'edit') {
                                                _showEditTaskDialog(task);
                                              } else if (val == 'delete') {
                                                _confirmDeleteTask(task);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              if (_canEdit)
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        IconlyLight.edit,
                                                        size: 16,
                                                        color: Color(0xFF0D6EFD),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text("Edit Task", style: TextStyle(color: textColor, fontSize: 13)),
                                                    ],
                                                  ),
                                                ),
                                              if (_canDelete)
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        IconlyLight.delete,
                                                        size: 16,
                                                        color: Colors.red,
                                                      ),
                                                      SizedBox(width: 10),
                                                      Text("Delete", style: TextStyle(color: Colors.red, fontSize: 13)),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Attributes Grid / Info rows
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        children: [
                                          // Client
                                          if (task.clientName.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 6.0),
                                              child: Row(
                                                children: [
                                                  Icon(IconlyLight.work, size: 14, color: textSecondary),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "Client: ",
                                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      task.clientName,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          // Operative
                                          if (task.operative.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 6.0),
                                              child: Row(
                                                children: [
                                                  Icon(IconlyLight.profile, size: 14, color: textSecondary),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "Operative: ",
                                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      task.operative,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          // Form Type
                                          if (task.form.isNotEmpty)
                                            Row(
                                              children: [
                                                Icon(IconlyLight.paper, size: 14, color: textSecondary),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "Form: ",
                                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    task.form,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF0D6EFD),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 14),

                                    // View Details Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isDark ? Colors.white : const Color(0xFF0D6EFD),
                                          side: BorderSide(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.3)
                                                : const Color(0xFF0D6EFD).withOpacity(0.3),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                        onPressed: () => _showTaskDetailsBottomSheet(task),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "View Details",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : const Color(0xFF0D6EFD),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 11,
                                              color: isDark ? Colors.white70 : const Color(0xFF0D6EFD),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
