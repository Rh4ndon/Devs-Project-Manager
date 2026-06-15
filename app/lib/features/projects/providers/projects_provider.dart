import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

class Project {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.createdAt,
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      ownerId: map['owner_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'owner_id': ownerId,
    };
  }
}

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final client = ref.read(supabaseProvider);
  final userId = ref.watch(authUserProvider)?.id;
  if (userId == null) return [];

  final response = await client
      .from('projects')
      .select()
      .order('created_at', ascending: false);

  return (response as List).map((e) => Project.fromMap(e as Map<String, dynamic>)).toList();
});

final createProjectProvider = FutureProvider.family<void, Project>((ref, project) async {
  final client = ref.read(supabaseProvider);
  await client.from('projects').insert(project.toMap());
  ref.invalidate(projectsProvider);
});

final deleteProjectProvider = FutureProvider.family<void, String>((ref, projectId) async {
  final client = ref.read(supabaseProvider);
  await client.from('projects').delete().eq('id', projectId);
  ref.invalidate(projectsProvider);
});

final updateProjectProvider = FutureProvider.family<void, ({String id, String name, String? description})>((ref, data) async {
  final client = ref.read(supabaseProvider);
  await client.from('projects').update({
    'name': data.name,
    if (data.description != null) 'description': data.description,
  }).eq('id', data.id);
  ref.invalidate(projectsProvider);
});
