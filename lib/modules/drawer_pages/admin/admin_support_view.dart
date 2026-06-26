import 'package:flutter/material.dart';
import 'admin_support_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminSupportView extends StatefulWidget {
  const AdminSupportView({super.key});

  @override
  State<AdminSupportView> createState() => _AdminSupportViewState();
}

class _AdminSupportViewState extends State<AdminSupportView> {
  final AdminSupportController _controller = AdminSupportController();

  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedCategory = 'login_access';
  String _selectedPriority = 'normal';

  final List<Map<String, String>> _categories = [
    {'value': 'login_access', 'label': 'Login & access'},
    {'value': 'attendance_timesheets', 'label': 'Attendance & timesheets'},
    {'value': 'projects', 'label': 'Projects & forms'},
    {'value': 'other', 'label': 'Other'},
  ];

  final List<Map<String, String>> _priorities = [
    {'value': 'low', 'label': 'Low'},
    {'value': 'normal', 'label': 'Normal'},
    {'value': 'high', 'label': 'High'},
    {'value': 'urgent', 'label': 'Urgent'},
  ];

  @override
  void initState() {
    super.initState();
    _controller.initializeData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await _controller.submitTicket(
      subject: _subjectController.text.trim(),
      category: _selectedCategory,
      priority: _selectedPriority,
      body: _messageController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: result['success'] ? Colors.green : Colors.red),
      );
      if (result['success']) {
        _formKey.currentState!.reset();
        _subjectController.clear();
        _messageController.clear();
        setState(() {
          _selectedCategory = 'login_access';
          _selectedPriority = 'normal';
        });
      }
    }
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBeforeSendItem(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade300, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        const Text("Support", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
        const SizedBox(height: 32),

        Expanded(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCard(
                            title: "Contact Support",
                            icon: Icons.support_agent_outlined,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Subject", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _subjectController,
                                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Briefly describe the issue", contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const SizedBox(height: 8),
                                            DropdownButtonFormField<String>(
                                              value: _selectedCategory,
                                              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                              items: _categories.map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!))).toList(),
                                              onChanged: (val) => setState(() => _selectedCategory = val!),
                                            ),
                                          ],
                                        )
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text("Priority", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            const SizedBox(height: 8),
                                            DropdownButtonFormField<String>(
                                              value: _selectedPriority,
                                              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                              items: _priorities.map((p) => DropdownMenuItem(value: p['value'], child: Text(p['label']!))).toList(),
                                              onChanged: (val) => setState(() => _selectedPriority = val!),
                                            ),
                                          ],
                                        )
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  const Text("Message", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _messageController,
                                    maxLines: 4,
                                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Add the page, user, project, job number, and what you expected to happen.", contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  const Text("Attachment or screenshot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                                          child: const Text("Choose File", style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text("No file chosen", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D6EFD), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                      onPressed: _controller.isSubmitting ? null : _submitForm,
                                      icon: _controller.isSubmitting 
                                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : const Icon(Icons.send_outlined, color: Colors.white, size: 18),
                                      label: const Text("Send Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ),
                          const SizedBox(height: 24),

                          _buildCard(
                            title: "Quick Actions",
                            icon: Icons.bolt,
                            child: Column(
                              children: [
                                _buildQuickActionItem(Icons.group_outlined, "Manage Members", "Invite users, reset access, and review pending invitations."),
                                _buildQuickActionItem(Icons.business_outlined, "Organisation Settings", "Update organisation name, currency, and profile settings."),
                                _buildQuickActionItem(Icons.folder_open_outlined, "Project Setup", "Check project setup, assigned operatives, forms, and locations."),
                              ],
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  
                  // Right Column
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCard(
                            title: "Support Details",
                            icon: Icons.info_outline,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.mail_outline, size: 16, color: Colors.blue.shade700),
                                    const SizedBox(width: 12),
                                    Text("Email: ${_controller.quickActions?.supportEmail ?? 'Loading...'}", style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.call_outlined, size: 16, color: Colors.blue.shade700),
                                    const SizedBox(width: 12),
                                    Text("Call: ${_controller.quickActions?.supportPhone ?? 'Loading...'}", style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_outlined, size: 16, color: Colors.blue.shade700),
                                    const SizedBox(width: 12),
                                    const Text("Monday to Friday, 09:30 - 17:30", style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    "Include screenshots, exact URLs, and affected job or project numbers. This helps support resolve the request faster.",
                                    style: TextStyle(color: Colors.blue.shade900, fontSize: 12, height: 1.5),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_controller.quickActions?.links != null)
                                  ..._controller.quickActions!.links.map((link) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: InkWell(
                                        onTap: () async {
                                          final uri = Uri.parse(link.url);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri);
                                          }
                                        },
                                        child: Text(link.title, style: TextStyle(color: Colors.blue.shade700, decoration: TextDecoration.underline, fontSize: 13)),
                                      ),
                                    );
                                  }).toList(),
                              ],
                            )
                          ),
                          const SizedBox(height: 24),
                          
                          _buildCard(
                            title: "Before You Send",
                            icon: Icons.checklist,
                            child: Column(
                              children: [
                                _buildBeforeSendItem(Icons.link, "Copy the page URL", "Paste the exact page where the issue appears."),
                                _buildBeforeSendItem(Icons.badge_outlined, "Add record numbers", "Include project, job, form submission, or user email details."),
                              ],
                            )
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              );
            }
          ),
        ),
      ],
    );
  }
}
