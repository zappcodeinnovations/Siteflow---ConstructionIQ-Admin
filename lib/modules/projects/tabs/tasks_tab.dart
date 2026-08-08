import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/theme/app_theme.dart';

class TasksTab extends StatelessWidget {
  final List<dynamic> tasks;

  const TasksTab({Key? key, required this.tasks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Filter Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: isDark ? AppTheme.corporateBlue : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
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
                          dropdownColor: isDark ? AppTheme.corporateBlue : Colors.white,
                          value: 'Status: All',
                          items: ['Status: All', 'Status: Open', 'Status: Closed']
                              .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black87))))
                              .toList(),
                          onChanged: (val) {},
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
                        onPressed: () {},
                        icon: Icon(IconlyLight.filter, size: 16, color: isDark ? Colors.white : Colors.black87),
                        label: const Text("Filters",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                Text("Total: ${tasks.length}",
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
          child: tasks.isEmpty
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
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskCard(
                      context,
                      taskNo: task['task_no']?.toString() ?? "N/A",
                      reference: task['reference']?.toString() ?? "N/A",
                      status: task['status']?.toString() ?? "N/A",
                      operativeName:
                          task['operative_name']?.toString() ?? "N/A",
                      form: task['form']?.toString() ?? "N/A",
                      sheets: task['sheets']?.toString() ?? "N/A",
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(
    BuildContext context, {
    required String taskNo,
    required String reference,
    required String status,
    required String operativeName,
    required String form,
    required String sheets,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final isCompleted = status.toLowerCase() == 'completed' ||
        status.toLowerCase() == 'closed';
    final statusColor = isCompleted ? Colors.green : const Color(0xFF0D6EFD);
    final statusBgColor =
        isCompleted 
            ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50) 
            : (isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50);

    return Container(
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
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
                      status.toUpperCase(),
                      style: TextStyle(
                        color: isDark ? Colors.white : statusColor.withOpacity(0.9),
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
            children: [
              Expanded(
                child: _buildInfoColumn(
                    context, "OPERATIVE", operativeName, IconlyLight.profile),
              ),
              Expanded(
                child: _buildInfoColumn(context, "FORM", form, IconlyLight.paper),
              ),
              Expanded(
                child: _buildInfoColumn(context, "SHEETS", sheets, IconlyLight.paper),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Footer Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
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
                onPressed: () {},
                child: const Text("View Details",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          )
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
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textSecondary,
                    letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
