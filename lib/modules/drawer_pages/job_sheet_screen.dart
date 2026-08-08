import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import 'job_sheet_controller.dart';
import 'job_sheet_details_screen.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';

class JobSheetScreen extends StatefulWidget {
  const JobSheetScreen({super.key});

  @override
  State<JobSheetScreen> createState() => _JobSheetScreenState();
}

class _JobSheetScreenState extends State<JobSheetScreen> {
  final JobSheetController _controller = JobSheetController();

  @override
  void initState() { 
    super.initState();
    _controller.fetchJobSheets();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _downloadReport() async {
    if (_controller.jobSheets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No job sheets to export")),
      );
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Downloading report...")),
        );
      }

      final ids = _controller.jobSheets.map((e) => e.id).join(',');
      final urlStr = '${ApiEndpoints.baseUrl}/job-sheets/?ids=$ids&export=excel';
      
      final response = await ApiClient.get(urlStr);

      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/job_sheets_report.xlsx');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        await Share.shareXFiles([XFile(file.path)], text: 'Job Sheets Report');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Download failed. Status: ${response.statusCode}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _showFilterDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = _controller.filterOptions;
    
    // Create local state for dialog
    String? tempProject = _controller.selectedProject;
    String? tempSheetNo = _controller.selectedSheetNo;
    String? tempClient = _controller.selectedClient;
    String? tempOperative = _controller.selectedOperative;
    String? tempForm = _controller.selectedForm;

    List<String> getOptions(String key) {
      if (options[key] is List) {
        return (options[key] as List).map((e) => e.toString()).toList();
      }
      return [];
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            Widget buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.white,
                      border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: isDark ? AppTheme.corporateBlue : Colors.white,
                        value: value,
                        hint: Text("Select $label", style: TextStyle(color: isDark ? Colors.white54 : Colors.black38)),
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text("All")),
                          ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            onChanged(val);
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }

            return AlertDialog(
              backgroundColor: isDark ? AppTheme.corporateBlue : Colors.white,
              title: Text("Filter Job Sheets", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildDropdown("Project", tempProject, getOptions("projects"), (val) => tempProject = val),
                    buildDropdown("Sheet No", tempSheetNo, getOptions("sheet_nos"), (val) => tempSheetNo = val),
                    buildDropdown("Client", tempClient, getOptions("clients"), (val) => tempClient = val),
                    buildDropdown("Operative", tempOperative, getOptions("operatives"), (val) => tempOperative = val),
                    buildDropdown("Form", tempForm, getOptions("forms"), (val) => tempForm = val),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _controller.clearFilters();
                    Navigator.pop(ctx);
                  },
                  child: const Text("Clear All"),
                ),
                ElevatedButton(
                  onPressed: () {
                    _controller.setFilter(
                      project: tempProject,
                      sheetNo: tempSheetNo,
                      client: tempClient,
                      operative: tempOperative,
                      form: tempForm,
                    );
                    Navigator.pop(ctx);
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.corporateBlue : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        backgroundColor: isDark ? AppTheme.corporateBlue : Colors.white,
        title: Text(
          "Job Sheets",
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F2C4A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundStripesPainter(isDark: isDark),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
            // Filter Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.corporateBlue : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Status Dropdown
                       Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white,
                          border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              return DropdownButton<String>(
                                dropdownColor: isDark ? AppTheme.corporateBlue : Colors.white,
                                value: _controller.selectedStatus,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                items: ['Status: All', 'Status: Submitted', 'Status: Draft']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87))))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) _controller.setStatusFilter(val);
                                },
                                icon: Icon(IconlyLight.arrow_down_2, color: isDark ? Colors.white70 : Colors.grey),
                              );
                            }
                          ),
                        ),
                      ),
                      
                      // Refresh Icon
                      IconButton(
                        icon: Icon(IconlyLight.swap, color: isDark ? Colors.white : Colors.black87),
                        onPressed: () => _controller.fetchJobSheets(),
                        tooltip: 'Refresh',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                      // Filter Icon
                      IconButton(
                        icon: Icon(IconlyLight.filter, color: isDark ? Colors.white : Colors.black87),
                        onPressed: () => _showFilterDialog(context),
                        tooltip: 'Filter',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  
                  // Get Report Button
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: _downloadReport,
                      icon: const Icon(IconlyLight.paper, color: Colors.white, size: 18),
                      label: const Text("Get Report", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cards List Container
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  if (_controller.isLoading && _controller.jobSheets.isEmpty) {
                    return const ShimmerLoadingList();
                  }

                  if (_controller.errorMessage != null && _controller.jobSheets.isEmpty) {
                    return Center(child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)));
                  }

                  if (_controller.jobSheets.isEmpty) {
                    return const Center(child: Text("No job sheets found.", style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    itemCount: _controller.jobSheets.length,
                    itemBuilder: (context, index) {
                      final sheet = _controller.jobSheets[index];
                      final isCompleted = sheet.statusLabel.toLowerCase().contains("completed") || sheet.status.toLowerCase().contains("completed");
                      
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
                      final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
                      final textColor = isDark ? Colors.white : Colors.black87;
                      final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                              // Top Row: Sheet No and Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sheet.sheetNo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          IconlyLight.category,
                                          size: 8,
                                          color: isCompleted ? Colors.green : Colors.orange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          sheet.statusLabel.isNotEmpty ? sheet.statusLabel : sheet.status,
                                          style: TextStyle(
                                            color: isCompleted ? Colors.green : Colors.orange,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Project Name
                              Text(
                                sheet.projectName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
                              const SizedBox(height: 16),
                              
                              // Details Grid
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Column 1
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailItem("CLIENT", sheet.clientName),
                                        const SizedBox(height: 16),
                                        _buildOperativeItem(sheet.operative),
                                        const SizedBox(height: 16),
                                        _buildDetailItem("MATERIAL COST", sheet.materialCost.isNotEmpty ? "\$${sheet.materialCost}" : "\$0.00", isBold: true),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Column 2
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailItem("JOB NO/REF", "${sheet.jobNo} / ${sheet.jobReference}"),
                                        const SizedBox(height: 16),
                                        _buildDetailItem("LOCATION", sheet.location),
                                        const SizedBox(height: 16),
                                        _buildDetailItem("CHARGE", sheet.charge.isNotEmpty ? "\$${sheet.charge}" : "\$0.00", isBold: true, color: isDark ? Colors.white : const Color(0xFF0D6EFD)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
                              const SizedBox(height: 16),
                              
                              // Bottom Section: Dates & Action
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Created: ${sheet.created}",
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(IconlyLight.time_circle, size: 12, color: textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Updated: ${sheet.lastUpdated}",
                                        style: TextStyle(fontSize: 12, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => JobSheetDetailsScreen(jobSheet: sheet),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFF0D6EFD).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "View Details",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.white : const Color(0xFF0D6EFD),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              IconlyLight.arrow_right,
                                              size: 14,
                                              color: isDark ? Colors.white : const Color(0xFF0D6EFD),
                                            ),
                                          ],
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
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isBold = false, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black54;
    final valueColor = color ?? (isDark ? Colors.white : Colors.black87);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: labelColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOperativeItem(String operative) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black54;
    final valueColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "OPERATIVE",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: labelColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: isDark ? Colors.white10 : Colors.blue.shade50,
              child: Icon(IconlyLight.profile, size: 14, color: isDark ? Colors.white : Colors.blue),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                operative,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}