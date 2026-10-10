import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/admin_member_model.dart';
import 'admin_members_controller.dart';

class QualificationsDialog extends StatefulWidget {
  final AdminMember member;
  final AdminMembersController controller;

  const QualificationsDialog({super.key, required this.member, required this.controller});

  @override
  State<QualificationsDialog> createState() => _QualificationsDialogState();
}

class _QualificationsDialogState extends State<QualificationsDialog> {
  List<Map<String, dynamic>> _qualifications = [];
  bool _isBusy = true;

  @override
  void initState() {
    super.initState();
    _loadQualifications();
  }

  Future<void> _loadQualifications() async {
    // The member passed in comes from the list screen, whose endpoint
    // never includes qualifications (would be N+1 queries there) - only
    // the detail endpoint does, so fetch it fresh on open.
    final detail = await widget.controller.fetchMemberDetails(widget.member.id);
    if (!mounted) return;
    setState(() {
      _qualifications = detail?.qualifications ?? List<Map<String, dynamic>>.from(widget.member.qualifications);
      _isBusy = false;
    });
  }

  Future<void> _confirmDelete(Map<String, dynamic> qualification) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Remove Qualification"),
        content: Text('Remove "${qualification['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    final result = await widget.controller.deleteQualification(widget.member.id, qualification['id'] as int);
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      if (result['success'] == true && result['data'] is List) {
        _qualifications = (result['data'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
    );
  }

  Future<void> _showAddForm() async {
    final titleController = TextEditingController();
    final issuerController = TextEditingController();
    final referenceController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? issueDate;
    DateTime? expiryDate;
    PlatformFile? attachment;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickDate({required bool isIssue}) async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setDialogState(() {
                if (isIssue) {
                  issueDate = picked;
                } else {
                  expiryDate = picked;
                }
              });
            }
          }

          String formatDate(DateTime? date) =>
              date == null ? "Select date" : "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

          return AlertDialog(
            title: const Text("Add Qualification"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: "Title *", hintText: "e.g. First Aid at Work"),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: issuerController, decoration: const InputDecoration(labelText: "Issuer")),
                  const SizedBox(height: 12),
                  TextField(controller: referenceController, decoration: const InputDecoration(labelText: "Reference Number")),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting ? null : () => pickDate(isIssue: true),
                          child: Text("Issue: ${formatDate(issueDate)}", overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting ? null : () => pickDate(isIssue: false),
                          child: Text("Expiry: ${formatDate(expiryDate)}", overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: "Notes"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final result = await FilePicker.platform.pickFiles();
                                if (result != null && result.files.isNotEmpty) {
                                  setDialogState(() => attachment = result.files.first);
                                }
                              },
                        icon: const Icon(Icons.attach_file, size: 16),
                        label: const Text("Attach File"),
                      ),
                      const SizedBox(width: 8),
                      if (attachment != null)
                        Expanded(child: Text(attachment!.name, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Title is required.")),
                          );
                          return;
                        }
                        if (issueDate != null && expiryDate != null && expiryDate!.isBefore(issueDate!)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Expiry date cannot be earlier than issue date.")),
                          );
                          return;
                        }
                        setDialogState(() => isSubmitting = true);
                        final result = await widget.controller.addQualification(
                          widget.member.id,
                          title: title,
                          issuer: issuerController.text.trim(),
                          referenceNumber: referenceController.text.trim(),
                          issueDate: issueDate == null ? null : formatDate(issueDate),
                          expiryDate: expiryDate == null ? null : formatDate(expiryDate),
                          notes: notesController.text.trim(),
                          attachmentPath: attachment?.path,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        setState(() {
                          if (result['success'] == true && result['data'] is List) {
                            _qualifications = (result['data'] as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? Colors.green : Colors.red),
                        );
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Add"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Qualifications - ${widget.member.displayName}",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(icon: Icon(Icons.close, color: subtitleColor), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isBusy
                  ? const Center(child: CircularProgressIndicator())
                  : _qualifications.isEmpty
                      ? Center(
                          child: Text("No qualifications added yet.", style: TextStyle(color: subtitleColor)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _qualifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final q = _qualifications[index];
                            final subtitleParts = <String>[
                              if ((q['issuer'] as String?)?.isNotEmpty == true) q['issuer'] as String,
                              if (q['expiry_date'] != null) "Expires ${q['expiry_date']}",
                            ];
                            return ListTile(
                              leading: Icon(IconlyBold.paper, color: textColor),
                              title: Text(q['title']?.toString() ?? '', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                              subtitle: subtitleParts.isEmpty
                                  ? null
                                  : Text(subtitleParts.join(' · '), style: TextStyle(color: subtitleColor, fontSize: 12)),
                              trailing: IconButton(
                                icon: const Icon(IconlyLight.delete, size: 18, color: Colors.red),
                                onPressed: () => _confirmDelete(q),
                              ),
                            );
                          },
                        ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: _showAddForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Qualification"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F62FE),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
