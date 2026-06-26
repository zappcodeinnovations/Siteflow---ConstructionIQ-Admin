import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_endpoints.dart';
import 'job_sheet_controller.dart';
import 'job_sheet_details_screen.dart';
import '../../core/widgets/shimmer_loading.dart';

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

    final ids = _controller.jobSheets.map((e) => e.id).join(',');
    final urlStr = '${ApiEndpoints.baseUrl}/api/job-sheets/?ids=$ids&export=excel';
    final url = Uri.parse(urlStr);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not download report")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          "Job Sheets",
          style: TextStyle(
            color: Color(0xFF0F2C4A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Add Filter Button
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, color: Colors.black87, size: 18),
                    label: const Text(
                      "Add Filter",
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Status Dropdown
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return DropdownButton<String>(
                            value: _controller.selectedStatus,
                            items: ['Status: All', 'Status: Submitted', 'Status: Draft']
                                .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) _controller.setStatusFilter(val);
                            },
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          );
                        }
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Apply Button
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _controller.fetchJobSheets(),
                      child: const Text("Apply", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Refresh Icon
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.black87),
                    onPressed: () => _controller.fetchJobSheets(),
                    tooltip: 'Refresh',
                  ),
                  
                  const Spacer(),
                  
                  // Get Report Button
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: _downloadReport,
                      icon: const Icon(Icons.description, color: Colors.white, size: 18),
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
                      
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
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
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
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
                                          Icons.circle,
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Divider(height: 1, color: Colors.grey.shade200),
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
                                        _buildDetailItem("CHARGE", sheet.charge.isNotEmpty ? "\$${sheet.charge}" : "\$0.00", isBold: true, color: const Color(0xFF0D6EFD)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 20),
                              Divider(height: 1, color: Colors.grey.shade200),
                              const SizedBox(height: 16),
                              
                              // Bottom Row: Dates & Action
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Created: ${sheet.created}",
                                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 12, color: Colors.black54),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Updated: ${sheet.lastUpdated}",
                                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => JobSheetDetailsScreen(jobSheet: sheet),
                                        ),
                                      );
                                    },
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "View Details",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF0D6EFD),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward,
                                          size: 16,
                                          color: Color(0xFF0D6EFD),
                                        ),
                                      ],
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
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isBold = false, Color color = Colors.black87}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOperativeItem(String operative) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "OPERATIVE",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.person_outline, size: 14, color: Colors.blue),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                operative,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
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