import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:blackcuack_studio/src/core/utils/frame_codec.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/features/profile/data/profile_service.dart'
    show activeProfileId;
import 'package:blackcuack_studio/src/features/workshop/data/workshop_service.dart'
    show activeWorkshopCode;
import 'package:blackcuack_studio/src/features/gallery/domain/project_repository.dart';

/// Código de sala activa como valor nulo-seguro ('' → null) para etiquetar el
/// proyecto/versión de la sesión.
String? get _activeWorkshopOrNull =>
    activeWorkshopCode.isEmpty ? null : activeWorkshopCode;

/// Une al dueño (perfil activo) con la lista de miembros, sin vacíos ni
/// duplicados. El dueño siempre es miembro.
List<String> _withOwner(List<String> members) {
  return <String>{
    if (activeProfileId.isNotEmpty) activeProfileId,
    ...members.where((m) => m.isNotEmpty),
  }.toList();
}

/// Un cuadro al momento de guardar: o ya existe en el repo (se reusa su id,
/// **sin recomprimir**), o es nuevo (bytes crudos que se comprimen).
class CapturedFrame {
  final String? existingId;
  final Uint8List? bytes;

  const CapturedFrame._(this.existingId, this.bytes);

  /// Cuadro ya guardado: se reutiliza su id sin tocar los bytes.
  factory CapturedFrame.existing(String id) => CapturedFrame._(id, null);

  /// Cuadro nuevo: se comprime y se guarda.
  factory CapturedFrame.raw(Uint8List bytes) => CapturedFrame._(null, bytes);

  bool get isNew => existingId == null;
}

/// Guarda (crea o actualiza) un proyecto local a partir de cuadros capturados.
///
/// Los cuadros existentes conservan su id y **no se recomprimen**; los nuevos se
/// comprimen (JPEG ≤1280) y se agregan al repo. [QuackProject.photoPaths] queda
/// con los ids en el orden dado.
Future<QuackProject> saveCapturedProject(
  ProjectRepository repo, {
  required String id,
  required String name,
  required String artistName,
  required List<CapturedFrame> frames,
  DateTime? date,
  bool isPublished = false,
  String? workshopCode,
  bool isDraft = false,
  String aspect = '9:16',
  List<String> memberProfileIds = const [],
}) async {
  final ids = <String>[];
  final sw = Stopwatch();
  int newCount = 0;
  for (final f in frames) {
    if (!f.isNew) {
      ids.add(f.existingId!);
    } else {
      sw.start();
      // Sin recorte (aspecto del sensor); el recorte al proyecto va en export/player.
      final jpeg = compressFrameJpeg(f.bytes!);
      sw.stop();
      newCount++;
      ids.add(await repo.addFrame(jpeg));
    }
  }
  if (newCount > 0) {
    // Medición para decidir compresión al capturar vs al guardar (umbral 300 ms/cuadro).
    debugPrint(
      '⏱️ compresión: ${sw.elapsedMilliseconds}ms / $newCount cuadros nuevos '
      '= ${(sw.elapsedMilliseconds / newCount).toStringAsFixed(1)} ms/cuadro',
    );
  }

  final project = QuackProject(
    id: id,
    name: name,
    artistName: artistName,
    photoPaths: ids,
    date: date ?? DateTime.now(),
    isPublished: isPublished,
    // Sala del taller: usa la seleccionada (grupo nube) o, si no, la sala activa.
    workshopCode: workshopCode ?? _activeWorkshopOrNull,
    isDraft: isDraft,
    aspect: aspect,
    ownerProfileId: activeProfileId,
    memberProfileIds: _withOwner(memberProfileIds),
  );
  return repo.saveProject(project);
}

/// Persiste un **borrador** incremental: un proyecto en curso (isDraft) con los
/// ids de cuadro ya existentes en el repo. Así, tras un cierre inesperado, el
/// trabajo no se pierde y sus cuadros no cuentan como huérfanos (están
/// referenciados por el borrador).
Future<QuackProject> saveDraft(
  ProjectRepository repo, {
  required String id,
  required List<String> frameIds,
  String name = 'Borrador',
  String artistName = '',
  String aspect = '9:16',
  List<String> memberProfileIds = const [],
}) async {
  final project = QuackProject(
    id: id,
    name: name,
    artistName: artistName,
    photoPaths: frameIds,
    date: DateTime.now(),
    isDraft: true,
    aspect: aspect,
    workshopCode: _activeWorkshopOrNull,
    ownerProfileId: activeProfileId,
    memberProfileIds: _withOwner(memberProfileIds),
  );
  return repo.saveProject(project);
}

/// Guarda una **versión** (snapshot) del proyecto [parentId]. Comparte los
/// cuadros por id (no duplica bytes). Registra fecha, autor y nº de cuadros
/// (= photoPaths.length).
Future<QuackProject> saveVersion(
  ProjectRepository repo, {
  required String parentId,
  required List<String> frameIds,
  String author = '',
  String aspect = '9:16',
  String? name,
  String authorRole = '',
  bool isCollaborative = false,
  // Participantes de la versión (ids de perfil). Si hay varios, es colaborativa.
  List<String> participantIds = const [],
}) async {
  final participants = participantIds.where((p) => p.isNotEmpty).toList();
  final project = QuackProject(
    id: 'v_${DateTime.now().microsecondsSinceEpoch}',
    name: name ?? 'Versión',
    artistName: author,
    photoPaths: List<String>.of(frameIds),
    date: DateTime.now(),
    aspect: aspect,
    parentId: parentId,
    workshopCode: _activeWorkshopOrNull,
    ownerProfileId: activeProfileId,
    authorRole: authorRole,
    isCollaborative: isCollaborative || participants.length > 1,
    memberProfileIds: participants,
  );
  return repo.saveProject(project);
}

/// Versiones de un proyecto, de la más reciente a la más antigua.
Future<List<QuackProject>> listVersions(
    ProjectRepository repo, String parentId) async {
  final all = await repo.loadProjects();
  final versions = all.where((p) => p.parentId == parentId).toList();
  versions.sort((a, b) => b.date.compareTo(a.date));
  return versions;
}
