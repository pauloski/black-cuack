import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:universal_html/html.dart' as html;

import 'package:blackcuack_studio/src/features/gallery/data/hive_project_repository.dart';
import 'package:blackcuack_studio/src/features/gallery/data/in_memory_project_repository.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_repository.dart';

/// Repositorio activo de proyectos/cuadros. Se inicializa a un respaldo en
/// memoria (no `late` desnudo) y [initRepositories] lo reemplaza por Hive si
/// este abre bien.
ProjectRepository projectRepository = InMemoryProjectRepository();

/// `true` mientras el almacén activo **no persiste** (respaldo en memoria).
/// La UI debe mostrar un aviso visible en ese caso y no decir "guardado".
bool repositoryIsEphemeral = true;

/// Intenta abrir el almacén local (Hive). Si falla, deja el respaldo en memoria
/// y marca [repositoryIsEphemeral] para que la app lo avise.
Future<void> initRepositories() async {
  try {
    await Hive.initFlutter();
    final repo = HiveProjectRepository();
    await repo.init();
    projectRepository = repo;
    repositoryIsEphemeral = false;
  } catch (e) {
    projectRepository = InMemoryProjectRepository();
    repositoryIsEphemeral = true;
    debugPrint(
      '⚠️ Hive no abrió; almacén en memoria (NO persistente). Causa: $e',
    );
  }
}

/// En web, pide almacenamiento persistente para reducir el desalojo de
/// IndexedDB (Safari/WebKit puede borrarlo tras ~7 días sin visitas). Es
/// best-effort: el navegador puede no concederlo.
Future<void> requestPersistentStorage() async {
  if (!kIsWeb) return;
  try {
    final storage = html.window.navigator.storage;
    if (storage != null) {
      final granted = await storage.persist();
      debugPrint('navigator.storage.persist() → $granted');
    }
  } catch (e) {
    debugPrint('persist() no disponible: $e');
  }
}
