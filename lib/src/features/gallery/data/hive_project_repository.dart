import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:hive_ce/hive.dart';

import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_repository.dart';

/// Implementación local-first con Hive CE.
///
/// - En web usa IndexedDB; en nativo, archivos. La inicialización de Hive
///   (`Hive.initFlutter()` en la app, `Hive.init(path)` en tests) la hace quien
///   construye el repositorio, antes de llamar a [init].
/// - Caja `bq_projects`: metadatos del proyecto como JSON (String), por id.
/// - Caja `bq_frames`: bytes de cada cuadro (`Uint8List`), por **id de cuadro**
///   único y estable. Un mismo id puede estar referenciado por varios proyectos
///   o versiones (cuadros compartidos) y por la misma lista más de una vez
///   (cuadro duplicado).
class HiveProjectRepository implements ProjectRepository {
  static const String projectsBoxName = 'bq_projects';
  static const String framesBoxName = 'bq_frames';

  late Box<String> _projects;
  late Box<Uint8List> _frames;

  final Random _rng = Random();

  @override
  Future<void> init() async {
    _projects = await Hive.openBox<String>(projectsBoxName);
    _frames = await Hive.openBox<Uint8List>(framesBoxName);
  }

  /// Id de cuadro único y estable, sin dependencias externas:
  /// marca de microsegundos + 64 bits aleatorios.
  String _newFrameId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final a = _rng.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final b = _rng.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return 'f_${ts.toRadixString(16)}_$a$b';
  }

  @override
  Future<List<QuackProject>> loadProjects() async {
    final projects = _projects.values
        .map((json) => QuackProject.fromJson(
              jsonDecode(json) as Map<String, dynamic>,
            ))
        .toList();
    // Más reciente primero.
    projects.sort((a, b) => b.date.compareTo(a.date));
    return projects;
  }

  @override
  Future<QuackProject?> getProject(String id) async {
    final json = _projects.get(id);
    if (json == null) return null;
    return QuackProject.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  Future<QuackProject> saveProject(QuackProject project) async {
    await _projects.put(project.id, jsonEncode(project.toJson()));
    return project;
  }

  @override
  Future<void> deleteProject(String id) async {
    final target = await getProject(id);
    await _projects.delete(id);
    if (target == null) return;
    // Conserva los cuadros que aún referencie algún otro proyecto.
    final stillUsed = await _referencedFrameIds();
    final toDelete =
        target.photoPaths.toSet().where((f) => !stillUsed.contains(f));
    await _frames.deleteAll(toDelete);
  }

  @override
  Future<String> addFrame(Uint8List bytes) async {
    final id = _newFrameId();
    await _frames.put(id, bytes);
    return id;
  }

  @override
  Future<Uint8List?> loadFrameBytes(String frameId) async {
    return _frames.get(frameId);
  }

  @override
  Future<List<Uint8List>> loadFrames(String projectId) async {
    final project = await getProject(projectId);
    if (project == null) return [];
    final frames = <Uint8List>[];
    for (final id in project.photoPaths) {
      final bytes = _frames.get(id);
      if (bytes != null) frames.add(bytes);
    }
    return frames;
  }

  @override
  Future<int> pruneOrphanFrames() async {
    final referenced = await _referencedFrameIds();
    final orphans = _frames.keys
        .whereType<String>()
        .where((k) => !referenced.contains(k))
        .toList();
    await _frames.deleteAll(orphans);
    return orphans.length;
  }

  /// Todos los ids de cuadro referenciados por algún proyecto guardado.
  Future<Set<String>> _referencedFrameIds() async {
    final projects = await loadProjects();
    return {for (final p in projects) ...p.photoPaths};
  }
}
