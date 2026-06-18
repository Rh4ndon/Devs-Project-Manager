import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/projects_provider.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProjectCard({super.key, required this.project, this.onEdit, this.onDelete});

  String _deadlineText(String deadline) {
    final date = DateTime.tryParse(deadline);
    if (date == null) return '';
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff < 0) return 'Overdue by ${-diff}d';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff <= 7) return '$diff days left';
    return DateFormat.yMMMd().format(date);
  }

  Color _deadlineColor(BuildContext context, String deadline) {
    final date = DateTime.tryParse(deadline);
    if (date == null) return Theme.of(context).colorScheme.onSurfaceVariant;
    final now = DateTime.now();
    final diff = date.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff < 0) return Theme.of(context).colorScheme.error;
    if (diff <= 3) return Colors.orange;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

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
        title: Text(project.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.description != null && project.description!.isNotEmpty)
              Text(project.description!, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    'Created ${DateFormat.yMMMd().format(project.createdAt)}',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (project.deadline != null) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.schedule, size: 12, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      _deadlineText(project.deadline!),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _deadlineColor(context, project.deadline!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: SizedBox(
          width: 40,
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit?.call();
              if (value == 'delete') onDelete?.call();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'delete', child: ListTile(
                leading: Icon(Icons.delete_outlined),
                title: Text('Delete'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
        ),
        onTap: () => context.push('/projects/${project.id}'),
      ),
    );
  }
}
