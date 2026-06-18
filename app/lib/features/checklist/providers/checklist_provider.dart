import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class ChecklistItem {
  final String id;
  final String projectId;
  final String? parentId;
  final String title;
  final int sortOrder;
  final bool isLeaf;
  final String createdBy;
  final DateTime createdAt;

  const ChecklistItem({
    required this.id,
    required this.projectId,
    this.parentId,
    required this.title,
    this.sortOrder = 0,
    this.isLeaf = true,
    required this.createdBy,
    required this.createdAt,
  });

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      parentId: map['parent_id'] as String?,
      title: map['title'] as String,
      sortOrder: (map['sort_order'] as num).toInt(),
      isLeaf: map['is_leaf'] as bool,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

final allItemsProvider = FutureProvider.family<List<ChecklistItem>, String>((ref, projectId) async {
  final client = ref.read(supabaseProvider);
  final items = await client.from('checklist_items').select().eq('project_id', projectId).order('sort_order');
  return (items as List).map((e) => ChecklistItem.fromMap(e as Map<String, dynamic>)).toList();
});

final createChecklistItemProvider = FutureProvider.family<void, ({String projectId, String? parentId, String title, bool isLeaf, String userId})>((ref, data) async {
  final client = ref.read(supabaseProvider);
  final maxOrder = await client.from('checklist_items').select('sort_order').eq('project_id', data.projectId).order('sort_order', ascending: false).limit(1);
  final sortOrder = maxOrder.isNotEmpty ? ((maxOrder.first as Map)['sort_order'] as num).toInt() + 1 : 0;
  final Map<String, dynamic> insertData = {
    'project_id': data.projectId,
    'title': data.title,
    'is_leaf': data.isLeaf,
    'sort_order': sortOrder,
    'created_by': data.userId,
  };
  if (data.parentId != null) {
    insertData['parent_id'] = data.parentId;
  }
  await client.from('checklist_items').insert(insertData);
  ref.invalidate(allItemsProvider(data.projectId));
  ref.invalidate(completedItemsProvider(data.projectId));
});

final updateChecklistItemProvider = FutureProvider.family<void, ({String id, String title, String projectId})>((ref, data) async {
  final client = ref.read(supabaseProvider);
  await client.from('checklist_items').update({
    'title': data.title,
  }).eq('id', data.id);
  ref.invalidate(allItemsProvider(data.projectId));
});

final deleteChecklistItemProvider = FutureProvider.family<void, ({String id, String projectId})>((ref, data) async {
  final client = ref.read(supabaseProvider);
  await client.from('checklist_items').delete().eq('id', data.id);
  ref.invalidate(allItemsProvider(data.projectId));
  ref.invalidate(completedItemsProvider(data.projectId));
});

final toggleTaskCompletionProvider = FutureProvider.family<void, ({String itemId, String projectId, String userId})>((ref, data) async {
  final client = ref.read(supabaseProvider);
  final existing = await client.from('task_completions').select('id').eq('user_id', data.userId).eq('item_id', data.itemId).maybeSingle();
  if (existing != null) {
    await client.from('task_completions').delete().eq('user_id', data.userId).eq('item_id', data.itemId);
  } else {
    await client.from('task_completions').insert({
      'user_id': data.userId,
      'item_id': data.itemId,
      'project_id': data.projectId,
    });
  }
  ref.invalidate(completedItemsProvider(data.projectId));
});

final completedItemsProvider = FutureProvider.family<Set<String>, String>((ref, projectId) async {
  final client = ref.read(supabaseProvider);
  final userId = ref.read(authUserProvider)?.id;
  if (userId == null) return {};
  final rows = await client.from('task_completions').select('item_id').eq('user_id', userId).eq('project_id', projectId);
  return (rows as List).map((e) => (e as Map)['item_id'] as String).toSet();
});
