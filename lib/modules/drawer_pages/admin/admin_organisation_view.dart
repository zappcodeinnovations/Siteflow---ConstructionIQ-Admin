import 'package:flutter/material.dart';
import 'admin_organisation_controller.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/theme/app_theme.dart';
import 'package:iconly/iconly.dart';

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
        if (_controller.currencies.contains(
          _controller.organisation!.currency,
        )) {
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

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: textColor.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(24), child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final fieldFillColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade50;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                "Organisation Settings",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Manage your organisation profile, name, and default currency.",
                style: TextStyle(color: subtitleColor, fontSize: 14),
              ),
              const SizedBox(height: 32),

              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  if (_controller.isLoading) {
                    return const ShimmerLoadingDashboard();
                  }

                  return Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCard(
                            title: "Profile Information",
                            icon: IconlyLight.profile,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Organisation Name",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _nameController,
                                  style: TextStyle(color: textColor),
                                  decoration: InputDecoration(
                                    hintText:
                                        "e.g. Euroside Construction Limited",
                                    hintStyle: TextStyle(color: subtitleColor),
                                    filled: true,
                                    fillColor: fieldFillColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _buildCard(
                            title: "Financial Settings",
                            icon: IconlyLight.category,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Default Currency",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _selectedCurrency,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: fieldFillColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  dropdownColor: isDark ? AppTheme.corporateBlue : Colors.white,
                                  icon: Icon(
                                    IconlyLight.arrow_down_2,
                                    color: subtitleColor,
                                    size: 20,
                                  ),
                                  items: _controller.currencies.map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
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

                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: isMobile ? double.infinity : null,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D6EFD),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _controller.isSaving
                                    ? null
                                    : () async {
                                        final result = await _controller
                                            .saveOrganisation(
                                              _nameController.text.trim(),
                                              _selectedCurrency,
                                            );
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(result['message']),
                                              backgroundColor: result['success']
                                                  ? Colors.green.shade600
                                                  : Colors.red.shade600,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                child: _controller.isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            IconlyLight.tick_square,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Save Changes",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
