import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';

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

  final List<Map<String, String>> _dummyTasks = [
    {"taskNo": "JOB 29", "status": "Pending", "project": "Asobu Client", "client": "Asobu"},
    {"taskNo": "JOB 30", "status": "Completed", "project": "Euroside Office", "client": "Euroside"},
    {"taskNo": "JOB 31", "status": "In Progress", "project": "Central Park Reno", "client": "City Council"},
    {"taskNo": "JOB 32", "status": "Draft", "project": "Highway A1", "client": "Gov Roads"},
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
          Text(status, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
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
      final matchesSearch = t['taskNo']!.toLowerCase().contains(_searchQuery) ||
          t['project']!.toLowerCase().contains(_searchQuery) ||
          t['client']!.toLowerCase().contains(_searchQuery);
      final matchesStatus = _selectedStatus == 'Status: All' || 'Status: ${t['status']}' == _selectedStatus;
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
                          onPressed: () => setState(() => _isSearchVisible = !_isSearchVisible),
                          icon: Icon(_isSearchVisible ? IconlyLight.search : IconlyLight.search, color: isDark ? Colors.white : Colors.black87),
                          tooltip: "Toggle Search",
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {},
                          icon: const Icon(IconlyLight.plus, size: 18, color: Colors.white),
                          label: const Text("Create Task", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                        )
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
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
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
                                    decoration: InputDecoration(
                                      hintText: "Search tasks...",
                                      hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                                      prefixIcon: Icon(IconlyLight.search, size: 20, color: textSecondary),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(color: borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: Color(0xFF0D6EFD)),
                                      ),
                                    ),
                                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                                  ),
                                ),

                                // Status Dropdown
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(6)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedStatus,
                                      dropdownColor: cardColor,
                                      items: ['Status: All', 'Status: Pending', 'Status: In Progress', 'Status: Completed', 'Status: Draft']
                                          .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 14, color: textColor))))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedStatus = val);
                                      },
                                      icon: Icon(IconlyLight.arrow_down_2, color: textSecondary),
                                    ),
                                  ),
                                ),

                                // Refresh Icon
                                IconButton(
                                  icon: Icon(IconlyLight.swap, color: textColor),
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
                                  filteredTasks.isNotEmpty ? "1 - ${filteredTasks.length} of ${filteredTasks.length}" : "0 of 0",
                                  style: TextStyle(color: textSecondary, fontSize: 14),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Task Card List
                    if (filteredTasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Center(child: Text("No tasks found.", style: TextStyle(color: textSecondary))),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredTasks.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: const Color(0xFFE8F2FF),
                                        child: Text(
                                          task['taskNo']!.replaceAll("JOB ", ""),
                                          style: const TextStyle(color: Color(0xFF0D6EFD), fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              task['taskNo']!,
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              task['project']!,
                                              style: TextStyle(fontSize: 14, color: textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildStatusPill(task['status']!),
                                          const SizedBox(width: 4),
                                          PopupMenuButton<String>(
                                            icon: Icon(IconlyLight.more_circle, color: textSecondary),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            onSelected: (val) {},
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(IconlyLight.edit, size: 18, color: Color(0xFF0D6EFD)),
                                                    SizedBox(width: 12),
                                                    Text("Edit Task"),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(IconlyLight.delete, size: 18, color: Colors.red),
                                                    SizedBox(width: 12),
                                                    Text("Delete", style: TextStyle(color: Colors.red)),
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
                                      Icon(IconlyLight.work, size: 16, color: textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Client: ",
                                        style: TextStyle(fontSize: 13, color: textSecondary),
                                      ),
                                      Text(
                                        task['client']!,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  Divider(height: 1, color: isDark ? const Color(0xFF1F2E40) : Colors.grey.shade100),
                                  const SizedBox(height: 16),
                                  
                                  // Bottom Row: Full-width View Details button
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isDark ? Colors.white : const Color(0xFF0D6EFD),
                                        side: BorderSide(
                                          color: isDark ? Colors.white.withOpacity(0.5) : const Color(0xFF0D6EFD).withOpacity(0.4),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {},
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
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
        ],
      ),
    );
  }
}