import 'package:flutter/material.dart';

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
    IconData icon = Icons.info_outline;

    if (status == 'Completed') {
      bg = Colors.green.shade50;
      text = Colors.green.shade700;
      icon = Icons.check_circle;
    } else if (status == 'Pending') {
      bg = Colors.orange.shade50;
      text = Colors.orange.shade700;
      icon = Icons.pending;
    } else if (status == 'In Progress') {
      bg = Colors.blue.shade50;
      text = Colors.blue.shade700;
      icon = Icons.autorenew;
    }

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

    return Scrollbar(
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
                    icon: Icon(_isSearchVisible ? Icons.search_off : Icons.search, color: Colors.black87),
                    tooltip: "Toggle Search",
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
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
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                prefixIcon: const Icon(Icons.search, size: 20),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
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
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedStatus,
                                items: ['Status: All', 'Status: Pending', 'Status: In Progress', 'Status: Completed', 'Status: Draft']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedStatus = val);
                                },
                                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                              ),
                            ),
                          ),

                          // Refresh Icon
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.black87),
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
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Task Card List
              if (filteredTasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(child: Text("No tasks found.", style: TextStyle(color: Colors.grey))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Task No, Project, Status
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
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        task['project']!,
                                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusPill(task['status']!),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Middle Row: Client info
                            Row(
                              children: [
                                Icon(Icons.business, size: 16, color: Colors.grey.shade500),
                                const SizedBox(width: 6),
                                Text(
                                  "Client: ",
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                                Text(
                                  task['client']!,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            Divider(height: 1, color: Colors.grey.shade200),
                            const SizedBox(height: 16),
                            
                            // Bottom Row: View Details & Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {},
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "View Details",
                                        style: TextStyle(fontSize: 13, color: Color(0xFF0D6EFD), fontWeight: FontWeight.w600),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward, size: 14, color: Color(0xFF0D6EFD)),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  onSelected: (val) {},
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0D6EFD)),
                                          SizedBox(width: 12),
                                          Text("Edit Task"),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
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
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}