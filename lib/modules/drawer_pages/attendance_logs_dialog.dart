import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../models/timesheet_model.dart';
import '../../core/theme/app_theme.dart';

class AttendanceLogsDialog extends StatelessWidget {
  final TimesheetRecord record;
  final Map<int, String> entryStartAddresses;
  final Map<int, String> entryEndAddresses;

  const AttendanceLogsDialog({
    super.key,
    required this.record,
    required this.entryStartAddresses,
    required this.entryEndAddresses,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    
    Widget buildChip(String label, String value) {
      return Container(
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(20),
          color: isDark ? const Color(0xFF1F2E40) : Colors.transparent,
        ),
        child: RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            children: [
              TextSpan(text: "$label: "),
              TextSpan(text: value, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 1000,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(IconlyLight.document, color: textColor),
                    const SizedBox(width: 8),
                    Text("Attendance Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Icon(IconlyLight.close_square, color: isDark ? Colors.white : Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: borderColor),
            const SizedBox(height: 16),
            
            // Summary Chips
            Wrap(
              children: [
                buildChip("First Login", record.clockIn),
                buildChip("Last Logout", record.clockOut),
                buildChip("Total Worked", record.shiftHours),
                buildChip("Projects Worked", record.projectEntries.length.toString()),
              ],
            ),
            const SizedBox(height: 24),
            
            // Data Sections
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: record.projectEntries.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final entry = record.projectEntries[index];
                  final startLoc = entryStartAddresses[index] ?? entry.startLocation;
                  final endLoc = entryEndAddresses[index] ?? entry.endLocation;
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text("${entry.projectName} (${entry.projectCode})", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : const Color(0xFF0D6EFD)).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text("${entry.shiftHours} hrs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0D6EFD))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(IconlyLight.time_circle, size: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text("${entry.clockInTime} - ${entry.clockOutTime}", style: TextStyle(fontSize: 13, color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: borderColor, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(IconlyLight.location, size: 14, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Start Location", style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                  const SizedBox(height: 2),
                                  Text(startLoc.isNotEmpty ? startLoc : "N/A", style: TextStyle(fontSize: 12, color: textColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(IconlyLight.location, size: 14, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("End Location", style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                  const SizedBox(height: 2),
                                  Text(endLoc.isNotEmpty ? endLoc : "N/A", style: TextStyle(fontSize: 12, color: textColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // Footer
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: borderColor),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text("Close", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
