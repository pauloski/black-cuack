import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:blackcuack_studio/src/core/utils/frame_codec.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_repository.dart';

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
}) async {
  final ids = <String>[];
  final sw = Stopwatch();
  int newCount = 0;
  for (final f in frames) {
    if (!f.isNew) {
      ids.add(f.existingId!);
    } else {
      sw.start();
      final jpeg = compressFrameJpeg(f.bytes!, aspect: aspectValue(aspect));
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
    workshopCode: workshopCode,
    isDraft: isDraft,
    aspect: aspect,
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
}) async {
  final project = QuackProject(
    id: id,
    name: name,
    artistName: artistName,
    photoPaths: frameIds,
    date: DateTime.now(),
    isDraft: true,
    aspect: aspect,
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
}) async {
  final project = QuackProject(
    id: 'v_${DateTime.now().microsecondsSinceEpoch}',
    name: name ?? 'Versión',
    artistName: author,
    photoPaths: List<String>.of(frameIds),
    date: DateTime.now(),
    aspect: aspect,
    parentId: parentId,
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
