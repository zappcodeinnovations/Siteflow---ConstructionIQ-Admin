import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_helper.dart';
import '../../../models/job_sheet_model.dart';
import '../../drawer_pages/job_sheet_details_screen.dart';
import '../create_task_controller.dart';

class JobSheetsTab extends StatefulWidget {
  final List<dynamic> jobSheets;
  final Map<String, dynamic> filterOptions;

  const JobSheetsTab({
    Key? key,
    required this.jobSheets,
    required this.filterOptions,
  }) : super(key: key);

  @override
  State<JobSheetsTab> createState() => _JobSheetsTabState();
}

class _JobSheetsTabState extends State<JobSheetsTab> {
  String? _selectedForm;
  String? _selectedOperative;
  String? _selectedMaterial;
  String? _selectedTeam;
  String? _selectedStatus;
  String _searchQuery = '';

  List<String> _getOptionList(String key, String fallbackField) {
    final listFromOptions = widget.filterOptions[key] as List?;
    if (listFromOptions != null && listFromOptions.isNotEmpty) {
      return listFromOptions
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }
    return widget.jobSheets
        .map((s) => (s is Map ? (s[fallbackField] ?? s['${fallbackField}_name']) : null)?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty && e != 'null' && e != '-')
        .toSet()
        .toList();
  }

  List<String> get _forms => _getOptionList('forms', 'form');

  List<String> get _operatives {
    final raw = _getOptionList('operatives', 'operative');
    return raw.where((e) => CreateTaskController.isEligibleOperativeName(e)).toList();
  }

  List<String> get _materials => _getOptionList('materials', 'material');
  List<String> get _teams => _getOptionList('teams', 'team');

