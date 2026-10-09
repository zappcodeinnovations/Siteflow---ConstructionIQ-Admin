import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_helper.dart';
import '../../../models/hse_document_model.dart';
import '../project_hse_controller.dart';

class HseTab extends StatefulWidget {
  final int projectId;
  const HseTab({super.key, required this.projectId});

  @override
  State<HseTab> createState() => _HseTabState();
}

class _HseTabState extends State<HseTab> {
  late final ProjectHseController _controller = ProjectHseController(widget.projectId);
  String _categoryFilter = 'All';

  static const _categories = [
    'All',
    'rams',
    'toolbox_talk',
    'site_induction',
    'permit_to_work',
    'certificate',
    'training',
    'other',
  ];

  static const _categoryLabels = {
    'All': 'All',
    'rams': 'RAMS',
    'toolbox_talk': 'Toolbox Talk',
    'site_induction': 'Site Induction',
    'permit_to_work': 'Permit to Work',
    'certificate': 'Certificate',
    'training': 'Training',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    _controller.fetchDocuments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizeCategory(String? raw) {
    if (raw == null) return 'other';
    final lower = raw.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    if (lower == 'toolbox_talk' || lower == 'toolbox_talks' || lower == 'toolboxtalk') return 'toolbox_talk';
    if (lower == 'site_induction' || lower == 'site_inductions' || lower == 'induction' || lower == 'inductions') return 'site_induction';
    if (lower == 'permit_to_work' || lower == 'permit' || lower == 'permits' || lower == 'permit_work') return 'permit_to_work';
    if (lower == 'rams') return 'rams';
    if (lower == 'certificate' || lower == 'certificates' || lower == 'certification') return 'certificate';
    if (lower == 'training' || lower == 'trainings') return 'training';
    if (lower == 'other' || lower == 'others') return 'other';
    return lower;
  }

  String _formatSubmissionDate(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw == 'null' || raw == '-') return '';
    return DateHelper.formatToLocal(raw, includeTime: true);
  }

