import 'package:flutter/material.dart';
import 'timesheet_controller.dart';

class AddAttendanceDialog extends StatefulWidget {
  final TimesheetController controller;

  const AddAttendanceDialog({super.key, required this.controller});

  @override
  State<AddAttendanceDialog> createState() => _AddAttendanceDialogState();
}

class _AddAttendanceDialogState extends State<AddAttendanceDialog> {
  String? _selectedOperatorId;
  String? _selectedProjectId;
  String? _selectedJobId; // Mocked job
  String? _selectedTaskSheet; // Dummy

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
    if (_selectedOperatorId == null || _selectedProjectId == null || _selectedJobId == null || _clockIn == null || _clockOut == null) {
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
      "project": int.parse(_selectedProjectId!),
      "job": int.parse(_selectedJobId!),
      "clock_in": _clockIn!.toIso8601String(),
      "clock_out": _clockOut!.toIso8601String(),
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Add Attendance", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: "Operative *", border: OutlineInputBorder()),
                            value: _selectedOperatorId,
                            isExpanded: true,
                            items: operators.map((o) => DropdownMenuItem(value: o['id'].toString(), child: Text(o['name'].toString(), overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => _selectedOperatorId = val),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: "Project *", border: OutlineInputBorder()),
                            value: _selectedProjectId,
                            isExpanded: true,
                            items: projects.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['name'].toString(), overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (val) => setState(() => _selectedProjectId = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Task Name (Job) *", border: OutlineInputBorder()),
                      value: _selectedJobId,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: "22", child: Text("Job 22 (Mocked for API)")),
                      ],
                      onChanged: (val) => setState(() => _selectedJobId = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Task Sheet *", border: OutlineInputBorder()),
                      value: _selectedTaskSheet,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: "drilling", child: Text("Drilling Form")),
                      ],
                      onChanged: (val) => setState(() => _selectedTaskSheet = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDateTime(true),
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: "Clocked in *", border: OutlineInputBorder()),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_clockIn != null ? _formatDateTime(_clockIn!) : 'dd-mm-yyyy hh:mm'),
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDateTime(false),
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: "Clocked out *", border: OutlineInputBorder()),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_clockOut != null ? _formatDateTime(_clockOut!) : 'dd-mm-yyyy hh:mm'),
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.location_on_outlined, size: 16),
                      label: const Text("Use Current Location"),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: "Notes", border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _signatureController,
                      decoration: const InputDecoration(labelText: "Signature Text", border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Add Entry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
