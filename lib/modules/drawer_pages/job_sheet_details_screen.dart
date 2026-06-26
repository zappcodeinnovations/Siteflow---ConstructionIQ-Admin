import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_sheet_model.dart';
import '../../core/network/api_endpoints.dart';

class JobSheetDetailsScreen extends StatelessWidget {
  final JobSheet jobSheet;

  const JobSheetDetailsScreen({super.key, required this.jobSheet});

  Future<void> _openFormBrowser(BuildContext context) async {
    final urlStr = ApiEndpoints.baseUrl + jobSheet.globalDetailApiUrl;
    final url = Uri.parse(urlStr);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open form URL: $urlStr")),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          "Job Sheet: ${jobSheet.sheetNo}",
          style: const TextStyle(
            color: Color(0xFF0F2C4A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status and Actions Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          jobSheet.statusLabel.isNotEmpty ? jobSheet.statusLabel : jobSheet.status,
                          style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (jobSheet.globalDetailApiUrl.isNotEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _openFormBrowser(context),
                      icon: const Icon(Icons.open_in_browser, color: Colors.white, size: 18),
                      label: const Text("View Form in Browser", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main Details Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Core Info
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Core Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
                        const Divider(height: 32),
                        _buildDetailRow("Project", jobSheet.projectName),
                        _buildDetailRow("Client", jobSheet.clientName),
                        _buildDetailRow("Job No.", jobSheet.jobNo),
                        _buildDetailRow("Job Reference", jobSheet.jobReference),
                        _buildDetailRow("Operative", "${jobSheet.operative} (${jobSheet.operativeCode})"),
                        _buildDetailRow("Form Type", jobSheet.form),
                        _buildDetailRow("Location", jobSheet.location),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                
                // Right Column: Additional Info
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Financials & Notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
                            const Divider(height: 32),
                            _buildDetailRow("Material Cost", jobSheet.materialCost.isNotEmpty ? "£${jobSheet.materialCost}" : "-"),
                            _buildDetailRow("Charge", jobSheet.charge.isNotEmpty ? "£${jobSheet.charge}" : "-"),
                            _buildDetailRow("Comments", jobSheet.comments),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Timestamps", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
                            const Divider(height: 32),
                            _buildDetailRow("Created", jobSheet.created),
                            _buildDetailRow("Submitted", jobSheet.submitted),
                            _buildDetailRow("Last Updated", jobSheet.lastUpdated),
                          ],
                        ),
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
  }
}
