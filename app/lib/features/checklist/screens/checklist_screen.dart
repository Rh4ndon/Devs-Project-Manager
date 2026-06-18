import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../providers/checklist_provider.dart';

class _TreeNode {
  final ChecklistItem item;
  final List<_TreeNode> children;
  _TreeNode(this.item, this.children);
}

List<_TreeNode> _buildTree(List<ChecklistItem> items) {
  final Map<String?, List<ChecklistItem>> byParent = {};
  for (final item in items) {
    byParent.putIfAbsent(item.parentId, () => []).add(item);
  }
  List<_TreeNode> _buildChildren(String? parentId) {
    final children = byParent[parentId] ?? [];
    return children.map((item) {
      return _TreeNode(item, _buildChildren(item.id));
    }).toList();
  }
  return _buildChildren(null);
}

class ChecklistScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String projectName;
  const ChecklistScreen({super.key, required this.projectId, required this.projectName});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  final Set<String> _expanded = {};

  bool _allExpanded = false;

  void _toggleExpand(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  void _collapseAll() {
    setState(() => _expanded.clear());
  }

  void _expandAll(List<_TreeNode> roots) {
    final all = <String>{};
    void collect(_TreeNode node) {
      if (node.children.isNotEmpty) {
        all.add(node.item.id);
        for (final child in node.children) {
          collect(child);
        }
      }
    }
    for (final root in roots) {
      collect(root);
    }
    setState(() => _expanded.addAll(all));
  }

  Future<void> _addItem({String? parentId, String? parentTitle}) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(parentTitle != null ? 'New sub-item in $parentTitle' : 'New item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Add as task'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, false);
            },
            child: const Text('Add as group'),
          ),
        ],
      ),
    );
    if (result == null || controller.text.trim().isEmpty) return;
    final userId = ref.read(authUserProvider)?.id;
    if (userId == null) return;
    await ref.read(createChecklistItemProvider((
      projectId: widget.projectId,
      parentId: parentId,
      title: controller.text.trim(),
      isLeaf: result,
      userId: userId,
    )).future);
  }

  Future<void> _editItem(ChecklistItem item) async {
    final controller = TextEditingController(text: item.title);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(updateChecklistItemProvider((
      id: item.id,
      title: controller.text.trim(),
      projectId: widget.projectId,
    )).future);
  }

  Future<void> _deleteItem(ChecklistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text(item.isLeaf ? 'This cannot be undone.' : 'All sub-items will also be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(deleteChecklistItemProvider((
      id: item.id,
      projectId: widget.projectId,
    )).future);
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(allItemsProvider(widget.projectId));
    final completedAsync = ref.watch(completedItemsProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.projectName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.unfold_less),
            tooltip: 'Collapse all',
            onPressed: _collapseAll,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          final completed = completedAsync.valueOrNull ?? {};
          final roots = _buildTree(items);

          if (roots.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.checklist, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('No items yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  const Text('Tap + to add a task or group'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allItemsProvider(widget.projectId));
              ref.invalidate(completedItemsProvider(widget.projectId));
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final root in roots)
                  _TreeNodeWidget(
                    node: root,
                    depth: 0,
                    completed: completed,
                    expanded: _expanded,
                    onToggle: _toggleExpand,
                    onToggleComplete: (item) {
                      final userId = ref.read(authUserProvider)?.id;
                      if (userId == null) return;
                      ref.read(toggleTaskCompletionProvider((
                        itemId: item.id,
                        projectId: widget.projectId,
                        userId: userId,
                      )).future);
                    },
                    onEdit: _editItem,
                    onDelete: _deleteItem,
                    onAddChild: (parent) => _addItem(parentId: parent.id, parentTitle: parent.title),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TreeNodeWidget extends StatelessWidget {
  final _TreeNode node;
  final int depth;
  final Set<String> completed;
  final Set<String> expanded;
  final void Function(String) onToggle;
  final void Function(ChecklistItem) onToggleComplete;
  final void Function(ChecklistItem) onEdit;
  final void Function(ChecklistItem) onDelete;
  final void Function(ChecklistItem)? onAddChild;

  const _TreeNodeWidget({
    required this.node,
    required this.depth,
    required this.completed,
    required this.expanded,
    required this.onToggle,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    final item = node.item;
    final isExpanded = expanded.contains(item.id);
    final isCompleted = completed.contains(item.id);
    final hasChildren = node.children.isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.0 + depth * 24),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: ListTile(
              dense: true,
              leading: IconButton(
                icon: Icon(
                  !item.isLeaf
                      ? (isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right)
                      : (isCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
                  size: 20,
                  color: isCompleted
                      ? colorScheme.primary
                      : (!item.isLeaf ? colorScheme.primary : colorScheme.onSurfaceVariant),
                ),
                onPressed: () {
                  if (!item.isLeaf) {
                    onToggle(item.id);
                  } else {
                    onToggleComplete(item);
                  }
                },
              ),
              title: Text(
                item.title,
                style: TextStyle(
                  fontSize: 14,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? colorScheme.onSurfaceVariant : null,
                ),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit(item);
                  if (value == 'delete') onDelete(item);
                  if (value == 'addChild') onAddChild?.call(item);
                },
                itemBuilder: (_) => [
                  if (!item.isLeaf)
                    const PopupMenuItem(value: 'addChild', child: ListTile(
                      leading: Icon(Icons.add),
                      title: Text('Add sub-item'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    )),
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
          ),
        ),
        if (hasChildren && isExpanded)
          ...node.children.map(
            (child) => _TreeNodeWidget(
              node: child,
              depth: depth + 1,
              completed: completed,
              expanded: expanded,
              onToggle: onToggle,
              onToggleComplete: onToggleComplete,
              onEdit: onEdit,
              onDelete: onDelete,
              onAddChild: onAddChild,
            ),
          ),
      ],
    );
  }
}
