import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/theme/app_theme.dart';

class JobSheetsTab extends StatelessWidget {
  final List<dynamic> jobSheets;
  final Map<String, dynamic> filterOptions;

  const JobSheetsTab({
    Key? key,
    required this.jobSheets,
    required this.filterOptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildJobSheetsFilterBar(context, filterOptions, jobSheets.length),
        Expanded(
          child: jobSheets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.folder,
                          size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text("No Job Sheets available",
                          style: TextStyle(
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  itemCount: jobSheets.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final sheet = jobSheets[index] as Map<String, dynamic>? ?? {};
                    return _buildJobSheetCard(
                      context,
                      sheetNo: sheet['sheet_no']?.toString() ?? "N/A",
                      reference: sheet['job_reference']?.toString() ??
                          sheet['job_no']?.toString() ??
                          "N/A",
                      status: sheet['status']?.toString() ?? "N/A",
                      operativeName: sheet['operative']?.toString() ?? "N/A",
                      form: sheet['form']?.toString() ?? "N/A",
                      location: sheet['location']?.toString() ?? "N/A",
                      created: sheet['created']?.toString() ?? "N/A",
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildJobSheetsFilterBar(
      BuildContext context, Map<String, dynamic> filterOptions, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.corporateBlue : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Job Sheets",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor)),
              Text("$count Sheets Found",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildFilterDropdown(
                  context, "Form", filterOptions['forms'] as List? ?? []),
              _buildFilterDropdown(
                  context, "Operative", filterOptions['operatives'] as List? ?? []),
              _buildFilterDropdown(
                  context, "Team", filterOptions['teams'] as List? ?? []),
              _buildFilterDropdown(
                  context, "Material", filterOptions['materials'] as List? ?? []),
              ElevatedButton.icon(
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
                label: const Text("More Filters",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(BuildContext context, String label, List<dynamic> options) {
    if (options.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ensure unique values to prevent DropdownButton assertion failures
    final uniqueOptions = options.map((e) => e.toString()).toSet().toList();

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: isDark ? AppTheme.corporateBlue : Colors.white,
          value: null,
          hint: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87)),
          items: uniqueOptions
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
    );
  }

  Widget _buildJobSheetCard(
    BuildContext context, {
    required String sheetNo,
    required String reference,
    required String status,
    required String operativeName,
    required String form,
    required String location,
    required String created,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final isCompleted = status.toLowerCase() == 'approved' ||
        status.toLowerCase() == 'completed' ||
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
                    child: Icon(IconlyLight.paper,
                        color: isDark ? Colors.white : const Color(0xFF0D6EFD), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Sheet #$sheetNo",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor)),
                      const SizedBox(height: 2),
                      Text("Ref: $reference",
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
                child: _buildInfoColumn(
                    context, "LOCATION", location, IconlyLight.location),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Created: $created",
                  style: TextStyle(color: textSecondary, fontSize: 12)),
              Row(
                children: [
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