  String _formatExpiryDate(String? raw) {
    if (raw == null || raw.trim().isEmpty || raw == 'null' || raw == '-') return '';
    try {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return DateFormat('dd MMM yyyy').format(parsed);
      }
    } catch (_) {}
    return DateHelper.formatDate(raw);
  }

  void _showUploadDialog() {
    String selectedCategory = 'rams';
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedExpiry;
    PlatformFile? selectedFile;
    bool requireSign = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? AppTheme.darkSurface : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
            final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Upload HS&E Document",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Category
                    Text("Category *", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          dropdownColor: bg,
                          items: _categories.where((c) => c != 'All').map((c) {
                            return DropdownMenuItem<String>(
                              value: c,
                              child: Text(_categoryLabels[c] ?? c, style: TextStyle(color: textColor, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text("Title", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Leave blank to use file name",
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Expiry Date
                    Text("Expiry Date", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedExpiry ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setModalState(() => selectedExpiry = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedExpiry != null ? DateFormat('dd-MM-yyyy').format(selectedExpiry!) : "dd-mm-yyyy",
                              style: TextStyle(
                                color: selectedExpiry != null ? textColor : (isDark ? Colors.white38 : Colors.grey.shade400),
                                fontSize: 14,
                              ),
                            ),
                            Icon(IconlyLight.calendar, size: 18, color: isDark ? Colors.white70 : Colors.grey.shade600),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // File picker
                    Text("Files *", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(withData: false);
                        if (result != null && result.files.isNotEmpty) {
                          setModalState(() {
                            selectedFile = result.files.first;
                            if (titleController.text.trim().isEmpty) {
                              titleController.text = selectedFile!.name;
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("Choose Files", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedFile != null ? selectedFile!.name : "No file chosen",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selectedFile != null ? textColor : (isDark ? Colors.white38 : Colors.grey.shade500),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    Text("Notes", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Optional notes",
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Require sign switch
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: requireSign,
                      onChanged: (val) => setModalState(() => requireSign = val ?? false),
                      title: Text(
                        "Require every assigned worker to read & sign this document",
                        style: TextStyle(fontSize: 13, color: textColor),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),

                    // Submit
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (selectedFile == null || selectedFile!.path == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please select a file to upload."), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              setModalState(() => isSubmitting = true);
                              final success = await _controller.uploadDocument(
                                category: selectedCategory,
                                title: titleController.text.trim().isNotEmpty ? titleController.text.trim() : selectedFile!.name,
                                filePath: selectedFile!.path!,
                                expiryDate: selectedExpiry != null ? DateFormat('yyyy-MM-dd').format(selectedExpiry!) : null,
                                notes: notesController.text.trim(),
                                requireSign: requireSign,
                              );
                              if (!context.mounted) return;
                              if (success) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("HS&E Document uploaded successfully."), backgroundColor: Colors.green),
                                );
                              } else {
                                setModalState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Failed to upload HS&E Document."), backgroundColor: Colors.red),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Upload Documents", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReviseDialog(HseDocumentModel doc) {
    String selectedCategory = _normalizeCategory(doc.category);
    final titleController = TextEditingController(text: doc.title);
    final notesController = TextEditingController();
    DateTime? selectedExpiry = doc.expiryDate != null ? DateTime.tryParse(doc.expiryDate!) : null;
    PlatformFile? selectedFile;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? AppTheme.darkSurface : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
            final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Revise Document: ${doc.title}",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // File picker
                    Text("Replacement File *", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(withData: false);
                        if (result != null && result.files.isNotEmpty) {
                          setModalState(() {
                            selectedFile = result.files.first;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("Choose File", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedFile != null ? selectedFile!.name : "No replacement file chosen",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selectedFile != null ? textColor : (isDark ? Colors.white38 : Colors.grey.shade500),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Revision Notes
                    Text("Revision Notes", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Reason for revision",
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (selectedFile == null || selectedFile!.path == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please select a replacement file."), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              setModalState(() => isSubmitting = true);
                              final success = await _controller.reviseDocument(
                                docId: doc.id,
                                category: selectedCategory,
                                title: titleController.text.trim().isNotEmpty ? titleController.text.trim() : doc.title,
                                filePath: selectedFile!.path!,
                                expiryDate: selectedExpiry != null ? DateFormat('yyyy-MM-dd').format(selectedExpiry) : doc.expiryDate,
                                notes: notesController.text.trim(),
                              );
                              if (!context.mounted) return;
                              if (success) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Document revised successfully."), backgroundColor: Colors.green),
                                );
                              } else {
                                setModalState(() => isSubmitting = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Failed to revise document."), backgroundColor: Colors.red),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Upload Revision", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRecycleBinDialog() {
    _controller.fetchRecycleBin();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
            final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

            return AlertDialog(
              backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(IconlyLight.delete, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Text("Recycle Bin", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: _controller.recycleBinDocuments.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text("No documents in recycle bin.", style: TextStyle(color: textSecondary, fontSize: 14)),
                        ),
                      )
                    : SizedBox(
                        height: 300,
                        child: ListView.separated(
                          itemCount: _controller.recycleBinDocuments.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final doc = _controller.recycleBinDocuments[index];
                            return ListTile(
                              leading: const Icon(IconlyLight.document),
                              title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(doc.categoryLabel),
                              trailing: TextButton(
                                onPressed: () async {
                                  final restored = await _controller.restoreDocument(doc.id);
                                  if (restored) {
                                    setDialogState(() {});
                                  }
                                },
                                child: const Text("Restore"),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Close")),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmAndDeleteDocument(HseDocumentModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Document"),
        content: Text("Are you sure you want to delete '${doc.title}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await _controller.deleteDocument(doc.id);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Document moved to Recycle Bin."), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete document."), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: _controller.fetchDocuments,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Toolbar Actions: Upload & Recycle Bin
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D6EFD),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _showUploadDialog,
                      icon: const Icon(IconlyLight.upload, size: 16),
                      label: const Text("Upload HS&E Document", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : Colors.black87,
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _showRecycleBinDialog,
                      icon: const Icon(IconlyLight.delete, size: 16),
                      label: const Text("Recycle Bin", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Warning banner if workers unacknowledged
                if (_controller.unacknowledgedWorkersCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${_controller.unacknowledgedWorkersCount} workers on site have not acknowledged the current RAMS/HS&E documents that require sign-off.",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                if (_controller.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_controller.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(_controller.error!, style: TextStyle(color: textSecondary)),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _controller.fetchDocuments, child: const Text("Retry")),
                      ],
                    ),
                  )
                else ...[
                  // Summary Category Grid (8 Categories)
                  _buildKpiGrid(textColor, textSecondary, cardColor, borderColor),
                  const SizedBox(height: 20),
                  // Documents List
                  _buildDocumentList(isDark, textColor, textSecondary, cardColor, borderColor),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiGrid(Color textColor, Color textSecondary, Color cardColor, Color borderColor) {
    final counts = <String, int>{for (final c in _categories) c: 0};
    counts['All'] = _controller.documents.length;
    for (final doc in _controller.documents) {
      final normCat = _normalizeCategory(doc.category);
      counts[normCat] = (counts[normCat] ?? 0) + 1;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        double aspectRatio = 2.0;
        if (constraints.maxWidth < 480) {
          crossAxisCount = 2;
          aspectRatio = 1.9;
        } else if (constraints.maxWidth < 750) {
          crossAxisCount = 4;
          aspectRatio = 1.9;
        } else {
          crossAxisCount = 8;
          aspectRatio = 1.8;
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: aspectRatio,
          children: _categories.map((c) {
            return _buildKpiCard(
              _categoryLabels[c] ?? c,
              '${counts[c] ?? 0}',
              isHighlighted: c == _categoryFilter,
              onTap: () => setState(() => _categoryFilter = c),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDocumentList(bool isDark, Color textColor, Color textSecondary, Color cardColor, Color borderColor) {
    final filtered = _categoryFilter == 'All'
        ? _controller.documents
        : _controller.documents.where((d) => _normalizeCategory(d.category) == _categoryFilter).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.document, size: 48, color: textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text("No HS&E documents in this category.", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              "Tap 'Upload HS&E Document' above to upload RAMS, toolbox talks, permits, certificates, and training records.",
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: filtered.map((doc) => _buildDocCard(doc, isDark, textColor, textSecondary, cardColor, borderColor)).toList(),
    );
  }

  Widget _buildDocCard(
    HseDocumentModel doc,
    bool isDark,
    Color textColor,
    Color textSecondary,
    Color cardColor,
    Color borderColor,
  ) {
    final categoryLabel = doc.categoryLabel.isNotEmpty
        ? doc.categoryLabel
        : (_categoryLabels[_normalizeCategory(doc.category)] ?? doc.category);
    final submittedDateStr = _formatSubmissionDate(doc.uploadedAt);
    final expiryDateStr = _formatExpiryDate(doc.expiryDate);

    final signedInfo = doc.signedCount != null && doc.totalSigners != null && doc.totalSigners! > 0
        ? "${doc.signedCount}/${doc.totalSigners} signed"
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Category Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  doc.title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  categoryLabel,
                  style: const TextStyle(
                    color: Color(0xFF0D6EFD),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Metadata Row: Category • Submitted Date • Expiry Date • Uploader
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (submittedDateStr.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconlyLight.calendar, size: 13, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(submittedDateStr, style: TextStyle(fontSize: 12, color: textSecondary)),
                  ],
                ),
              if (expiryDateStr.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconlyLight.time_circle, size: 13, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text("Expires $expiryDateStr", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.orange.shade300 : Colors.orange.shade800)),
                  ],
                ),
              if (doc.uploadedByName.isNotEmpty)
                Text(
                  "By ${doc.uploadedByName}${doc.revisionNumber > 1 ? ' (Rev ${doc.revisionNumber})' : ''}",
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
            ],
          ),

          if (doc.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(doc.notes, style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.85))),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Bottom Action Row: Sign status on left, Open/Revise/Delete on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Signatures / Acknowledgment indicator
              if (signedInfo != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 14, color: Color(0xFF0D6EFD)),
                      const SizedBox(width: 4),
                      Text(
                        signedInfo,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D6EFD)),
                      ),
                    ],
                  ),
                )
              else if (doc.requiresAcknowledgment)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (doc.isAcknowledged ? const Color(0xFF16A34A) : const Color(0xFFF59E0B)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    doc.isAcknowledged ? "Acknowledged" : "Acknowledgment required",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: doc.isAcknowledged ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              // Action Buttons: Open, Revise, Delete
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (doc.fileUrl.isNotEmpty)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(40, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => launchUrl(Uri.parse(doc.fileUrl), mode: LaunchMode.externalApplication),
                      icon: const Icon(IconlyLight.show, size: 15),
                      label: const Text("Open", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(40, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _showReviseDialog(doc),
                    icon: const Icon(IconlyLight.swap, size: 15),
                    label: const Text("Revise", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  IconButton(
                    icon: const Icon(IconlyLight.delete, size: 16, color: Colors.red),
                    tooltip: "Delete Document",
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    onPressed: () => _confirmAndDeleteDocument(doc),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, {bool isHighlighted = false, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark
        ? (isHighlighted ? Colors.white : Colors.white24)
        : (isHighlighted ? const Color(0xFF0D6EFD) : Colors.grey.shade200);
    final labelColor = isHighlighted
        ? (isDark ? Colors.white : const Color(0xFF0D6EFD))
        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    final valColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isHighlighted ? 1.5 : 1),
          boxShadow: [
            if (isHighlighted)
              BoxShadow(
                color: const Color(0xFF0D6EFD).withValues(alpha: 0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: labelColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valColor),
            ),
          ],
        ),
      ),
    );
  }
}
