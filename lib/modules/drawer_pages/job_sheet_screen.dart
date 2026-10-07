import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import 'job_sheet_controller.dart';
import 'job_sheet_details_screen.dart';
import 'job_sheet_webview_screen.dart';
import '../../models/job_sheet_model.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_helper.dart';
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
  static const MethodChannel _downloadsChannel = MethodChannel(
    'com.euroside.siteflow_admin/downloads',
  );

  Future<String?> _savePdfToDownloads(List<int> bytes, String fileName) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _downloadsChannel.invokeMethod<String>('savePdf', {
        'bytes': bytes,
        'fileName': fileName,
      });
    } on PlatformException {
      return null;
    }
  }

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

  Future<void> _downloadJobSheetPdf(JobSheet sheet) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Downloading PDF for ${sheet.sheetNo.isNotEmpty ? sheet.sheetNo : 'Job Sheet'}..."),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final urlStr = '${ApiEndpoints.baseUrl}/job-sheets/?ids=${sheet.id}&export=pdf';
      final response = await ApiClient.get(urlStr);

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final contentType = response.headers['content-type'] ?? '';
        final isPdfBinary = contentType.contains('application/pdf') ||
            (response.bodyBytes.length >= 4 &&
                response.bodyBytes[0] == 0x25 && // %
                response.bodyBytes[1] == 0x50 && // P
                response.bodyBytes[2] == 0x44 && // D
                response.bodyBytes[3] == 0x46);   // F

        if (isPdfBinary) {
          final directory = await getTemporaryDirectory();
          final fileName = 'job_sheet_${sheet.sheetNo.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pdf';
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }

          await Share.shareXFiles([XFile(file.path)], text: 'Job Sheet ${sheet.sheetNo} PDF');
          return;
        }
      }

      // Fallback: If viewFormInBrowserUrl or globalDetailApiUrl is available, open form in in-app webview
      String path = sheet.viewFormInBrowserUrl.isNotEmpty
          ? sheet.viewFormInBrowserUrl
          : sheet.globalDetailApiUrl;

      if (path.isNotEmpty) {
        String base = ApiEndpoints.baseUrl;
        if (path.startsWith('/api/') && base.endsWith('/api')) {
          base = base.substring(0, base.length - 4);
        }
        final fullUrl = base + path;
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobSheetWebviewScreen(
                url: fullUrl,
                title: "PDF / Form: ${sheet.sheetNo}",
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("PDF is not available for this job sheet.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening PDF: $e")),
        );
      }
    }
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
        const SnackBar(content: Text("No job sheets available to export Project PDF")),
      );
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Downloading Project PDF..."),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final ids = _controller.jobSheets.map((e) => e.id).join(',');
      List<String> queryParams = [];
      if (_controller.selectedProject != null && _controller.selectedProject!.isNotEmpty) {
        queryParams.add('project=${Uri.encodeComponent(_controller.selectedProject!)}');
      }
      queryParams.add('ids=$ids');
      queryParams.add('export=pdf');

      final urlStr = '${ApiEndpoints.baseUrl}/job-sheets/?${queryParams.join('&')}';
      final response = await ApiClient.get(urlStr);

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final contentType = response.headers['content-type'] ?? '';
        final isPdfBinary = contentType.contains('application/pdf') ||
            (response.bodyBytes.length >= 4 &&
                response.bodyBytes[0] == 0x25 && // %
                response.bodyBytes[1] == 0x50 && // P
                response.bodyBytes[2] == 0x44 && // D
                response.bodyBytes[3] == 0x46);   // F

        if (isPdfBinary) {
          final directory = await getTemporaryDirectory();
          final projName = _controller.selectedProject != null && _controller.selectedProject!.isNotEmpty
              ? _controller.selectedProject!.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
              : 'all_projects';
          final file = File('${directory.path}/project_pdf_$projName.pdf');
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            final savedLocation = await _savePdfToDownloads(
              response.bodyBytes,
              'project_pdf_$projName.pdf',
            );
            if (!mounted) return;
            if (savedLocation != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Project PDF saved in Downloads/Euroside')),
              );
            } else {
              // iOS/desktop and older Android versions use the system save
              // sheet when public Downloads storage is unavailable.
              await Share.shareXFiles([XFile(file.path)], text: 'Project PDF: ${widget.title}');
            }
          }
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Project PDF could not be downloaded (Status: ${response.statusCode})")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error downloading Project PDF: $e")),
        );
      }
    }
  }

  List<String> _getFilterOptions(String key) {
    final options = _controller.filterOptions;
    List<String> items = [];
    if (options[key] is List) {
      items = (options[key] as List)
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Fallback or augment with distinct values from current job sheets if needed
    if (items.isEmpty) {
      if (key == 'projects') {
        items = _controller.jobSheets
            .map((s) => s.projectName.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
      } else if (key == 'clients') {
        items = _controller.jobSheets
            .map((s) => s.clientName.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
      } else if (key == 'operatives') {
        items = _controller.jobSheets
            .map((s) => s.operative.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
      } else if (key == 'forms') {
        items = _controller.jobSheets
            .map((s) => s.form.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
      } else if (key == 'sheet_nos') {
        items = _controller.jobSheets
            .map((s) => s.sheetNo.trim())
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList();
      }
    }

    items.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return items;
  }

  void _showSearchableFilterSelector({
    required String title,
    required String filterKey,
    required String searchHint,
    required String? currentValue,
    required Function(String?) onApply,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allOptions = _getFilterOptions(filterKey);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        String searchQuery = '';
        String? selectedVal = currentValue;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredOptions = allOptions.where((opt) {
              if (searchQuery.isEmpty) return true;
              return opt.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${allOptions.length} available",
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                          onPressed: () => Navigator.pop(bottomSheetContext),
                        ),
                      ],
                    ),
                  ),

                  Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),

                  // Search Field
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                        ),
                      ),
                      child: TextField(
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            IconlyLight.search,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                            size: 20,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                  onPressed: () {
                                    setModalState(() {
                                      searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                    ),
                  ),

                  // Options List
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // "All" option (to clear this filter)
                        if (searchQuery.isEmpty)
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setModalState(() {
                                selectedVal = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: selectedVal == null
                                    ? (isDark ? Colors.white12 : const Color(0xFF0D6EFD).withValues(alpha: 0.1))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedVal == null
                                      ? const Color(0xFF0D6EFD)
                                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.all_inclusive,
                                    size: 18,
                                    color: selectedVal == null
                                        ? const Color(0xFF0D6EFD)
                                        : (isDark ? Colors.white60 : Colors.grey),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "All $title (Clear Filter)",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: selectedVal == null ? FontWeight.bold : FontWeight.normal,
                                        color: selectedVal == null
                                            ? (isDark ? Colors.white : const Color(0xFF0D6EFD))
                                            : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                  ),
                                  if (selectedVal == null)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF0D6EFD),
                                      size: 18,
                                    ),
                                ],
                              ),
                            ),
                          ),

                        if (filteredOptions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                "No matches found for \"$searchQuery\"",
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          ...filteredOptions.map((opt) {
                            final isSelected = selectedVal == opt;
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setModalState(() {
                                  selectedVal = opt;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? Colors.white12 : const Color(0xFF0D6EFD).withValues(alpha: 0.1))
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF0D6EFD)
                                        : (isDark ? Colors.white10 : Colors.grey.shade200),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        opt,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected
                                              ? (isDark ? Colors.white : const Color(0xFF0D6EFD))
                                              : (isDark ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF0D6EFD),
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkSurface : Colors.white,
                      border: Border(
                        top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                            ),
                            onPressed: () => Navigator.pop(bottomSheetContext),
                            child: Text(
                              "Cancel",
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6EFD),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Navigator.pop(bottomSheetContext);
                              onApply(selectedVal);
                            },
                            child: const Text(
                              "Apply",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openFilterForKey(String key, String title, String hint) {
    String? currentVal;
    if (key == 'projects') currentVal = _controller.selectedProject;
    if (key == 'clients') currentVal = _controller.selectedClient;
    if (key == 'operatives') currentVal = _controller.selectedOperative;
    if (key == 'forms') currentVal = _controller.selectedForm;
    if (key == 'sheet_nos') currentVal = _controller.selectedSheetNo;

    _showSearchableFilterSelector(
      title: title,
      filterKey: key,
      searchHint: hint,
      currentValue: currentVal,
      onApply: (newVal) {
        _controller.setFilter(
          project: key == 'projects' ? newVal : _controller.selectedProject,
          client: key == 'clients' ? newVal : _controller.selectedClient,
          operative: key == 'operatives' ? newVal : _controller.selectedOperative,
          form: key == 'forms' ? newVal : _controller.selectedForm,
          sheetNo: key == 'sheet_nos' ? newVal : _controller.selectedSheetNo,
        );
      },
    );
  }

  void _showAddFilterMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filterTypes = [
      {'key': 'projects', 'title': 'Project', 'icon': IconlyLight.work, 'hint': 'Find project'},
      {'key': 'clients', 'title': 'Client', 'icon': IconlyLight.profile, 'hint': 'Find client'},
      {'key': 'operatives', 'title': 'Operative', 'icon': IconlyLight.user, 'hint': 'Find operative'},
      if (!widget.dailyReportsMode)
        {'key': 'forms', 'title': 'Form', 'icon': IconlyLight.document, 'hint': 'Find form'},
      {'key': 'sheet_nos', 'title': 'Sheet No.', 'icon': Icons.tag, 'hint': 'Find sheet'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, -4),
              ),
            ],
          ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "Filter by",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...filterTypes.map((item) {
                final String key = item['key'] as String;
                final String title = item['title'] as String;
                final IconData icon = item['icon'] as IconData;
                final String hint = item['hint'] as String;

                String? currentVal;
                if (key == 'projects') currentVal = _controller.selectedProject;
                if (key == 'clients') currentVal = _controller.selectedClient;
                if (key == 'operatives') currentVal = _controller.selectedOperative;
                if (key == 'forms') currentVal = _controller.selectedForm;
                if (key == 'sheet_nos') currentVal = _controller.selectedSheetNo;

                final hasValue = currentVal != null && currentVal.isNotEmpty;

                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  leading: Icon(
                    icon,
                    color: hasValue ? const Color(0xFF0D6EFD) : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: hasValue
                      ? Text(
                          currentVal,
                          style: const TextStyle(color: Color(0xFF0D6EFD), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: Icon(
                    IconlyLight.arrow_right_2,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openFilterForKey(key, title, hint);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveFilterTags(bool isDark) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final List<Widget> chips = [];

        void addTag(String label, String? value, String key, String hint) {
          if (value != null && value.isNotEmpty) {
            chips.add(
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8),
                padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0D6EFD).withValues(alpha: 0.25)
                      : const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF0D6EFD).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _openFilterForKey(key, label, hint),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "$label: ",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF0D6EFD),
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            IconlyLight.arrow_down_2,
                            size: 12,
                            color: isDark ? Colors.white70 : const Color(0xFF0D6EFD),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        _controller.setFilter(
                          project: key == 'projects' ? null : _controller.selectedProject,
                          client: key == 'clients' ? null : _controller.selectedClient,
                          operative: key == 'operatives' ? null : _controller.selectedOperative,
                          form: key == 'forms' ? null : _controller.selectedForm,
                          sheetNo: key == 'sheet_nos' ? null : _controller.selectedSheetNo,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }

        addTag("Project", _controller.selectedProject, "projects", "Find project");
        addTag("Client", _controller.selectedClient, "clients", "Find client");
        addTag("Operative", _controller.selectedOperative, "operatives", "Find operative");
        if (!widget.dailyReportsMode) {
          addTag("Form", _controller.selectedForm, "forms", "Find form");
        }
        addTag("Sheet No.", _controller.selectedSheetNo, "sheet_nos", "Find sheet");

        if (chips.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: chips),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
            // Filter Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // + Add Filter Button
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _showAddFilterMenu(context),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.white,
                                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 16, color: isDark ? Colors.white : Colors.black87),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Add Filter",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(IconlyLight.arrow_down_2, size: 14, color: isDark ? Colors.white70 : Colors.grey),
                                ],
                              ),
                            ),
                          ),

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
                                  final statusList = const [
                                    'Status: All',
                                    'Status: In Progress',
                                    'Status: Submitted',
                                    'Status: In Review',
                                    'Status: Approved',
                                    'Status: Rejected',
                                    'Status: Archived',
                                  ];
                                  final currentVal = statusList.contains(_controller.selectedStatus)
                                      ? _controller.selectedStatus
                                      : 'Status: All';

                                  return DropdownButton<String>(
                                    dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                                    value: currentVal,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                    items: statusList
                                        .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(
                                                e,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) _controller.setStatusFilter(val);
                                    },
                                    icon: Icon(IconlyLight.arrow_down_2, size: 16, color: isDark ? Colors.white70 : Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),

                          // Reset Button
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _controller.clearFilters(),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade100,
                                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh, size: 16, color: isDark ? Colors.white70 : Colors.black87),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Reset",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Select Projects Button
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _openFilterForKey('projects', 'Project', 'Find project'),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade100,
                                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(IconlyLight.folder, size: 16, color: isDark ? Colors.white70 : Colors.black87),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Select Projects",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Project PDF Button
                          SizedBox(
                            height: 36,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D6EFD),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onPressed: _downloadProjectPdf,
                              icon: const Icon(IconlyLight.document, color: Colors.white, size: 16),
                              label: const Text("Project PDF", style: TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                          ),

                          // Get Report Button
                          SizedBox(
                            height: 36,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D6EFD),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onPressed: _downloadReport,
                              icon: const Icon(IconlyLight.paper, color: Colors.white, size: 16),
                              label: const Text("Get Report", style: TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Active Filter Tags Row
                  _buildActiveFilterTags(isDark),
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
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (_controller.errorMessage != null && _controller.jobSheets.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _controller.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0D6EFD),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _controller.fetchJobSheets(),
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      ),
                    );
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
                      final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
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
                              color: Colors.black.withValues(alpha: 0.02),
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
                                    "Created: ${DateHelper.formatToLocal(sheet.created)}",
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(IconlyLight.time_circle, size: 12, color: textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Updated: ${DateHelper.formatToLocal(sheet.lastUpdated)}",
                                        style: TextStyle(fontSize: 12, color: textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // PDF Action Button
                                        InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () => _downloadJobSheetPdf(sheet),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.red.withValues(alpha: 0.15)
                                                  : Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isDark
                                                    ? Colors.red.withValues(alpha: 0.3)
                                                    : Colors.red.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  IconlyLight.document,
                                                  size: 14,
                                                  color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  "PDF",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),

                                        // View Details Button
                                        InkWell(
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
                                              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF0D6EFD).withValues(alpha: 0.1),
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
          softWrap: true,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: isDark ? Colors.white10 : Colors.blue.shade50,
                child: Icon(IconlyLight.profile, size: 14, color: isDark ? Colors.white : Colors.blue),
              ),
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
                softWrap: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
