import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget
    implements PreferredSizeWidget {

  final String title;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {

    return AppBar(
      title: Text(title),

      actions: [
        if (actions != null) ...actions!,

        IconButton(
          onPressed: () {
            // TODO: Navigate to notifications
          },
          icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
        ),

        const SizedBox(width: 10),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}