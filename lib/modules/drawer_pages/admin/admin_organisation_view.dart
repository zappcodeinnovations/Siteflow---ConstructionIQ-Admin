import 'package:flutter/material.dart';
import 'admin_organisation_controller.dart';
import '../../../core/widgets/shimmer_loading.dart';

class AdminOrganisationView extends StatefulWidget {
  const AdminOrganisationView({super.key});

  @override
  State<AdminOrganisationView> createState() => _AdminOrganisationViewState();
}

class _AdminOrganisationViewState extends State<AdminOrganisationView> {
  final AdminOrganisationController _controller = AdminOrganisationController();
  final _nameController = TextEditingController();
  String _selectedCurrency = 'GBP';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _controller.fetchCurrencies();
    await _controller.fetchOrganisation();
    if (_controller.organisation != null) {
      setState(() {
        _nameController.text = _controller.organisation!.name;
        if (_controller.currencies.contains(_controller.organisation!.currency)) {
          _selectedCurrency = _controller.organisation!.currency;
        } else if (_controller.currencies.isNotEmpty) {
          _selectedCurrency = _controller.currencies.first;
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        const Text("Organisation", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F2C4A))),
        const SizedBox(height: 4),
        Text("Manage your organisation profile and settings", style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 32),

        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const ShimmerLoadingDashboard();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCard(
                  title: "Profile",
                  icon: Icons.person_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Organisation name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                _buildCard(
                  title: "Currency",
                  icon: Icons.payments_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Select Currency", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _controller.currencies.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCurrency = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),

                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _controller.isSaving 
                        ? null 
                        : () async {
                            final result = await _controller.saveOrganisation(_nameController.text.trim(), _selectedCurrency);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(result['message']), backgroundColor: result['success'] ? Colors.green : Colors.red),
                              );
                            }
                          },
                    child: _controller.isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          }
        ),
      ],
    );
  }
}
