import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_theme.dart';

class HseTab extends StatefulWidget {
  const HseTab({Key? key}) : super(key: key);

  @override
  State<HseTab> createState() => _HseTabState();
}

class _HseTabState extends State<HseTab> {
  bool _isFormVisible = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _selectedCategory = 'Training';
  DateTime? _expiryDate;
  String? _fileName;

  final List<String> _categories = ['RAMS', 'Certificate', 'Training', 'Other'];

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        _expiryDate = date;
      });
    }
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _fileName = result.files.first.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isFormVisible) ...[
                  SizedBox(
                    width: 320,
                    child: _buildFormPanel(),
                  ),
                  const SizedBox(width: 24),
                ],
                Expanded(
                  child: _buildMainContent(),
                )
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isFormVisible) ...[
                  _buildFormPanel(),
                  const SizedBox(height: 24),
                ],
                _buildMainContent(),
              ],
            ),
    );
  }

  Widget _buildFormPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Upload HS&E Document",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: isDark ? Colors.white : Colors.black87),
                onPressed: () => setState(() => _isFormVisible = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            ],
          ),
          const SizedBox(height: 20),
          
          _buildFormLabel("Category"),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: isDark ? AppTheme.corporateBlue : Colors.white,
                isExpanded: true,
                value: _selectedCategory,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                icon: Icon(IconlyLight.arrow_down_2, color: isDark ? Colors.white70 : Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFormLabel("Title"),
          TextField(
            controller: _titleController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: "Leave blank to use file name",
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 14),
              isDense: true,
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFormLabel("Expiry Date"),
          InkWell(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _expiryDate != null ? "${_expiryDate!.day.toString().padLeft(2, '0')}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.year}" : "dd-mm-yyyy",
                    style: TextStyle(color: _expiryDate != null ? textColor : (isDark ? Colors.white38 : Colors.grey.shade400), fontSize: 14),
                  ),
                  Icon(IconlyLight.calendar, size: 18, color: isDark ? Colors.white70 : Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFormLabel("Files"),
          InkWell(
            onTap: _pickFile,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                      border: Border(right: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                    ),
                    child: Text("Choose Files", style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        _fileName ?? "No file chosen",
                        style: TextStyle(fontSize: 14, color: _fileName != null ? textColor : (isDark ? Colors.white38 : Colors.grey.shade500)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFormLabel("Notes"),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: "Optional notes",
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white10 : const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
                side: BorderSide(color: isDark ? Colors.white24 : Colors.transparent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (_fileName == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a file.")));
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("HS&E Document Uploaded!")));
                setState(() => _isFormVisible = false);
              },
              child: const Text("Upload Documents", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.black87),
      ),
    );
  }

  Widget _buildMainContent() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_isFormVisible)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white10 : const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
                side: BorderSide(color: isDark ? Colors.white24 : Colors.transparent),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => setState(() => _isFormVisible = true),
              icon: const Icon(IconlyLight.upload, size: 18),
              label: const Text("Upload HS&E Document", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        if (!_isFormVisible) const SizedBox(height: 16),
        
        // KPI Cards in Grid
        LayoutBuilder(
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
              children: [
                _buildKpiCard("All", "0", isHighlighted: true),
                _buildKpiCard("RAMS", "0"),
                _buildKpiCard("Certificate", "0"),
                _buildKpiCard("Training", "0"),
                _buildKpiCard("Other", "0"),
              ],
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // Empty State
        Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.corporateBlue : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "No HS&E documents uploaded yet.",
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "Upload RAMS, certificates, training records, and supporting files from the panel.",
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, {bool isHighlighted = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final borderColor = isDark 
        ? (isHighlighted ? Colors.white : Colors.white24)
        : (isHighlighted ? const Color(0xFF0D6EFD).withOpacity(0.5) : Colors.grey.shade200);
    final labelColor = isHighlighted 
        ? (isDark ? Colors.white : const Color(0xFF0D6EFD)) 
        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    final valColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12, 
              color: labelColor, 
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: valColor,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
