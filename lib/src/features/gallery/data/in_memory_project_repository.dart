import 'dart:math';
import 'dart:typed_data';

import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_repository.dart';

/// Respaldo en memoria cuando Hive no puede abrir (p. ej. IndexedDB bloqueado).
///
/// **No persiste**: al recargar o cerrar se pierde todo. Por eso la app debe
/// avisarlo de forma visible (ver `repositoryIsEphemeral`), nunca en silencio.
class InMemoryProjectRepository implements ProjectRepository {
  final Map<String, QuackProject> _projects = {};
  final Map<String, Uint8List> _frames = {};
  final Random _rng = Random();

  @override
  Future<void> init() async {}

  @override
  Future<List<QuackProject>> loadProjects() async {
    final list = _projects.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<QuackProject?> getProject(String id) async => _projects[id];

  @override
  Future<QuackProject> saveProject(QuackProject project) async {
    _projects[project.id] = project;
    return project;
  }

  @override
  Future<void> deleteProject(String id) async {
    final target = _projects.remove(id);
    if (target == null) return;
    final stillUsed = _referencedFrameIds();
    for (final f in target.photoPaths.toSet()) {
      if (!stillUsed.contains(f)) _frames.remove(f);
    }
  }

  @override
  Future<String> addFrame(Uint8List bytes) async {
    final id = _newFrameId();
    _frames[id] = bytes;
    return id;
  }

  @override
  Future<Uint8List?> loadFrameBytes(String frameId) async => _frames[frameId];

  @override
  Future<List<Uint8List>> loadFrames(String projectId) async {
    final project = _projects[projectId];
    if (project == null) return [];
    final out = <Uint8List>[];
    for (final id in project.photoPaths) {
      final b = _frames[id];
      if (b != null) out.add(b);
    }
    return out;
  }

  @override
  Future<int> pruneOrphanFrames() async {
    final referenced = _referencedFrameIds();
    final orphans = _frames.keys.where((k) => !referenced.contains(k)).toList();
    for (final k in orphans) {
      _frames.remove(k);
    }
    return orphans.length;
  }

  Set<String> _referencedFrameIds() =>
      {for (final p in _projects.values) ...p.photoPaths};

  String _newFrameId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final a = _rng.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final b = _rng.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return 'f_${ts.toRadixString(16)}_$a$b';
  }
}
