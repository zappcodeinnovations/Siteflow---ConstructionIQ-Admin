import 'package:flutter/material.dart';
import '../../models/client_model.dart';
import '../projects/projects_screen.dart';
import 'package:iconly/iconly.dart';

class ClientProjectsScreen extends StatelessWidget {
  final Client client;

  const ClientProjectsScreen({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.surface,
        iconTheme: IconThemeData(color: colors.onSurface),
        title: Text(
          '${client.name} Projects',
          style: TextStyle(
            color: colors.onSurface,
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
