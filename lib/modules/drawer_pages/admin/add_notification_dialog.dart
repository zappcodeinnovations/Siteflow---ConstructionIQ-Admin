import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'admin_notifications_controller.dart';

class AddNotificationDialog extends StatefulWidget {
  final AdminNotificationsController controller;
  const AddNotificationDialog({super.key, required this.controller});

  @override
  State<AddNotificationDialog> createState() => _AddNotificationDialogState();
}

class _AddNotificationDialogState extends State<AddNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _headlineController = TextEditingController();
  final _textController = TextEditingController();
  final _operatorSearchController = TextEditingController();

  String _audience = "all";
  bool _isActive = true;
  bool _sendPush = true;
  bool _isLoading = false;

  // "Selected Operators" audience: a real picker (search + checkbox list)
  // instead of asking the user to type raw numeric operator IDs by hand -
  // the search field previously had no list to search at all.
  List<Map<String, dynamic>> _operators = [];
  bool _loadingOperators = false;
  final Set<int> _selectedOperatorIds = {};
  String _operatorSearch = '';

  @override
  void initState() {
    super.initState();
    _loadOperators();
  }

  Future<void> _loadOperators() async {
    setState(() => _loadingOperators = true);
    try {
      final response = await ApiClient.get(
        '${ApiEndpoints.baseUrl}/admin/notifications/filter-options/',
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded['status'] == true) {
        final list = (decoded['data'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
        if (mounted) setState(() => _operators = list);
      }
    } catch (_) {
      // The picker shows "No operators found" if the list stays empty.
    } finally {
      if (mounted) setState(() => _loadingOperators = false);
    }
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _textController.dispose();
    _operatorSearchController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audience == "selected_operators" && _selectedOperatorIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one operator")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final operatorIds = _selectedOperatorIds.toList();

    final payload = {
      "headline": _headlineController.text.trim(),
      "notification_text": _textController.text.trim(),
      "audience": _audience,
      if (_audience == "selected_operators") "operator_ids": operatorIds,
      "is_active": _isActive,
      "send_push": _sendPush,
      "attachment": null,
    };

    final result = await widget.controller.createNotification(payload);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (result['success'] == true) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Create Notification",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F2C4A),
                      ),
                    ),
                    IconButton(
                      icon: Icon(IconlyLight.close_square, color: isDark ? Colors.white70 : Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(color: isDark ? Colors.white24 : Colors.grey.shade300),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _headlineController,
                  decoration: _buildInputDecoration("Headline", IconlyLight.document, isDark),
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _textController,
                  maxLines: 3,
                  decoration: _buildInputDecoration("Notification Text", IconlyLight.message, isDark),
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _audience,
                  dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  decoration: _buildInputDecoration("Audience", IconlyLight.user_1, isDark),
                  items: const [
                    DropdownMenuItem(value: "all", child: Text("All Operators")),
                    DropdownMenuItem(value: "selected_operators", child: Text("Selected Operators")),
                  ],
                  onChanged: (val) => setState(() => _audience = val ?? "all"),
                ),
                if (_audience == "selected_operators") ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _operatorSearchController,
                    decoration: _buildInputDecoration(
                      "Search Operator (name or email)",
                      IconlyLight.search,
                      isDark,
                    ),
                    onChanged: (val) =>
                        setState(() => _operatorSearch = val.trim().toLowerCase()),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      if (_loadingOperators) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final filtered = _operatorSearch.isEmpty
                          ? _operators
                          : _operators.where((o) {
                              final name = (o['display_name'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              final email =
                                  (o['email'] ?? '').toString().toLowerCase();
                              return name.contains(_operatorSearch) ||
                                  email.contains(_operatorSearch);
                            }).toList();
                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            "No operators found",
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        );
                      }
                      return Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final operator = filtered[index];
                            final id = operator['id'] as int;
                            final name = (operator['display_name'] ?? '')
                                .toString();
                            final email = (operator['email'] ?? '').toString();
                            return CheckboxListTile(
                              dense: true,
                              value: _selectedOperatorIds.contains(id),
                              title: Text(
                                name.isNotEmpty ? name : email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              subtitle: name.isNotEmpty && email.isNotEmpty
                                  ? Text(email, style: const TextStyle(fontSize: 11))
                                  : null,
                              onChanged: (checked) => setState(() {
                                if (checked == true) {
                                  _selectedOperatorIds.add(id);
                                } else {
                                  _selectedOperatorIds.remove(id);
                                }
                              }),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  if (_selectedOperatorIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "${_selectedOperatorIds.length} selected",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text("Is Active", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: 13)),
                  value: _isActive,
                  activeColor: Colors.green,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
                SwitchListTile(
                  title: Text("Send Push Notification", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontSize: 13)),
                  value: _sendPush,
                  activeColor: Colors.blue,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setState(() => _sendPush = val),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Send Notification", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, bool isDark) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300)),
    );
  }
}
