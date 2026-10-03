import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import '../../core/services/auth_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final ScrollController _verticalScrollController = ScrollController();
  bool _isSearchVisible = false;
  String _searchQuery = "";
  String _selectedStatus = "Status: All";
  bool _canCreate = true;
  bool _canEdit = true;
  bool _canDelete = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
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

  void _showCreateTaskDialog() {
    final taskNoController = TextEditingController(
      text: "JOB ${_dummyTasks.length + 29}",
    );
    final projectController = TextEditingController();
    final clientController = TextEditingController();
    final instructionsController = TextEditingController();
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
                side: isDark
                    ? const BorderSide(color: Colors.white24)
                    : BorderSide.none,
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: taskNoController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "e.g. JOB 33",
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
                            borderSide: BorderSide(
                              color: Color(0xFF0D6EFD),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Project Name",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: projectController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "e.g. Second testing project",
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
                            borderSide: BorderSide(
                              color: Color(0xFF0D6EFD),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Client Name",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
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
                            borderSide: BorderSide(
                              color: Color(0xFF0D6EFD),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Status",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
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
                            dropdownColor: isDark
                                ? const Color(0xFF162A42)
                                : Colors.white,
                            style: TextStyle(color: textColor, fontSize: 14),
                            items: [
                              'Pending',
                              'In Progress',
                              'Completed',
                              'Draft',
                            ]
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
                      const SizedBox(height: 14),
                      Text(
                        "Instructions (Optional)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: instructionsController,
                        maxLines: 2,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Enter task instructions...",
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
                            borderSide: BorderSide(
                              color: Color(0xFF0D6EFD),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
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
                        : "JOB ${_dummyTasks.length + 29}";
                    final project = projectController.text.trim().isNotEmpty
                        ? projectController.text.trim()
                        : "General Project";
                    final client = clientController.text.trim().isNotEmpty
                        ? clientController.text.trim()
                        : "Euroside";

                    setState(() {
                      _dummyTasks.insert(0, {
                        "taskNo": taskNo,
                        "status": selectedStatus,
                        "project": project,
                        "client": client,
                      });
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Task $taskNo created successfully!"),
                      ),
                    );
                  },
                  child: const Text(
                    "Create Task",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditTaskDialog(Map<String, String> task) {
    final taskNoController = TextEditingController(text: task['taskNo']);
    final projectController = TextEditingController(text: task['project']);
    final clientController = TextEditingController(text: task['client']);
    String selectedStatus = task['status'] ?? "Pending";

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
                side: isDark
                    ? const BorderSide(color: Colors.white24)
                    : BorderSide.none,
              ),
              title: Text(
                "Edit Task",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor,
                ),
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
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Project Name",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Client Name",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Status",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
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
                            dropdownColor: isDark
                                ? const Color(0xFF162A42)
                                : Colors.white,
                            style: TextStyle(color: textColor, fontSize: 14),
                            items: [
                              'Pending',
                              'In Progress',
                              'Completed',
                              'Draft',
                            ]
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
                    setState(() {
                      task['taskNo'] = taskNoController.text.trim();
                      task['project'] = projectController.text.trim();
                      task['client'] = clientController.text.trim();
                      task['status'] = selectedStatus;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Task updated successfully!")),
                    );
                  },
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTask(Map<String, String> task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppTheme.corporateBlue : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isDark ? const BorderSide(color: Colors.white24) : BorderSide.none,
          ),
          title: Text(
            "Delete Task",
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
          content: Text(
            "Are you sure you want to delete ${task['taskNo']}?",
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
                  _dummyTasks.remove(task);
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

  Future<void> _viewDetails(Map<String, String> task) async {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        side: isDark ? const BorderSide(color: Colors.white24) : BorderSide.none,
      ),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task['taskNo'] ?? 'Task Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),
              _detailRow('Project', task['project'] ?? '-', textColor, textSecondary),
              _detailRow('Client', task['client'] ?? '-', textColor, textSecondary),
              _detailRow('Status', task['status'] ?? '-', textColor, textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color textColor, Color labelColor) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
          ),
        ),
      ],
    ),
  );

  final List<Map<String, String>> _dummyTasks = [
    {
      "taskNo": "JOB 29",
      "status": "Pending",
      "project": "Asobu Client",
      "client": "Asobu",
    },
    {
      "taskNo": "JOB 30",
      "status": "Completed",
      "project": "Euroside Office",
      "client": "Euroside",
    },
    {
      "taskNo": "JOB 31",
      "status": "In Progress",
      "project": "Central Park Reno",
      "client": "City Council",
    },
    {
      "taskNo": "JOB 32",
      "status": "Draft",
      "project": "Highway A1",
      "client": "Gov Roads",
    },
  ];

  Widget _buildStatusPill(String status) {
    Color bg = Colors.grey.shade100;
    Color text = Colors.grey.shade700;
    IconData icon = IconlyLight.info_square;

    if (status == 'Completed') {
      bg = Colors.green.shade50;
      text = Colors.green.shade700;
      icon = IconlyLight.tick_square;
    } else if (status == 'Pending') {
      bg = Colors.orange.shade50;
      text = Colors.orange.shade700;
      icon = IconlyLight.time_circle;
    } else if (status == 'In Progress') {
      bg = Colors.blue.shade50;
      text = Colors.blue.shade700;
      icon = IconlyLight.swap;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: text.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: text, size: 14),
          const SizedBox(width: 4),
          Text(
            status,
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
  void dispose() {
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _dummyTasks.where((t) {
      final matchesSearch =
          t['taskNo']!.toLowerCase().contains(_searchQuery) ||
          t['project']!.toLowerCase().contains(_searchQuery) ||
          t['client']!.toLowerCase().contains(_searchQuery);
      final matchesStatus =
          _selectedStatus == 'Status: All' ||
          'Status: ${t['status']}' == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.corporateBlue : const Color(0xFFF8FAFC);
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
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
          Scrollbar(
            controller: _verticalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header & Export
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => setState(
                            () => _isSearchVisible = !_isSearchVisible,
                          ),
                          icon: Icon(
                            _isSearchVisible
                                ? IconlyLight.search
                                : IconlyLight.search,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          tooltip: "Toggle Search",
                        ),
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
                            onPressed: _showCreateTaskDialog,
                            icon: const Icon(
                              IconlyLight.plus,
                              size: 18,
                              color: Colors.white,
                            ),
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
                              color: Colors.black.withOpacity(0.02),
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: borderColor,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: borderColor,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF0D6EFD),
                                        ),
                                      ),
                                    ),
                                    onChanged: (val) => setState(
                                      () => _searchQuery = val.toLowerCase(),
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
                                      dropdownColor: isDark
                                          ? const Color(0xFF162A42)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textColor,
                                      ),
                                      items: [
                                        'Status: All',
                                        'Status: Pending',
                                        'Status: In Progress',
                                        'Status: Completed',
                                        'Status: Draft',
                                      ]
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(
                                                e,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: e == _selectedStatus
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F2C4A),
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
                                      icon: Icon(
                                        IconlyLight.arrow_down_2,
                                        size: 16,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ),
                                ),

                                // Refresh Icon
                                IconButton(
                                  icon: Icon(
                                    IconlyLight.swap,
                                    color: textColor,
                                  ),
                                  onPressed: () => setState(() {
                                    _searchQuery = "";
                                    _selectedStatus = "Status: All";
                                  }),
                                  tooltip: 'Refresh',
                                ),
                              ],
                            ),

                            // Right Actions
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  filteredTasks.isNotEmpty
                                      ? "1 - ${filteredTasks.length} of ${filteredTasks.length}"
                                      : "0 of 0",
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

                    // Task Card List
                    if (filteredTasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Center(
                          child: Text(
                            "No tasks found.",
                            style: TextStyle(color: textSecondary),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTasks.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return Container(
                            margin: EdgeInsets.zero,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
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
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: const Color(
                                          0xFFE8F2FF,
                                        ),
                                        child: Text(
                                          task['taskNo']!.replaceAll(
                                            "JOB ",
                                            "",
                                          ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task['taskNo']!,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              task['project']!,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildStatusPill(task['status']!),
                                          const SizedBox(width: 4),
                                          if (_canEdit || _canDelete)
                                            PopupMenuButton<String>(
                                              icon: Icon(
                                                IconlyLight.more_circle,
                                                color: textSecondary,
                                              ),
                                              color: cardColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: isDark
                                                    ? const BorderSide(
                                                        color: Colors.white24,
                                                      )
                                                    : BorderSide.none,
                                              ),
                                              onSelected: (val) { if (val == 'edit') { _showEditTaskDialog(task); } else if (val == 'delete') { _confirmDeleteTask(task); } },
                                              itemBuilder: (context) => [
                                                if (_canEdit)
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          IconlyLight.edit,
                                                          size: 18,
                                                          color: Color(
                                                            0xFF0D6EFD,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Text(
                                                          "Edit Task",
                                                          style: TextStyle(
                                                            color: textColor,
                                                          ),
                                                        ),
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
                                                          size: 18,
                                                          color: Colors.red,
                                                        ),
                                                        SizedBox(width: 12),
                                                        Text(
                                                          "Delete",
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
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
                                      Text(
                                        task['client']!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),
                                  Divider(
                                    height: 1,
                                    color: isDark
                                        ? const Color(0xFF1F2E40)
                                        : Colors.grey.shade100,
                                  ),
                                  const SizedBox(height: 16),

                                  // Bottom Row: Full-width View Details button
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isDark
                                            ? Colors.white
                                            : const Color(0xFF0D6EFD),
                                        side: BorderSide(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.5)
                                              : const Color(
                                                  0xFF0D6EFD,
                                                ).withOpacity(0.4),
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
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "View Details",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0D6EFD),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 11,
                                            color: isDark
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

