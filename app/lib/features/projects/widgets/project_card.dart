import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/projects_provider.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onDelete;

  const ProjectCard({super.key, required this.project, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            project.name[0].toUpperCase(),
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.description != null && project.description!.isNotEmpty)
              Text(project.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              'Created ${DateFormat.yMMMd().format(project.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') onDelete?.call();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => context.push('/projects/${project.id}'),
      ),
    );
  }
}
