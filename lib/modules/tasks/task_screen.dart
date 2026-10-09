import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../models/job_sheet_model.dart';
import '../projects/widgets/create_task_dialog.dart';
import '../projects/create_task_controller.dart';
import '../drawer_pages/job_sheet_controller.dart';
import '../drawer_pages/job_sheet_details_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/services/auth_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final JobSheetController _controller = JobSheetController();
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;
  String _searchQuery = "";
  String _selectedStatus = "Status: All";
  String _selectedProject = "All";
  String _selectedClient = "All";
  String _selectedOperative = "All";
  bool _canCreate = false;
  bool _canEdit = false;
  bool _canDelete = false;

  final List<String> _statusOptions = [
    'Status: All',
    'Status: Pending',
    'Status: In Progress',
    'Status: Completed',
    'Status: Awaiting',
    'Status: Draft',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    _verticalScrollController.addListener(_loadNextPageWhenNeeded);
    _controller.fetchJobSheets();
    _loadPermissions();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _loadNextPageWhenNeeded() {
    if (!_verticalScrollController.hasClients) return;
    if (_verticalScrollController.position.extentAfter < 400) {
      _controller.loadMore();
    }
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
    final set = <String>{'All'};
    if (_controller.filterOptions['projects'] is List) {
      for (final p in _controller.filterOptions['projects']) {
        if (p != null && p.toString().trim().isNotEmpty) {
          set.add(p.toString().trim());
        }
      }
    }
    for (final t in _controller.jobSheets) {
      if (t.projectName.trim().isNotEmpty) set.add(t.projectName.trim());
    }
    return set.toList();
  }

  List<String> get _clientOptions {
    final set = <String>{'All'};
    if (_controller.filterOptions['clients'] is List) {
      for (final c in _controller.filterOptions['clients']) {
        if (c != null && c.toString().trim().isNotEmpty) {
          set.add(c.toString().trim());
        }
      }
    }
    for (final t in _controller.jobSheets) {
      if (t.clientName.trim().isNotEmpty) set.add(t.clientName.trim());
    }
    return set.toList();
  }

  List<String> get _operativeOptions {
    final set = <String>{'All'};
    if (_controller.filterOptions['operatives'] is List) {
      for (final o in _controller.filterOptions['operatives']) {
        if (o != null) {
          final str = o.toString().trim();
          if (str.isNotEmpty && CreateTaskController.isEligibleOperativeName(str)) {
            set.add(str);
          }
        }
      }
    }
    for (final t in _controller.jobSheets) {
      final op = t.operative.trim();
      if (op.isNotEmpty && CreateTaskController.isEligibleOperativeName(op)) {
        set.add(op);
      }
    }
    return set.toList();
  }

  bool get _hasActiveFilters =>
      _selectedStatus != 'Status: All' ||
      _selectedProject != 'All' ||
      _selectedClient != 'All' ||
      _selectedOperative != 'All';

  List<JobSheet> get _filteredTasks {
    final query = _searchQuery.trim().toLowerCase();

    return _controller.jobSheets.where((task) {
      // 1. Status Filter
      if (_selectedStatus != 'Status: All' && _selectedStatus != 'All') {
        final targetStatus = _selectedStatus
            .replaceAll('Status: ', '')
            .toLowerCase()
            .replaceAll(' ', '_');
        final taskStatus = task.status.toLowerCase().replaceAll(' ', '_');
        final taskStatusLabel =
            task.statusLabel.toLowerCase().replaceAll(' ', '_');

        final matchesStatus = taskStatus == targetStatus ||
            taskStatusLabel == targetStatus ||
            (targetStatus == 'awaiting' &&
                (taskStatus.contains('await') ||
                    taskStatusLabel.contains('await'))) ||
            (targetStatus == 'in_progress' &&
                (taskStatus.contains('progress') ||
                    taskStatusLabel.contains('progress'))) ||
            (targetStatus == 'completed' &&
                (taskStatus.contains('complete') ||
                    taskStatusLabel.contains('complete'))) ||
            (targetStatus == 'pending' &&
                (taskStatus.contains('pend') ||
                    taskStatusLabel.contains('pend'))) ||
            (targetStatus == 'draft' &&
                (taskStatus.contains('draft') ||
                    taskStatusLabel.contains('draft')));

        if (!matchesStatus) return false;
      }

      // 2. Project Filter
      if (_selectedProject != 'All') {
        if (task.projectName.trim().toLowerCase() !=
            _selectedProject.trim().toLowerCase()) {
          return false;
        }
      }

      // 3. Client Filter
      if (_selectedClient != 'All') {
        if (task.clientName.trim().toLowerCase() !=
            _selectedClient.trim().toLowerCase()) {
          return false;
        }
      }

      // 4. Operative Filter
      if (_selectedOperative != 'All') {
        if (task.operative.trim().toLowerCase() !=
            _selectedOperative.trim().toLowerCase()) {
          return false;
        }
      }

      // 5. Search Query Filter
      if (query.isNotEmpty) {
        final taskNo =
            (task.jobNo.isNotEmpty ? task.jobNo : task.sheetNo).toLowerCase();
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
      _searchQuery = "";
      _selectedStatus = "Status: All";
      _selectedProject = "All";
      _selectedClient = "All";
      _selectedOperative = "All";
    });
    _controller.clearFilters();
  }

  void _showFilterBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0F2C4A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final inputBg =
        isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC);

    String tempProject = _selectedProject;
    String tempClient = _selectedClient;
    String tempOperative = _selectedOperative;
    String tempStatus =
        _selectedStatus.startsWith('Status: ')
            ? _selectedStatus.substring(8)
            : _selectedStatus;

    final projectOptions = _projectOptions;
    final clientOptions = _clientOptions;
    final operativeOptions = _operativeOptions;
    final statusList = [
      'All',
      'Pending',
      'In Progress',
      'Completed',
      'Awaiting',
      'Draft',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget buildFilterDropdown({
              required String label,
              required String value,
              required List<String> items,
              required IconData icon,
              required ValueChanged<String?> onChanged,
            }) {
              final selectedValue = items.contains(value) ? value : items.first;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: const Color(0xFF0D6EFD)),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedValue,
                        isExpanded: true,
                        dropdownColor:
                            isDark ? const Color(0xFF162A42) : Colors.white,
                        style: TextStyle(color: textColor, fontSize: 14),
                        icon: Icon(
                          IconlyLight.arrow_down_2,
                          size: 18,
                          color: textSecondary,
                        ),
                        items:
                            items.map((item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    fontWeight:
                                        item == selectedValue
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => onChanged(val));
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white30 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Filter Tasks",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              tempProject = 'All';
                              tempClient = 'All';
                              tempOperative = 'All';
                              tempStatus = 'All';
                            });
                          },
                          icon: const Icon(
                            IconlyLight.swap,
                            size: 16,
                            color: Color(0xFF0D6EFD),
                          ),
                          label: const Text(
                            "Reset",
                            style: TextStyle(
                              color: Color(0xFF0D6EFD),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: borderColor, height: 1),
                    const SizedBox(height: 18),

                    // Scrollable filter fields
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Project
                            buildFilterDropdown(
                              label: "Project",
                              value: tempProject,
                              items: projectOptions,
                              icon: Icons.business_outlined,
                              onChanged: (val) => tempProject = val!,
                            ),

                            // Client
                            buildFilterDropdown(
                              label: "Client",
                              value: tempClient,
                              items: clientOptions,
                              icon: IconlyLight.work,
                              onChanged: (val) => tempClient = val!,
                            ),

                            // Status
                            buildFilterDropdown(
                              label: "Status",
                              value: tempStatus,
                              items: statusList,
                              icon: IconlyLight.info_square,
                              onChanged: (val) => tempStatus = val!,
                            ),

                            // Operative
                            buildFilterDropdown(
                              label: "Operative",
                              value: tempOperative,
                              items: operativeOptions,
                              icon: IconlyLight.profile,
                              onChanged: (val) => tempOperative = val!,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons (Cancel & Apply)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  isDark ? Colors.white70 : Colors.black87,
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6EFD),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedProject = tempProject;
                                _selectedClient = tempClient;
                                _selectedOperative = tempOperative;
                                _selectedStatus =
                                    tempStatus == 'All'
                                        ? 'Status: All'
                                        : 'Status: $tempStatus';
                              });
                              Navigator.pop(context);
                            },
                            child: const Text(
                              "Apply Filters",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
          },
        );
      },
    );
  }

  Future<void> _showCreateTaskFlow() async {
    if (!_canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Access denied: You do not have permission to create tasks.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const CreateTaskDialog(),
    );

    if (result == true && mounted) {
      _controller.fetchJobSheets();
    }
  }

  Future<void> _viewDetails(JobSheet task) async {
    if (!await AuthService.can('tasks')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Access denied: You do not have permission to view task details.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobSheetDetailsScreen(jobSheet: task),
      ),
    );
  }

  Widget _buildStatusPill(String status, String statusLabel) {
    Color bg = Colors.grey.shade100;
    Color text = Colors.grey.shade700;
    IconData icon = IconlyLight.info_square;

    final lower =
        (statusLabel.isNotEmpty ? statusLabel : status).toLowerCase();

    if (lower.contains('complete')) {
      bg = Colors.green.shade50;
      text = Colors.green.shade700;
      icon = IconlyLight.tick_square;
    } else if (lower.contains('pend')) {
      bg = Colors.orange.shade50;
      text = Colors.orange.shade700;
      icon = IconlyLight.time_circle;
    } else if (lower.contains('progress')) {
      bg = Colors.blue.shade50;
      text = Colors.blue.shade700;
      icon = IconlyLight.swap;
    } else if (lower.contains('await')) {
      bg = Colors.purple.shade50;
      text = Colors.purple.shade700;
      icon = IconlyLight.time_circle;
    } else if (lower.contains('draft')) {
      bg = Colors.grey.shade100;
      text = Colors.grey.shade700;
      icon = IconlyLight.document;
    }

    final displayText =
        statusLabel.isNotEmpty
            ? statusLabel
            : (status.isNotEmpty ? status : 'Pending');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: text.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: text, size: 14),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;
    final totalCount = _controller.totalCount;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return RefreshIndicator(
      onRefresh: () async {
        await _controller.fetchJobSheets();
      },
      child: Container(
        color: bgColor,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundStripesPainter(isDark: isDark),
              ),
            ),
            Scrollbar(
              controller: _verticalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Actions
                      Row(
                        children: [
                          IconButton(
                            onPressed:
                                () => setState(
                                  () => _isSearchVisible = !_isSearchVisible,
                                ),
                            icon: Icon(
                              IconlyLight.search,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            tooltip: "Toggle Search",
                          ),
                          IconButton(
                            onPressed: () => _showFilterBottomSheet(context),
                            icon: Stack(
                              children: [
                                Icon(
                                  IconlyLight.filter,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                if (_hasActiveFilters)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0D6EFD),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            tooltip: "Filter Tasks",
                          ),
                          const Spacer(),
                          if (_canCreate)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D6EFD),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _showCreateTaskFlow,
                              icon: const Icon(
                                IconlyLight.plus,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Create Task",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Filter Bar
                      if (_isSearchVisible)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: borderColor),
                          ),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Search Field
                                  SizedBox(
                                    width: 200,
                                    height: 40,
                                    child: TextField(
                                      controller: _searchController,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "Search tasks...",
                                        hintStyle: TextStyle(
                                          color: textSecondary,
                                          fontSize: 14,
                                        ),
                                        prefixIcon: Icon(
                                          IconlyLight.search,
                                          size: 20,
                                          color: textSecondary,
                                        ),
                                        suffixIcon:
                                            _searchController.text.isNotEmpty
                                                ? IconButton(
                                                  icon: Icon(
                                                    Icons.close,
                                                    size: 18,
                                                    color: textSecondary,
                                                  ),
                                                  onPressed: () {
                                                    _searchController.clear();
                                                    setState(() {
                                                      _searchQuery = "";
                                                    });
                                                  },
                                                )
                                                : null,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: BorderSide(
                                            color: borderColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: BorderSide(
                                            color: borderColor,
                                          ),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(6),
                                          ),
                                          borderSide: BorderSide(
                                            color: Color(0xFF0D6EFD),
                                          ),
                                        ),
                                      ),
                                      onChanged:
                                          (val) => setState(
                                            () =>
                                                _searchQuery =
                                                    val.toLowerCase().trim(),
                                          ),
                                    ),
                                  ),

                                  // Status Dropdown
                                  Container(
                                    height: 40,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: borderColor),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedStatus,
                                        dropdownColor:
                                            isDark
                                                ? const Color(0xFF0F2C4A)
                                                : Colors.white,
                                        items:
                                            _statusOptions
                                                .map(
                                                  (e) => DropdownMenuItem(
                                                    value: e,
                                                    child: Text(
                                                      e,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(
                                              () => _selectedStatus = val,
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          IconlyLight.arrow_down_2,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Refresh / Reset Icon
                                  IconButton(
                                    icon: Icon(
                                      IconlyLight.swap,
                                      color: textColor,
                                    ),
                                    onPressed: _resetFilters,
                                    tooltip: 'Reset Filters',
                                  ),
                                ],
                              ),

                              // Right Actions (Counts)
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    filteredTasks.isNotEmpty
                                        ? "1 - ${filteredTasks.length} of $totalCount"
                                        : "0 of $totalCount",
                                    style: TextStyle(
                                      color: textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Task Card List / Loading State
                      if (_controller.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (filteredTasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  IconlyLight.document,
                                  size: 48,
                                  color: textSecondary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No tasks found.",
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredTasks.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final taskDisplayNo =
                                task.jobNo.isNotEmpty
                                    ? task.jobNo
                                    : (task.sheetNo.isNotEmpty
                                        ? task.sheetNo
                                        : "JOB ${task.id}");

                            return Container(
                              margin: EdgeInsets.zero,
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top Row: Task No, Project, Status, Actions
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                taskDisplayNo,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: textColor,
                                                ),
                                                softWrap: true,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                task.projectName.isNotEmpty
                                                    ? task.projectName
                                                    : 'No Project Assigned',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: textSecondary,
                                                ),
                                                softWrap: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildStatusPill(
                                              task.status,
                                              task.statusLabel,
                                            ),
                                            const SizedBox(width: 4),
                                            if (_canEdit || _canDelete)
                                              PopupMenuButton<String>(
                                                icon: Icon(
                                                  IconlyLight.more_circle,
                                                  color: textSecondary,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                onSelected: (val) {
                                                  if (val == 'view') {
                                                    _viewDetails(task);
                                                  }
                                                },
                                                itemBuilder:
                                                    (context) => [
                                                      const PopupMenuItem(
                                                        value: 'view',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              IconlyLight.show,
                                                              size: 18,
                                                              color: Color(
                                                                0xFF0D6EFD,
                                                              ),
                                                            ),
                                                            SizedBox(width: 12),
                                                            Text("View Details"),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Middle Row: Client info
                                    Row(
                                      children: [
                                        Icon(
                                          IconlyLight.work,
                                          size: 16,
                                          color: textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Client: ",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textSecondary,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            task.clientName.isNotEmpty
                                                ? task.clientName
                                                : '-',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),
                                    Divider(
                                      height: 1,
                                      color:
                                          isDark
                                              ? const Color(0xFF1F2E40)
                                              : Colors.grey.shade100,
                                    ),
                                    const SizedBox(height: 16),

                                    // Bottom Row: Full-width View Details button
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0D6EFD),
                                          side: BorderSide(
                                            color:
                                                isDark
                                                    ? Colors.white.withValues(
                                                      alpha: 0.5,
                                                    )
                                                    : const Color(
                                                      0xFF0D6EFD,
                                                    ).withValues(alpha: 0.4),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        onPressed: () => _viewDetails(task),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "View Details",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : const Color(
                                                          0xFF0D6EFD,
                                                        ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 11,
                                              color:
                                                  isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF0D6EFD),
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
                      if (_controller.isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_controller.hasMore)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Center(child: Text('Scroll to load more tasks')),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
