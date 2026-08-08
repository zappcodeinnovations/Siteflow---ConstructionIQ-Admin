import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/job_sheet_model.dart';
import '../../core/network/api_endpoints.dart';
import 'package:iconly/iconly.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';
import 'job_sheet_webview_screen.dart';

class JobSheetDetailsScreen extends StatelessWidget {
  final JobSheet jobSheet;

  const JobSheetDetailsScreen({super.key, required this.jobSheet});

  void _openFormBrowser(BuildContext context) {
    String path = jobSheet.viewFormInBrowserUrl.isNotEmpty 
        ? jobSheet.viewFormInBrowserUrl
        : jobSheet.globalDetailApiUrl;
    
    String base = ApiEndpoints.baseUrl;
    if (path.startsWith('/api/') && base.endsWith('/api')) {
      base = base.substring(0, base.length - 4);
    }
    
    final urlStr = base + path;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobSheetWebviewScreen(
          url: urlStr,
          title: "Form: ${jobSheet.sheetNo}",
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
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
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.corporateBlue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white : const Color(0xFF0F2C4A)
            )
          ),
          Divider(height: 32, color: isDark ? Colors.white24 : Colors.grey.shade200),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.corporateBlue : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppTheme.corporateBlue : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          "Job Sheet: ${jobSheet.sheetNo}",
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F2C4A),
            fontSize: 20,
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status and Actions Card
                Container(
                  padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.corporateBlue : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(IconlyLight.tick_square, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          jobSheet.statusLabel.isNotEmpty ? jobSheet.statusLabel : jobSheet.status,
                          style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (jobSheet.viewFormInBrowserUrl.isNotEmpty || jobSheet.globalDetailApiUrl.isNotEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _openFormBrowser(context),
                      icon: const Icon(IconlyLight.document, color: Colors.white, size: 18),
                      label: const Text("View Form", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Main Details Row / Column depending on screen size
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSectionCard(
                      title: "Core Information",
                      isDark: isDark,
                      children: [
                        _buildDetailRow("Project", jobSheet.projectName, isDark),
                        _buildDetailRow("Client", jobSheet.clientName, isDark),
                        _buildDetailRow("Job No.", jobSheet.jobNo, isDark),
                        _buildDetailRow("Job Reference", jobSheet.jobReference, isDark),
                        _buildDetailRow("Operative", "${jobSheet.operative} (${jobSheet.operativeCode})", isDark),
                        _buildDetailRow("Form Type", jobSheet.form, isDark),
                        _buildDetailRow("Location", jobSheet.location, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSectionCard(
                          title: "Financials & Notes",
                          isDark: isDark,
                          children: [
                            _buildDetailRow("Material Cost", jobSheet.materialCost.isNotEmpty ? "£${jobSheet.materialCost}" : "-", isDark),
                            _buildDetailRow("Charge", jobSheet.charge.isNotEmpty ? "£${jobSheet.charge}" : "-", isDark),
                            _buildDetailRow("Comments", jobSheet.comments, isDark),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionCard(
                          title: "Timestamps",
                          isDark: isDark,
                          children: [
                            _buildDetailRow("Created", jobSheet.created, isDark),
                            _buildDetailRow("Submitted", jobSheet.submitted, isDark),
                            _buildDetailRow("Last Updated", jobSheet.lastUpdated, isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildSectionCard(
                    title: "Core Information",
                    isDark: isDark,
                    children: [
                      _buildDetailRow("Project", jobSheet.projectName, isDark),
                      _buildDetailRow("Client", jobSheet.clientName, isDark),
                      _buildDetailRow("Job No.", jobSheet.jobNo, isDark),
                      _buildDetailRow("Job Reference", jobSheet.jobReference, isDark),
                      _buildDetailRow("Operative", "${jobSheet.operative} (${jobSheet.operativeCode})", isDark),
                      _buildDetailRow("Form Type", jobSheet.form, isDark),
                      _buildDetailRow("Location", jobSheet.location, isDark),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: "Financials & Notes",
                    isDark: isDark,
                    children: [
                      _buildDetailRow("Material Cost", jobSheet.materialCost.isNotEmpty ? "£${jobSheet.materialCost}" : "-", isDark),
                      _buildDetailRow("Charge", jobSheet.charge.isNotEmpty ? "£${jobSheet.charge}" : "-", isDark),
                      _buildDetailRow("Comments", jobSheet.comments, isDark),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: "Timestamps",
                    isDark: isDark,
                    children: [
                      _buildDetailRow("Created", jobSheet.created, isDark),
                      _buildDetailRow("Submitted", jobSheet.submitted, isDark),
                      _buildDetailRow("Last Updated", jobSheet.lastUpdated, isDark),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}