import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'admin_support_controller.dart';
import '../../../../models/admin_support_model.dart';
import '../../../core/widgets/shimmer_loading.dart';

class TicketDetailsView extends StatefulWidget {
  final AdminSupportController controller;
  final int ticketId;

  const TicketDetailsView({super.key, required this.controller, required this.ticketId});

  @override
  State<TicketDetailsView> createState() => _TicketDetailsViewState();
}

class _TicketDetailsViewState extends State<TicketDetailsView> {
  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.fetchTicketDetails(widget.ticketId);
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final body = _replyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please type a reply message before sending."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await widget.controller.replyToTicket(widget.ticketId, body);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
      if (result['success']) {
        _replyController.clear();
        FocusScope.of(context).unfocus();
      }
    }
  }

  Future<void> _reopenTicket() async {
    final result = await widget.controller.reopenTicket(widget.ticketId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: result['success'] ? Colors.green : Colors.red),
      );
    }
  }

  Widget _buildStatusPill(String statusDisplay, String statusKey, {bool isDark = false}) {
    Color bg = isDark ? Colors.white12 : Colors.grey.shade100;
    Color fg = isDark ? Colors.white70 : Colors.grey.shade700;
    
    if (statusKey == 'open' || statusKey == 'in_progress') {
      bg = isDark ? const Color(0xFF1E3A8A).withOpacity(0.5) : Colors.blue.shade50;
      fg = isDark ? Colors.lightBlueAccent : Colors.blue.shade700;
    } else if (statusKey == 'resolved' || statusKey == 'closed') {
      bg = isDark ? const Color(0xFF065F46).withOpacity(0.5) : Colors.green.shade50;
      fg = isDark ? Colors.greenAccent : Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(statusDisplay.toUpperCase(), style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildMessageBubble(SupportTicketMessage msg, {bool isDark = false}) {
    final isSupport = msg.senderType != 'user';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isSupport
                ? (isDark ? const Color(0xFF1E3A8A).withOpacity(0.5) : Colors.blue.shade100)
                : (isDark ? const Color(0xFF162A42) : Colors.grey.shade200),
            child: Icon(
              isSupport ? IconlyLight.user_1 : IconlyLight.profile,
              color: isSupport ? (isDark ? Colors.lightBlueAccent : Colors.blue.shade700) : (isDark ? Colors.white70 : Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(msg.senderName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(width: 8),
                    Text(msg.createdAt.split('T').first, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSupport
                        ? (isDark ? const Color(0xFF162A42) : Colors.blue.shade50)
                        : (isDark ? const Color(0xFF0F2C4A) : Colors.white),
                    border: Border.all(
                      color: isSupport
                          ? (isDark ? Colors.blue.withOpacity(0.3) : Colors.blue.shade100)
                          : (isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg.body,
                    style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? Colors.white : Colors.black87),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1929) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Ticket Details", style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF0F2C4A) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading && widget.controller.currentTicketDetails == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final details = widget.controller.currentTicketDetails;
          if (details == null) {
            return Center(
              child: Text(widget.controller.errorMessage ?? "Failed to load ticket details", style: const TextStyle(color: Colors.red)),
            );
          }

          final ticket = details.ticket;
          final isClosed = ticket.status == 'closed' || ticket.status == 'resolved';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Ticket Header
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F2C4A) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Ticket #${ticket.ticketNumber}", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                    _buildStatusPill(ticket.statusDisplay, ticket.status, isDark: isDark),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(ticket.subject, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
                                const SizedBox(height: 16),
                                Divider(height: 1, color: isDark ? Colors.white12 : null),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 24,
                                  runSpacing: 12,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(IconlyLight.category, size: 16, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                        const SizedBox(width: 8),
                                        Text("Category: ${ticket.categoryDisplay}", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade800)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(IconlyLight.bookmark, size: 16, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                        const SizedBox(width: 8),
                                        Text("Priority: ${ticket.priorityDisplay}", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade800)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          Text("Conversation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF0F2C4A))),
                          const SizedBox(height: 24),

                          ...details.messages.map((m) => _buildMessageBubble(m, isDark: isDark)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Reply Box
              SafeArea(
                top: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F2C4A) : Colors.white,
                    border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, -4))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: isClosed 
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("This ticket is closed.", style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              ElevatedButton.icon(
                                onPressed: widget.controller.isSubmitting ? null : _reopenTicket,
                                icon: widget.controller.isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
                                label: const Text("Reopen Ticket"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade50,
                                  foregroundColor: Colors.orange.shade800,
                                  elevation: 0,
                                ),
                              )
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _replyController,
                                  maxLines: 4,
                                  minLines: 1,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: InputDecoration(
                                    hintText: "Type your reply here...",
                                    hintStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade500),
                                    filled: true,
                                    fillColor: isDark ? const Color(0xFF162A42) : Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5)),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: widget.controller.isSubmitting ? null : _sendReply,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D6EFD),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: widget.controller.isSubmitting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text("Reply", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }
}