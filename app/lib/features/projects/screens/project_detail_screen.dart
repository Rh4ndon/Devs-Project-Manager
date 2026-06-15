import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/projects_provider.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return projectsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (projects) {
        final project = projects.where((p) => p.id == projectId).firstOrNull;
        if (project == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Project not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(project.name)),
          body: const Center(child: Text('Checklist coming next')),
        );
      },
    );
  }
}
