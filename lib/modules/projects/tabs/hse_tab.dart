import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/hse_document_model.dart';
import '../project_hse_controller.dart';

class HseTab extends StatefulWidget {
  final int projectId;
  const HseTab({Key? key, required this.projectId}) : super(key: key);

  @override
  State<HseTab> createState() => _HseTabState();
}

class _HseTabState extends State<HseTab> {
  late final ProjectHseController _controller = ProjectHseController(widget.projectId);
  String _categoryFilter = 'All';

  static const _categories = ['All', 'rams', 'certificate', 'training', 'other'];
  static const _categoryLabels = {
    'All': 'All',
    'rams': 'RAMS',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: _controller.fetchDocuments,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  _buildKpiGrid(textColor, textSecondary, cardColor, borderColor),
                  const SizedBox(height: 24),
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
      counts[doc.category] = (counts[doc.category] ?? 0) + 1;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 5;
        double aspectRatio = 2.0;
        if (constraints.maxWidth < 480) {
          crossAxisCount = 2;
          aspectRatio = 1.8;
        } else if (constraints.maxWidth < 800) {
          crossAxisCount = 3;
          aspectRatio = 1.9;
        }
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
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
        : _controller.documents.where((d) => d.category == _categoryFilter).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.corporateBlue : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("No HS&E documents uploaded yet.", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              "RAMS, certificates, and training records are uploaded from the web admin panel.",
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: filtered.map((doc) => _buildDocCard(doc, textColor, textSecondary, cardColor, borderColor)).toList(),
    );
  }

  Widget _buildDocCard(HseDocumentModel doc, Color textColor, Color textSecondary, Color cardColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(doc.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: textSecondary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text(doc.categoryLabel, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Uploaded by ${doc.uploadedByName.isEmpty ? '-' : doc.uploadedByName}${doc.revisionNumber > 1 ? ' · Revision ${doc.revisionNumber}' : ''}",
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          if (doc.expiryDate != null && doc.expiryDate!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text("Expires ${doc.expiryDate}", style: TextStyle(fontSize: 12, color: textSecondary)),
          ],
          if (doc.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(doc.notes, style: TextStyle(fontSize: 13, color: textSecondary)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (doc.requiresAcknowledgment)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (doc.isAcknowledged ? const Color(0xFF16A34A) : const Color(0xFFF59E0B)).withOpacity(0.12),
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
                ),
              const Spacer(),
              if (doc.fileUrl.isNotEmpty)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(doc.fileUrl), mode: LaunchMode.externalApplication),
                  icon: const Icon(IconlyLight.document, size: 16),
                  label: const Text("View File"),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, {bool isHighlighted = false, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark
        ? (isHighlighted ? Colors.white : Colors.white24)
        : (isHighlighted ? const Color(0xFF0D6EFD).withOpacity(0.5) : Colors.grey.shade200);
    final labelColor = isHighlighted
        ? (isDark ? Colors.white : const Color(0xFF0D6EFD))
        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    final valColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isHighlighted ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: labelColor, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valColor, fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }
}
