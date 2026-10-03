import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import 'job_sheet_controller.dart';
import 'job_sheet_details_screen.dart';
import 'job_sheet_webview_screen.dart';
import '../../models/job_sheet_model.dart';
import '../../core/widgets/shimmer_loading.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/background_stripes_painter.dart';

class JobSheetScreen extends StatefulWidget {
  final String title;
  final bool dailyReportsMode;

  const JobSheetScreen({
    super.key,
    this.title = "Job Sheets",
    this.dailyReportsMode = false,
  });

  @override
  State<JobSheetScreen> createState() => _JobSheetScreenState();
}

class _JobSheetScreenState extends State<JobSheetScreen> {
  final JobSheetController _controller = JobSheetController();

  @override
  void initState() {
    super.initState();
    _controller.dailyReportsMode = widget.dailyReportsMode;
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

  Future<void> _downloadProjectPdf() async {
    if (_controller.jobSheets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No job sheets to export")),
      );
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Generating Project PDF...")),
        );
      }

      final ids = _controller.jobSheets.map((e) => e.id).join(',');
      String urlStr = '${ApiEndpoints.baseUrl}/job-sheets/?ids=$ids&export=pdf';
      if (_controller.selectedProject != null && _controller.selectedProject!.isNotEmpty) {
        urlStr += '&project=${Uri.encodeComponent(_controller.selectedProject!)}';
      }
      
      final response = await ApiClient.get(urlStr);