  List<dynamic> get _filteredJobSheets {
    return widget.jobSheets.where((item) {
      final sheet = item is Map<String, dynamic>
          ? item
          : (item is Map ? item.cast<String, dynamic>() : <String, dynamic>{});

      // Form filter
      if (_selectedForm != null && _selectedForm!.isNotEmpty) {
        final formVal = sheet['form']?.toString().toLowerCase().trim() ?? '';
        if (formVal != _selectedForm!.toLowerCase().trim()) return false;
      }

      // Operative filter
      if (_selectedOperative != null && _selectedOperative!.isNotEmpty) {
        final opVal = sheet['operative']?.toString().toLowerCase().trim() ?? '';
        final targetOp = _selectedOperative!.toLowerCase().trim();
        if (opVal != targetOp && !opVal.contains(targetOp) && !targetOp.contains(opVal)) return false;
      }

      // Material filter
      if (_selectedMaterial != null && _selectedMaterial!.isNotEmpty) {
        final matVal = sheet['material']?.toString().toLowerCase().trim() ?? '';
        final materialsList = (sheet['materials'] as List?)
                ?.map((e) => e.toString().toLowerCase().trim())
                .toList() ??
            [];
        final targetMat = _selectedMaterial!.toLowerCase().trim();
        if (matVal != targetMat && !matVal.contains(targetMat) && !materialsList.contains(targetMat)) {
          return false;
        }
      }

      // Team filter
      if (_selectedTeam != null && _selectedTeam!.isNotEmpty) {
        final teamVal = sheet['team']?.toString().toLowerCase().trim() ?? '';
        if (teamVal != _selectedTeam!.toLowerCase().trim()) return false;
      }

      // Status filter
      if (_selectedStatus != null &&
          _selectedStatus!.isNotEmpty &&
          _selectedStatus != 'All' &&
          _selectedStatus != 'Status: All') {
        final statusVal = (sheet['status'] ?? sheet['status_label'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        final targetStatus =
            _selectedStatus!.replaceAll('Status: ', '').toLowerCase().trim();
        if (statusVal != targetStatus && !statusVal.contains(targetStatus)) return false;
      }

      // Search Query (Sheet No / Reference / Keywords)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final sheetNo = sheet['sheet_no']?.toString().toLowerCase() ?? '';
        final ref = (sheet['job_reference'] ?? sheet['job_no'] ?? '')
            .toString()
            .toLowerCase();
        final op = sheet['operative']?.toString().toLowerCase() ?? '';
        final form = sheet['form']?.toString().toLowerCase() ?? '';
        if (!sheetNo.contains(q) &&
            !ref.contains(q) &&
            !op.contains(q) &&
            !form.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _selectedForm != null ||
      _selectedOperative != null ||
      _selectedMaterial != null ||
      _selectedTeam != null ||
      (_selectedStatus != null &&
          _selectedStatus != 'All' &&
          _selectedStatus != 'Status: All') ||
      _searchQuery.isNotEmpty;

  void _clearAllFilters() {
    setState(() {
      _selectedForm = null;
      _selectedOperative = null;
      _selectedMaterial = null;
      _selectedTeam = null;
      _selectedStatus = null;
      _searchQuery = '';
    });
  }

  void _openMoreFiltersSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String? tempForm = _selectedForm;
    String? tempOperative = _selectedOperative;
    String? tempMaterial = _selectedMaterial;
    String? tempTeam = _selectedTeam;
    String? tempStatus = _selectedStatus;
    TextEditingController searchCtrl = TextEditingController(text: _searchQuery);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(IconlyLight.filter,
                                size: 20,
                                color: isDark ? Colors.white : Colors.black87),
                            const SizedBox(width: 8),
                            Text(
                              "More Filters",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempForm = null;
                              tempOperative = null;
                              tempMaterial = null;
                              tempTeam = null;
                              tempStatus = null;
                              searchCtrl.clear();
                            });
                          },
                          child: const Text("Reset All"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search by Sheet No / Keyword
                    TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: "Search Sheet # or Keyword...",
                        prefixIcon: const Icon(IconlyLight.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Chips
                    Text(
                      "Status",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'All',
                        'Submitted',
                        'Approved',
                        'In Progress',
                        'Rejected',
                      ].map((st) {
                        final isSelected = (tempStatus == null && st == 'All') ||
                            tempStatus == st;
                        return ChoiceChip(
                          label: Text(st),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0D6EFD),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black87),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              tempStatus = st == 'All' ? null : st;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Form Dropdown
                    if (_forms.isNotEmpty) ...[
                      _buildModalDropdownRow(
                        label: "Form",
                        value: tempForm,
                        options: _forms,
                        isDark: isDark,
                        onChanged: (val) {
                          setModalState(() {
                            tempForm = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Operative Dropdown
                    if (_operatives.isNotEmpty) ...[
                      _buildModalDropdownRow(
                        label: "Operative",
                        value: tempOperative,
                        options: _operatives,
                        isDark: isDark,
                        onChanged: (val) {
                          setModalState(() {
                            tempOperative = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Material Dropdown
                    if (_materials.isNotEmpty) ...[
                      _buildModalDropdownRow(
                        label: "Material",
                        value: tempMaterial,
                        options: _materials,
                        isDark: isDark,
                        onChanged: (val) {
                          setModalState(() {
                            tempMaterial = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Team Dropdown
                    if (_teams.isNotEmpty) ...[
                      _buildModalDropdownRow(
                        label: "Team",
                        value: tempTeam,
                        options: _teams,
                        isDark: isDark,
                        onChanged: (val) {
                          setModalState(() {
                            tempTeam = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 20),

                    // Bottom Action Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              side: BorderSide(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text("Cancel",
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D6EFD),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedForm = tempForm;
                                _selectedOperative = tempOperative;
                                _selectedMaterial = tempMaterial;
                                _selectedTeam = tempTeam;
                                _selectedStatus = tempStatus;
                                _searchQuery = searchCtrl.text.trim();
                              });
                              Navigator.pop(ctx);
                            },
                            child: const Text("Apply Filters",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalDropdownRow({
    required String label,
    required String? value,
    required List<String> options,
    required bool isDark,
    required ValueChanged<String?> onChanged,
  }) {
    final unique = options.toSet().toList();
    final isSelected = value != null && value.isNotEmpty;

    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? Colors.grey.shade300 : Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF0D6EFD)
                    : (isDark ? Colors.white12 : Colors.grey.shade300),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                value: unique.contains(value) ? value : null,
                hint: Text("All $label",
                    style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                isExpanded: true,
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text("All $label (Clear)",
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey)),
                  ),
                  ...unique.map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: value == e
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isDark ? Colors.white : Colors.black87)),
                    ),
                  ),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayedList = _filteredJobSheets;

    return Column(
      children: [
        _buildJobSheetsFilterBar(context, displayedList.length),
        Expanded(
          child: displayedList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyLight.folder,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _hasActiveFilters
                            ? "No matching Job Sheets found"
                            : "No Job Sheets available",
                        style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                      if (_hasActiveFilters) ...[
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _clearAllFilters,
                          child: const Text("Clear Filters"),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  itemCount: displayedList.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final sheet = displayedList[index] as Map<String, dynamic>? ??
                        (displayedList[index] is Map
                            ? (displayedList[index] as Map).cast<String, dynamic>()
                            : <String, dynamic>{});
                    return _buildJobSheetCard(
                      context,
                      sheet: sheet,
                      sheetNo: sheet['sheet_no']?.toString() ?? "N/A",
                      reference: sheet['job_reference']?.toString() ??
                          sheet['job_no']?.toString() ??
                          "N/A",
                      status: sheet['status']?.toString() ??
                          sheet['status_label']?.toString() ??
                          "N/A",
                      operativeName: sheet['operative']?.toString() ?? "N/A",
                      form: sheet['form']?.toString() ?? "N/A",
                      location: sheet['location']?.toString() ?? "N/A",
                      created: DateHelper.formatToLocal(sheet['created']?.toString()),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildJobSheetsFilterBar(BuildContext context, int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
            bottom: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade200)),
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
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey.shade400 : Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildFilterDropdown(
                context,
                "Form",
                _forms,
                _selectedForm,
                (val) => setState(() => _selectedForm = val),
              ),
              _buildFilterDropdown(
                context,
                "Operative",
                _operatives,
                _selectedOperative,
                (val) => setState(() => _selectedOperative = val),
              ),
              if (_materials.isNotEmpty)
                _buildFilterDropdown(
                  context,
                  "Material",
                  _materials,
                  _selectedMaterial,
                  (val) => setState(() => _selectedMaterial = val),
                ),
              if (_teams.isNotEmpty)
                _buildFilterDropdown(
                  context,
                  "Team",
                  _teams,
                  _selectedTeam,
                  (val) => setState(() => _selectedTeam = val),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasActiveFilters
                      ? const Color(0xFF0D6EFD).withValues(alpha: 0.15)
                      : (isDark ? Colors.white10 : Colors.white),
                  foregroundColor: _hasActiveFilters
                      ? const Color(0xFF0D6EFD)
                      : (isDark ? Colors.white : Colors.black87),
                  elevation: 0,
                  side: BorderSide(
                      color: _hasActiveFilters
                          ? const Color(0xFF0D6EFD)
                          : (isDark ? Colors.white24 : Colors.grey.shade300)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                onPressed: () => _openMoreFiltersSheet(context),
                icon: Icon(IconlyLight.filter,
                    size: 16,
                    color: _hasActiveFilters
                        ? const Color(0xFF0D6EFD)
                        : (isDark ? Colors.white : Colors.black87)),
                label: const Text("More Filters",
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 12),
            _buildActiveFilterChips(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFilterChips(bool isDark) {
    final chips = <Widget>[];

    void addChip(String label, String value, VoidCallback onRemove) {
      chips.add(
        Container(
          margin: const EdgeInsets.only(right: 8, top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0D6EFD).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF0D6EFD).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$label: ",
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6EFD)),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  value,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onRemove,
                child: const Icon(Icons.close,
                    size: 14, color: Color(0xFF0D6EFD)),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedForm != null) {
      addChip("Form", _selectedForm!, () => setState(() => _selectedForm = null));
    }
    if (_selectedOperative != null) {
      addChip("Operative", _selectedOperative!,
          () => setState(() => _selectedOperative = null));
    }
    if (_selectedMaterial != null) {
      addChip("Material", _selectedMaterial!,
          () => setState(() => _selectedMaterial = null));
    }
    if (_selectedTeam != null) {
      addChip("Team", _selectedTeam!, () => setState(() => _selectedTeam = null));
    }
    if (_selectedStatus != null &&
        _selectedStatus != 'All' &&
        _selectedStatus != 'Status: All') {
      addChip("Status", _selectedStatus!,
          () => setState(() => _selectedStatus = null));
    }
    if (_searchQuery.isNotEmpty) {
      addChip("Search", _searchQuery, () => setState(() => _searchQuery = ''));
    }

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: chips),
          ),
        ),
        TextButton(
          onPressed: _clearAllFilters,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text("Clear All",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context,
    String label,
    List<String> options,
    String? currentValue,
    ValueChanged<String?> onChanged,
  ) {
    if (options.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uniqueOptions = options.toSet().toList();
    final isSelected = currentValue != null && currentValue.isNotEmpty;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF0D6EFD).withValues(alpha: 0.12)
            : (isDark ? Colors.white10 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF0D6EFD)
              : (isDark ? Colors.white12 : Colors.grey.shade300),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
          value: uniqueOptions.contains(currentValue) ? currentValue : null,
          hint: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text(
                "All $label (Clear)",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            ...uniqueOptions.map(
              (e) => DropdownMenuItem<String>(
                value: e,
                child: Text(
                  e,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected && currentValue == e
                        ? FontWeight.bold
                        : FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
          onChanged: (val) {
            if (val == '' || val == null) {
              onChanged(null);
            } else {
              onChanged(val);
            }
          },
          icon: Icon(
            IconlyLight.arrow_down_2,
            color: isSelected
                ? const Color(0xFF0D6EFD)
                : (isDark ? Colors.white70 : Colors.black54),
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildJobSheetCard(
    BuildContext context, {
    required Map<String, dynamic> sheet,
    required String sheetNo,
    required String reference,
    required String status,
    required String operativeName,
    required String form,
    required String location,
    required String created,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkSurface : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final isCompleted = status.toLowerCase() == 'approved' ||
        status.toLowerCase() == 'completed' ||
        status.toLowerCase() == 'closed';
    final statusColor = isCompleted ? Colors.green : const Color(0xFF0D6EFD);
    final statusBgColor = isCompleted
        ? (isDark ? Colors.green.withValues(alpha: 0.2) : Colors.green.shade50)
        : (isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50);

    return Container(
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
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
                        color:
                            isDark ? Colors.white : const Color(0xFF0D6EFD),
                        size: 18),
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
                          style:
                              TextStyle(color: textSecondary, fontSize: 13)),
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
                        color: isDark
                            ? Colors.white
                            : statusColor.withValues(alpha: 0.9),
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
            child: Divider(
                height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),

          // 2-Column Metadata Row for OPERATIVE and FORM
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInfoColumn(
                    context, "OPERATIVE", operativeName, IconlyLight.profile),
              ),
              const SizedBox(width: 16),
              Expanded(
                child:
                    _buildInfoColumn(context, "FORM", form, IconlyLight.paper),
              ),
            ],
          ),

          if (location.isNotEmpty &&
              location != '-' &&
              location != 'null' &&
              location != 'N/A') ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(IconlyLight.location, size: 14, color: textSecondary),
                const SizedBox(width: 6),
                Text(
                  "LOCATION: ",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 0.5),
                ),
                Expanded(
                  child: Tooltip(
                    message: location,
                    child: Text(
                      location,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor),
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],

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
                      foregroundColor:
                          isDark ? Colors.white : const Color(0xFF0D6EFD),
                      side: BorderSide(
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFF0D6EFD)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobSheetDetailsScreen(
                            jobSheet: JobSheet.fromJson(sheet),
                          ),
                        ),
                      );
                    },
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

  Widget _buildInfoColumn(
      BuildContext context, String label, String value, IconData icon) {
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
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textSecondary,
                    letterSpacing: 0.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Tooltip(
          message: value,
          child: Text(
            value.isNotEmpty ? value : "-",
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.25),
            softWrap: true,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
