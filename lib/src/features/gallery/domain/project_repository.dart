import 'dart:typed_data';

import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';

/// Contrato de persistencia de proyectos y cuadros.
///
/// La demo usa una implementación local (Hive) donde los cuadros se guardan
/// como **datos (bytes)**, no como URLs. Más adelante se podrá reemplazar por
/// una implementación Cloudflare sin tocar las pantallas (ver
/// docs/decisiones/0001-modo-local-demo.md).
///
/// Modelo de cuadros:
/// - Cada cuadro se guarda una sola vez bajo un **id único y estable**
///   (ver [addFrame]).
/// - [QuackProject.photoPaths] es la **lista ordenada de ids de cuadro** del
///   proyecto (no URLs ni rutas).
/// - Reordenar o duplicar un cuadro (HDU3/T7) solo cambia esa lista: duplicar
///   es repetir un id, por lo que los bytes no se copian.
/// - Varias versiones o proyectos (HDU5/T9) pueden referenciar el mismo id y
///   así **compartir cuadros sin duplicarlos**.
abstract interface class ProjectRepository {
  /// Abre/prepara el almacén. Debe llamarse una vez antes de usarse.
  Future<void> init();

  /// Todos los proyectos, del más reciente al más antiguo.
  Future<List<QuackProject>> loadProjects();

  /// Un proyecto por id, o null si no existe.
  Future<QuackProject?> getProject(String id);

  /// Crea o actualiza los **metadatos** de un proyecto (incluida la lista
  /// ordenada de ids de cuadro en [QuackProject.photoPaths]).
  ///
  /// No gestiona bytes de cuadros: estos se agregan antes con [addFrame] y se
  /// referencian por id. Los cuadros que dejen de estar referenciados por
  /// ningún proyecto se pueden limpiar con [pruneOrphanFrames].
  Future<QuackProject> saveProject(QuackProject project);

  /// Elimina el proyecto y limpia los cuadros que ya no referencie ningún otro
  /// proyecto (los compartidos se conservan).
  Future<void> deleteProject(String id);

  /// Guarda los bytes de un cuadro y devuelve su **id único y estable**.
  /// Llamar una vez por cuadro nuevo capturado.
  Future<String> addFrame(Uint8List bytes);

  /// Bytes de un cuadro por su id (un elemento de [QuackProject.photoPaths]).
  Future<Uint8List?> loadFrameBytes(String frameId);

  /// Bytes de todos los cuadros de un proyecto, en el orden de
  /// [QuackProject.photoPaths].
  Future<List<Uint8List>> loadFrames(String projectId);

  /// Elimina los cuadros que no referencie ningún proyecto (p. ej. capturas de
  /// una sesión que no se llegó a guardar). Devuelve cuántos eliminó.
  Future<int> pruneOrphanFrames();
}
