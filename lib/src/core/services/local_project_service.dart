import 'dart:typed_data';

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
}) async {
  final ids = <String>[];
  for (final f in frames) {
    if (!f.isNew) {
      ids.add(f.existingId!);
    } else {
      final jpeg = compressFrameJpeg(f.bytes!);
      ids.add(await repo.addFrame(jpeg));
    }
  }

  final project = QuackProject(
    id: id,
    name: name,
    artistName: artistName,
    photoPaths: ids,
    date: date ?? DateTime.now(),
    isPublished: isPublished,
    workshopCode: workshopCode,
  );
  return repo.saveProject(project);
}
