import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../projects/projects_screen.dart';
import 'package:iconly/iconly.dart';

class ClientProjectsScreen extends StatelessWidget {
  final Client client;

  const ClientProjectsScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          '${client.name} Projects',
          style: const TextStyle(
            color: Color(0xFF0F2C4A),
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
