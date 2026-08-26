import 'package:flutter/material.dart';
import 'timesheet_controller.dart';
import 'package:iconly/iconly.dart';
import '../../core/theme/app_theme.dart';

class AddAttendanceDialog extends StatefulWidget {
  final TimesheetController controller;

  const AddAttendanceDialog({super.key, required this.controller});

  @override
  State<AddAttendanceDialog> createState() => _AddAttendanceDialogState();
}

class _AddAttendanceDialogState extends State<AddAttendanceDialog> {
  String? _selectedOperatorId;
  String? _selectedProjectId;
  String? _selectedJobId;
  String? _selectedTaskSheet;

  DateTime? _clockIn;
  DateTime? _clockOut;
  
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();

  bool _isSubmitting = false;

  String _formatDateTime(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDateTime(bool isClockIn) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final dt = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
        setState(() {
          if (isClockIn) {
            _clockIn = dt;
          } else {
            _clockOut = dt;
          }
        });
      }
    }
  }

  void _submit() async {
    if (_selectedOperatorId == null || _clockIn == null || _clockOut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields.")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final payload = {
      "operator": int.parse(_selectedOperatorId!),
      "project": _selectedProjectId != null ? int.parse(_selectedProjectId ?? "N/A") : null,
      "job": _selectedJobId!= null? int.parse(_selectedJobId ?? "N/A") : null,
      "clock_in": _clockIn!.toIso8601String().split('.').first,
      "clock_out": _clockOut!.toIso8601String().split('.').first,
      "location_latitude": "51.5074", // Mock location
      "location_longitude": "-0.1278",
      "notes": _notesController.text,
    };

    final result = await widget.controller.addAttendance(payload);

    if (!mounted) return;
    
    setState(() {
      _isSubmitting = false;
    });

    if (result['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.controller.data?.filterOptions ?? {};
    final operators = (options['operators'] as List?) ?? [];
    final projects = (options['projects'] as List?) ?? [];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final iconBgColor = isDark ? Colors.white24 : Colors.grey.shade100;
    final iconColor = isDark ? Colors.white : Colors.black54;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Add Attendance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                    child: Icon(IconlyLight.close_square, size: 18, color: iconColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildPremiumDropdown(
                            "Operative *", 
                            _selectedOperatorId, 
                            operators.map((o) => DropdownMenuItem(value: o['id'].toString(), child: Text(o['name'].toString(), overflow: TextOverflow.ellipsis))).toList(),
                            (val) => setState(() => _selectedOperatorId = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPremiumDropdown(
                            "Project",
                            _selectedProjectId, 
                            projects.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['name'].toString(), overflow: TextOverflow.ellipsis))).toList(),
                            (val) => setState(() => _selectedProjectId = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPremiumDropdown(
                      "Task Name (Job) *", 
                      _selectedJobId, 
                      const [DropdownMenuItem(value: "22", child: Text("Job 22 (Mocked for API)"))],
                      (val) => setState(() => _selectedJobId = val),
                    ),
                    const SizedBox(height: 16),
                    _buildPremiumDropdown(
                      "Task Sheet *", 
                      _selectedTaskSheet, 
                      const [DropdownMenuItem(value: "drilling", child: Text("Drilling Form"))],
                      (val) => setState(() => _selectedTaskSheet = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimeField("Clocked in *", _clockIn, () => _selectDateTime(true)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateTimeField("Clocked out *", _clockOut, () => _selectDateTime(false)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {},
                        icon: Icon(IconlyLight.location, size: 16, color: isDark ? Colors.white : Colors.black87),
                        label: Text("Use Current Location", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPremiumTextField("Notes", _notesController, maxLines: 3),
                    const SizedBox(height: 16),
                    _buildPremiumTextField("Signature Text", _signatureController),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color(0xFF0D6EFD),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Add Entry", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumDropdown(String label, String? value, List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBgColor = isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black54;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dropdownColor = isDark ? const Color(0xFF1F2E40) : Colors.white;
    final iconColor = isDark ? Colors.white70 : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: labelColor)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: boxBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text("Select option", style: TextStyle(color: labelColor)),
              icon: Icon(IconlyLight.arrow_down_2, color: iconColor),
              dropdownColor: dropdownColor,
              style: TextStyle(color: textColor, fontSize: 14),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField(String label, DateTime? value, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBgColor = isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black54;
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white70 : Colors.grey;
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: labelColor)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: boxBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value != null ? _formatDateTime(value) : 'dd-mm-yyyy hh:mm',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: value != null ? textColor : hintColor),
                ),
                Icon(IconlyLight.calendar, size: 16, color: iconColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBgColor = isDark ? const Color(0xFF1F2E40) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade200;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black54;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: labelColor)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            filled: true,
            fillColor: boxBgColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D6EFD))),
          ),
        ),
      ],
    );
  }
}
