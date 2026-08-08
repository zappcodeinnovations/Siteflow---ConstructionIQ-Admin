import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../../../../models/admin_guest_model.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../core/theme/app_theme.dart';
import 'admin_guests_controller.dart';
import 'invite_guest_dialog.dart';
import 'edit_guest_dialog.dart';
import 'guest_details_dialog.dart';

class AdminGuestsView extends StatefulWidget {
  const AdminGuestsView({super.key});

  @override
  State<AdminGuestsView> createState() => _AdminGuestsViewState();
}

class _AdminGuestsViewState extends State<AdminGuestsView> {
  final AdminGuestsController _controller = AdminGuestsController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _controller.fetchGuests();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => InviteGuestDialog(controller: _controller),
    );
  }

  void _deleteGuest(AdminGuest guest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Guest"),
        content: Text("Are you sure you want to remove ${guest.email}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final result = await _controller.deleteGuest(guest.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success'] == true
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _editGuest(AdminGuest guest) {
    showDialog(
      context: context,
      builder: (context) =>
          EditGuestDialog(guest: guest, controller: _controller),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF0F2C4A),
      const Color(0xFF0D6EFD),
      const Color(0xFF6C757D),
      Colors.teal,
      Colors.indigo,
    ];
    int hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
    return colors[hash % colors.length];
  }

  Widget _buildGuestCard(
    AdminGuest guest, {
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final initials = guest.displayName.isNotEmpty
        ? guest.displayName.substring(0, 2).toUpperCase()
        : "G";
    final avatarColor = _getAvatarColor(guest.displayName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: "Dismiss",
              transitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (context, animation, secondaryAnimation) {
                return GuestDetailsDialog(
                  guestId: guest.id,
                  controller: _controller,
                );
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: avatarColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        if (guest.isActive)
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guest.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            guest.email,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "GUEST",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        IconlyLight.more_circle,
                        color: Colors.grey,
                      ),
                      onSelected: (val) {
                        if (val == 'edit') _editGuest(guest);
                        if (val == 'delete') _deleteGuest(guest);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text("Edit Guest"),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            "Remove Guest",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 32,
                  runSpacing: 16,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "USERNAME",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          guest.username.isNotEmpty ? guest.username : "N/A",
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "PHONE",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          guest.phone.isNotEmpty ? guest.phone : "N/A",
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.corporateBlue : Colors.white;
    final headerBg = isDark ? AppTheme.corporateBlue : Colors.grey.shade50;
    final headerTitle = isDark ? Colors.white : const Color(0xFF0F2C4A);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;
    final searchFillColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.corporateBlue : null,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final filteredGuests = _controller.guests
              .where(
                (g) =>
                    g.displayName.toLowerCase().contains(_searchQuery) ||
                    g.email.toLowerCase().contains(_searchQuery),
              )
              .toList();

          final totalGuests = _controller.guests.length;

          return Column(
            children: [
              // Header & Search
              Container(
                color: headerBg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Guests\nDirectory",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: headerTitle,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "$totalGuests Guests Total",
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D6EFD),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _showInviteDialog,
                          icon: const Icon(
                            IconlyLight.add_user,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            "Invite Guest",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    TextField(
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Search guests...",
                        hintStyle: TextStyle(color: subtitleColor),
                        prefixIcon: Icon(
                          IconlyLight.search,
                          color: subtitleColor,
                        ),
                        filled: true,
                        fillColor: searchFillColor,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                      ),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ],
                ),
              ),

              // Guests List
              Expanded(
                child: _controller.isLoading && _controller.guests.isEmpty
                    ? const ShimmerLoadingList()
                    : _controller.errorMessage != null &&
                          _controller.guests.isEmpty
                    ? Center(
                        child: Text(
                          _controller.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredGuests.length,
                        itemBuilder: (context, index) {
                          return _buildGuestCard(
                            filteredGuests[index],
                            isDark: isDark,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