      if (response.statusCode == 200) {
        // Check if response is JSON with a redirect/url or direct bytes
        if (response.headers['content-type']?.contains('application/json') == true) {
          try {
            final data = jsonDecode(response.body);
            if (data is Map && (data['url'] != null || data['file'] != null || data['pdf_url'] != null)) {
              final pdfUrl = data['url'] ?? data['file'] ?? data['pdf_url'];
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobSheetWebviewScreen(
                      url: pdfUrl.toString().startsWith('http')
                          ? pdfUrl.toString()
                          : '${ApiEndpoints.baseUrl}${pdfUrl.toString()}',
                      title: "Project PDF",
                    ),
                  ),
                );
              }
              return;
            }
          } catch (_) {}
        }

        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/project_job_sheets.pdf');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        await Share.shareXFiles([XFile(file.path)], text: 'Project Job Sheets PDF');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("PDF generation failed. Status: ${response.statusCode}")),
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

  void _showSearchablePickerModal({
    required BuildContext context,
    required String title,
    required String searchHint,
    required String? currentValue,
    required List<String> options,
    required Function(String?) onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF162A42) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final searchBg = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setStateModal) {
            final filteredList = options.where((item) {
              if (searchQuery.isEmpty) return true;
              return item.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.45,
              maxChildSize: 0.94,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: textSecondary, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Search Box
                      Container(
                        decoration: BoxDecoration(
                          color: searchBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          autofocus: false,
                          style: TextStyle(color: textColor, fontSize: 14),
                          onChanged: (val) {
                            setStateModal(() {
                              searchQuery = val.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: searchHint,
                            hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                            prefixIcon: Icon(IconlyLight.search, color: textSecondary, size: 18),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Options List
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: filteredList.length + 1,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                          ),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              final isSelected = currentValue == null;
                              final entityName = title.replaceAll('Find ', '').replaceAll('Filter by ', '').replaceAll('Select ', '');
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                title: Text(
                                  "All ($entityName)",
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF0D6EFD) : textColor,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: Color(0xFF0D6EFD), size: 18)
                                    : null,
                                onTap: () {
                                  onSelected(null);
                                  Navigator.pop(ctx);
                                },
                              );
                            }

                            final item = filteredList[index - 1];
                            final isSelected = currentValue == item;

                            return ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              title: Text(
                                item,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF0D6EFD) : textColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: Color(0xFF0D6EFD), size: 18)
                                  : null,
                              onTap: () {
                                onSelected(item);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddFilterMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF162A42) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  "Filter by",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(IconlyLight.folder, color: Color(0xFF0D6EFD)),
                  title: Text("Project", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  subtitle: Text(_controller.selectedProject ?? "All projects", style: TextStyle(color: textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSearchablePickerModal(
                      context: context,
                      title: "Filter by Project",
                      searchHint: "Find project...",
                      currentValue: _controller.selectedProject,
                      options: _controller.projectOptions,
                      onSelected: (val) => _controller.setFilter(
                        project: val,
                        sheetNo: _controller.selectedSheetNo,
                        client: _controller.selectedClient,
                        operative: _controller.selectedOperative,
                        form: _controller.selectedForm,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(IconlyLight.category, color: Color(0xFF0D6EFD)),
                  title: Text("Client", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  subtitle: Text(_controller.selectedClient ?? "All clients", style: TextStyle(color: textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSearchablePickerModal(
                      context: context,
                      title: "Filter by Client",
                      searchHint: "Find client...",
                      currentValue: _controller.selectedClient,
                      options: _controller.clientOptions,
                      onSelected: (val) => _controller.setFilter(
                        project: _controller.selectedProject,
                        sheetNo: _controller.selectedSheetNo,
                        client: val,
                        operative: _controller.selectedOperative,
                        form: _controller.selectedForm,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(IconlyLight.profile, color: Color(0xFF0D6EFD)),
                  title: Text("Operative", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  subtitle: Text(_controller.selectedOperative ?? "All operatives", style: TextStyle(color: textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSearchablePickerModal(
                      context: context,
                      title: "Filter by Operative",
                      searchHint: "Find operative...",
                      currentValue: _controller.selectedOperative,
                      options: _controller.operativeOptions,
                      onSelected: (val) => _controller.setFilter(
                        project: _controller.selectedProject,
                        sheetNo: _controller.selectedSheetNo,
                        client: _controller.selectedClient,
                        operative: val,
                        form: _controller.selectedForm,
                      ),
                    );
                  },
                ),
                if (!widget.dailyReportsMode)
                  ListTile(
                    leading: const Icon(IconlyLight.document, color: Color(0xFF0D6EFD)),
                    title: Text("Form", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                    subtitle: Text(_controller.selectedForm ?? "All forms", style: TextStyle(color: textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showSearchablePickerModal(
                        context: context,
                        title: "Filter by Form",
                        searchHint: "Find form...",
                        currentValue: _controller.selectedForm,
                        options: _controller.formOptions,
                        onSelected: (val) => _controller.setFilter(
                          project: _controller.selectedProject,
                          sheetNo: _controller.selectedSheetNo,
                          client: _controller.selectedClient,
                          operative: _controller.selectedOperative,
                          form: val,
                        ),
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(IconlyLight.paper, color: Color(0xFF0D6EFD)),
                  title: Text("Sheet No.", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  subtitle: Text(_controller.selectedSheetNo ?? "All sheets", style: TextStyle(color: textSecondary, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showSearchablePickerModal(
                      context: context,
                      title: "Filter by Sheet No.",
                      searchHint: "Find sheet no...",
                      currentValue: _controller.selectedSheetNo,
                      options: _controller.sheetNoOptions,
                      onSelected: (val) => _controller.setFilter(
                        project: _controller.selectedProject,
                        sheetNo: val,
                        client: _controller.selectedClient,
                        operative: _controller.selectedOperative,
                        form: _controller.selectedForm,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSelectProjectsDialog(BuildContext context) {
    _showSearchablePickerModal(
      context: context,
      title: "Select Project",
      searchHint: "Find project...",
      currentValue: _controller.selectedProject,
      options: _controller.projectOptions,
      onSelected: (val) => _controller.setFilter(
        project: val,
        sheetNo: _controller.selectedSheetNo,
        client: _controller.selectedClient,
        operative: _controller.selectedOperative,
        form: _controller.selectedForm,
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, {required String label, required String value, required VoidCallback onRemove, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D6EFD).withOpacity(0.2) : const Color(0xFFEBF5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0D6EFD).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Text(
              "$label: $value",
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0D6EFD),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: isDark ? Colors.white70 : const Color(0xFF0D6EFD)),
          ),
        ],
      ),
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
          widget.title,
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
            // Filter & Action Bar
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Filters (+ Add Filter, Status dropdown, Reset button)
                  Row(
                    children: [
                      // + Add Filter Button
                      SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            foregroundColor: isDark ? Colors.white : const Color(0xFF0F2C4A),
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => _showAddFilterMenu(context),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text("Add Filter", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Status Dropdown
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
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
                                  isExpanded: true,
                                  dropdownColor: isDark ? AppTheme.corporateBlue : Colors.white,
                                  value: _controller.selectedStatus,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  items: ['Status: All', 'Status: Submitted', 'Status: Draft']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) _controller.setStatusFilter(val);
                                  },
                                  icon: Icon(IconlyLight.arrow_down_2, size: 16, color: isDark ? Colors.white70 : Colors.grey),
                                );
                              }
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Reset Button
                      SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => _controller.clearFilters(),
                          icon: const Icon(Icons.refresh, size: 15),
                          label: const Text("Reset", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),

                  // Active Filter Pills
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final hasProject = _controller.selectedProject != null && _controller.selectedProject!.isNotEmpty;
                      final hasClient = _controller.selectedClient != null && _controller.selectedClient!.isNotEmpty;
                      final hasOperative = _controller.selectedOperative != null && _controller.selectedOperative!.isNotEmpty;
                      final hasForm = _controller.selectedForm != null && _controller.selectedForm!.isNotEmpty;
                      final hasSheetNo = _controller.selectedSheetNo != null && _controller.selectedSheetNo!.isNotEmpty;

                      if (!hasProject && !hasClient && !hasOperative && !hasForm && !hasSheetNo) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (hasProject)
                                _buildFilterChip(
                                  context,
                                  label: "Project",
                                  value: _controller.selectedProject!,
                                  onRemove: () => _controller.setFilter(
                                    project: null,
                                    sheetNo: _controller.selectedSheetNo,
                                    client: _controller.selectedClient,
                                    operative: _controller.selectedOperative,
                                    form: _controller.selectedForm,
                                  ),
                                  onTap: () => _showSearchablePickerModal(
                                    context: context,
                                    title: "Filter by Project",
                                    searchHint: "Find project...",
                                    currentValue: _controller.selectedProject,
                                    options: _controller.projectOptions,
                                    onSelected: (val) => _controller.setFilter(
                                      project: val,
                                      sheetNo: _controller.selectedSheetNo,
                                      client: _controller.selectedClient,
                                      operative: _controller.selectedOperative,
                                      form: _controller.selectedForm,
                                    ),
                                  ),
                                ),
                              if (hasClient)
                                _buildFilterChip(
                                  context,
                                  label: "Client",
                                  value: _controller.selectedClient!,
                                  onRemove: () => _controller.setFilter(
                                    project: _controller.selectedProject,
                                    sheetNo: _controller.selectedSheetNo,
                                    client: null,
                                    operative: _controller.selectedOperative,
                                    form: _controller.selectedForm,
                                  ),
                                  onTap: () => _showSearchablePickerModal(
                                    context: context,
                                    title: "Filter by Client",
                                    searchHint: "Find client...",
                                    currentValue: _controller.selectedClient,
                                    options: _controller.clientOptions,
                                    onSelected: (val) => _controller.setFilter(
                                      project: _controller.selectedProject,
                                      sheetNo: _controller.selectedSheetNo,
                                      client: val,
                                      operative: _controller.selectedOperative,
                                      form: _controller.selectedForm,
                                    ),
                                  ),
                                ),
                              if (hasOperative)
                                _buildFilterChip(
                                  context,
                                  label: "Operative",
                                  value: _controller.selectedOperative!,
                                  onRemove: () => _controller.setFilter(
                                    project: _controller.selectedProject,
                                    sheetNo: _controller.selectedSheetNo,
                                    client: _controller.selectedClient,
                                    operative: null,
                                    form: _controller.selectedForm,
                                  ),
                                  onTap: () => _showSearchablePickerModal(
                                    context: context,
                                    title: "Filter by Operative",
                                    searchHint: "Find operative...",
                                    currentValue: _controller.selectedOperative,
                                    options: _controller.operativeOptions,
                                    onSelected: (val) => _controller.setFilter(
                                      project: _controller.selectedProject,
                                      sheetNo: _controller.selectedSheetNo,
                                      client: _controller.selectedClient,
                                      operative: val,
                                      form: _controller.selectedForm,
                                    ),
                                  ),
                                ),
                              if (hasForm)
                                _buildFilterChip(
                                  context,
                                  label: "Form",
                                  value: _controller.selectedForm!,
                                  onRemove: () => _controller.setFilter(
                                    project: _controller.selectedProject,
                                    sheetNo: _controller.selectedSheetNo,
                                    client: _controller.selectedClient,
                                    operative: _controller.selectedOperative,
                                    form: null,
                                  ),
                                  onTap: () => _showSearchablePickerModal(
                                    context: context,
                                    title: "Filter by Form",
                                    searchHint: "Find form...",
                                    currentValue: _controller.selectedForm,
                                    options: _controller.formOptions,
                                    onSelected: (val) => _controller.setFilter(
                                      project: _controller.selectedProject,
                                      sheetNo: _controller.selectedSheetNo,
                                      client: _controller.selectedClient,
                                      operative: _controller.selectedOperative,
                                      form: val,
                                    ),
                                  ),
                                ),
                              if (hasSheetNo)
                                _buildFilterChip(
                                  context,
                                  label: "Sheet No",
                                  value: _controller.selectedSheetNo!,
                                  onRemove: () => _controller.setFilter(
                                    project: _controller.selectedProject,
                                    sheetNo: null,
                                    client: _controller.selectedClient,
                                    operative: _controller.selectedOperative,
                                    form: _controller.selectedForm,
                                  ),
                                  onTap: () => _showSearchablePickerModal(
                                    context: context,
                                    title: "Filter by Sheet No.",
                                    searchHint: "Find sheet no...",
                                    currentValue: _controller.selectedSheetNo,
                                    options: _controller.sheetNoOptions,
                                    onSelected: (val) => _controller.setFilter(
                                      project: _controller.selectedProject,
                                      sheetNo: val,
                                      client: _controller.selectedClient,
                                      operative: _controller.selectedOperative,
                                      form: _controller.selectedForm,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Row 3: Action Buttons (Select Projects, Project PDF, Get Report)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Select Projects Button
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            final isProjectSelected = _controller.selectedProject != null && _controller.selectedProject!.isNotEmpty;
                            return SizedBox(
                              height: 36,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  foregroundColor: isProjectSelected ? const Color(0xFF0D6EFD) : (isDark ? Colors.white : const Color(0xFF0F2C4A)),
                                  side: BorderSide(
                                    color: isProjectSelected ? const Color(0xFF0D6EFD) : (isDark ? Colors.white24 : Colors.grey.shade300),
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: () => _showSelectProjectsDialog(context),
                                icon: Icon(
                                  isProjectSelected ? Icons.folder : IconlyLight.folder,
                                  size: 16,
                                  color: isProjectSelected ? const Color(0xFF0D6EFD) : (isDark ? Colors.white70 : Colors.black54),
                                ),
                                label: Text(
                                  isProjectSelected ? _controller.selectedProject! : "Select Projects",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),

                        // Project PDF Button
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: _downloadProjectPdf,
                            icon: const Icon(IconlyLight.download, color: Colors.white, size: 16),
                            label: const Text(
                              "Project PDF",
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Get Report Button
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6EFD),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: _downloadReport,
                            icon: const Icon(IconlyLight.paper, color: Colors.white, size: 16),
                            label: const Text(
                              "Get Report",
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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
                  Widget content;
                  if (_controller.isLoading && _controller.jobSheets.isEmpty) {
                    content = const ShimmerLoadingList(key: ValueKey('loading'));
                  } else if (_controller.errorMessage != null && _controller.jobSheets.isEmpty) {
                    content = Center(
                      key: const ValueKey('error'),
                      child: Text(_controller.errorMessage!, style: const TextStyle(color: Colors.red)),
                    );
                  } else if (_controller.jobSheets.isEmpty) {
                    content = const Center(
                      key: ValueKey('empty'),
                      child: Text("No job sheets found.", style: TextStyle(color: Colors.grey)),
                    );
                  } else {
                    content = ListView.builder(
                      key: const ValueKey('list'),
                      itemCount: _controller.jobSheets.length,
                      itemBuilder: (context, index) {
                        final sheet = _controller.jobSheets[index];
                        final isCompleted = sheet.statusLabel.toLowerCase().contains("completed") || sheet.status.toLowerCase().contains("completed");
                        
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        final cardColor = isDark ? const Color(0xFF162A42) : Colors.white;
                        final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
                        final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
                        final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Sheet No and Status Pill
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sheet.sheetNo,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isCompleted
                                            ? Colors.green.withOpacity(0.3)
                                            : Colors.orange.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isCompleted ? Icons.check_circle_outline : Icons.access_time_rounded,
                                          size: 13,
                                          color: isCompleted ? const Color(0xFF047857) : const Color(0xFFC2410C),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          sheet.statusLabel.isNotEmpty ? sheet.statusLabel : sheet.status,
                                          style: TextStyle(
                                            color: isCompleted ? const Color(0xFF047857) : const Color(0xFFC2410C),
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
                                sheet.projectName.isNotEmpty ? sheet.projectName : "General Project",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
                              const SizedBox(height: 14),
                              
                              // Details Grid: Client, Operative, Operative Code, Form
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Column 1: Client & Operative Code
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailItem("CLIENT", sheet.clientName.isNotEmpty ? sheet.clientName : "-"),
                                        const SizedBox(height: 14),
                                        _buildDetailItem("OPERATIVE CODE", sheet.operativeCode.isNotEmpty ? sheet.operativeCode : "-"),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Column 2: Operative & Form
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildOperativeItem(sheet.operative.isNotEmpty ? sheet.operative : "-"),
                                        const SizedBox(height: 14),
                                        _buildFormItem(sheet.form.isNotEmpty ? sheet.form : "-"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
                              const SizedBox(height: 14),
                              
                              // Timestamps Section: Created, Submitted, Last Updated
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(IconlyLight.calendar, size: 13, color: textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Created: ",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
                                      ),
                                      Expanded(
                                        child: Text(
                                          sheet.created.isNotEmpty ? sheet.created : "-",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (sheet.submitted.isNotEmpty && sheet.submitted != '-') ...[
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(IconlyLight.send, size: 13, color: textSecondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Submitted: ",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
                                        ),
                                        Expanded(
                                          child: Text(
                                            sheet.submitted,
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Icon(IconlyLight.time_circle, size: 13, color: textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Last Updated: ",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
                                      ),
                                      Expanded(
                                        child: Text(
                                          sheet.lastUpdated.isNotEmpty ? sheet.lastUpdated : "-",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Actions Row: PDF and View Details
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // PDF Action Button
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark ? Colors.white : const Color(0xFF0D6EFD),
                                      side: BorderSide(
                                        color: isDark ? Colors.white24 : const Color(0xFF0D6EFD).withOpacity(0.3),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _openPdfOrForm(context, sheet),
                                    icon: const Icon(IconlyLight.document, size: 14),
                                    label: const Text(
                                      "PDF",
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // View Details Button
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D6EFD),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => JobSheetDetailsScreen(jobSheet: sheet),
                                        ),
                                      );
                                    },
                                    icon: const Icon(IconlyLight.show, size: 14, color: Colors.white),
                                    label: const Text(
                                      "View Details",
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                }
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: content,
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

  void _openPdfOrForm(BuildContext context, JobSheet sheet) {
    String path = sheet.viewFormInBrowserUrl.isNotEmpty
        ? sheet.viewFormInBrowserUrl
        : (sheet.formHtmlUrl.isNotEmpty ? sheet.formHtmlUrl : sheet.globalDetailApiUrl);

    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF/Form not available for this job sheet")),
      );
      return;
    }

    String base = ApiEndpoints.baseUrl;
    if (path.startsWith('/api/') && base.endsWith('/api')) {
      base = base.substring(0, base.length - 4);
    }

    final urlStr = path.startsWith('http') ? path : base + path;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobSheetWebviewScreen(
          url: urlStr,
          title: "PDF / Form: ${sheet.sheetNo}",
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool isBold = false, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black54;
    final valueColor = color ?? (isDark ? Colors.white : const Color(0xFF0F2C4A));

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
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
            height: 1.25,
          ),
          softWrap: true,
        ),
      ],
    );
  }

  Widget _buildOperativeItem(String operative) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black54;
    final valueColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: isDark ? Colors.white10 : Colors.blue.shade50,
              child: Icon(IconlyLight.profile, size: 13, color: isDark ? Colors.white : const Color(0xFF0D6EFD)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                operative,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                  height: 1.25,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormItem(String form) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "FORM",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: labelColor,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF0D6EFD).withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(IconlyLight.paper, size: 12, color: Color(0xFF0D6EFD)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  form,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D6EFD),
                    height: 1.2,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}