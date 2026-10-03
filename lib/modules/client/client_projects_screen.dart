import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../projects/projects_screen.dart';
import 'package:iconly/iconly.dart';

class ClientProjectsScreen extends StatelessWidget {
  final Client client;

  const ClientProjectsScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F2C4A) : const Color(0xffF5F7FB);
    final appBarBg = isDark ? const Color(0xFF0F2C4A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F2C4A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: appBarBg,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          '${client.name} Projects',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(IconlyLight.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ProjectsScreen(filterClient: client),
    );
  }
}
