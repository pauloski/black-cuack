import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image/image.dart' as img;

import 'package:blackcuack_studio/src/features/gallery/data/hive_project_repository.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/core/services/local_project_service.dart';
import 'package:blackcuack_studio/src/features/profile/data/profile_service.dart'
    as profile;

Uint8List _png(int w, int h) {
  final im = img.Image(width: w, height: h);
  img.fill(im, color: img.ColorRgb8(30, 90, 200));
  return Uint8List.fromList(img.encodePng(im));
}

/// Réplica del filtro de "Mis proyectos" (project_grid_view): proyectos del
/// perfil activo, con cuadros y que no son versiones.
List<QuackProject> visibleFor(List<QuackProject> all, String profileId) => all
    .where((p) =>
        p.photoPaths.isNotEmpty &&
        p.parentId == null &&
        p.ownerProfileId == profileId)
    .toList();

void main() {
  late Directory tempDir;
  late HiveProjectRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bq_profile_cycle');
    Hive.init(tempDir.path);
    repo = HiveProjectRepository();
    await repo.init();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(HiveProjectRepository.projectsBoxName);
    await Hive.deleteBoxFromDisk(HiveProjectRepository.framesBoxName);
    await Hive.close();
    await tempDir.delete(recursive: true);
    profile.activeProfileId = '';
  });

  test('ciclo completo SIN perfil activo: guardar → listar → sigue tras recargar',
      () async {
    profile.activeProfileId = ''; // sin perfil (biblioteca general)

    await saveCapturedProject(
      repo,
      id: 'p_noprofile',
      name: 'Mi Animación',
      artistName: 'Pato',
      frames: [CapturedFrame.raw(_png(640, 480)), CapturedFrame.raw(_png(640, 480))],
    );

    final visible = visibleFor(await repo.loadProjects(), '');
    expect(visible.map((p) => p.id), contains('p_noprofile'));
    expect(visible.single.ownerProfileId, '');

    // "Recargar": reabrir el repo (persistencia Hive) y volver a listar.
    await Hive.close();
    Hive.init(tempDir.path);
    final repo2 = HiveProjectRepository();
    await repo2.init();
    final visible2 = visibleFor(await repo2.loadProjects(), '');
    expect(visible2.map((p) => p.id), contains('p_noprofile'));
    expect(await repo2.loadFrames('p_noprofile'), hasLength(2));
  });

  test('ciclo completo CON perfil: el proyecto queda ligado al perfil activo',
      () async {
    profile.activeProfileId = 'p_ana';

    await saveCapturedProject(
      repo,
      id: 'proj_ana',
      name: 'Animación de Ana',
      artistName: 'Ana',
      frames: [CapturedFrame.raw(_png(640, 480))],
    );

    final all = await repo.loadProjects();
    // Ana lo ve.
    expect(visibleFor(all, 'p_ana').map((p) => p.id), contains('proj_ana'));
    // Otro perfil NO lo ve (aislamiento HDU6).
    expect(visibleFor(all, 'p_beto'), isEmpty);
  });

  test('borrador con perfil: se persiste, aparece y "Guardar" lo finaliza',
      () async {
    profile.activeProfileId = 'p_ana';
    final id1 = await repo.addFrame(_png(400, 400));

    // Borrador incremental (lo que hace _persistDraft al capturar).
    await saveDraft(repo, id: 'draft_ana', frameIds: [id1]);
    var visible = visibleFor(await repo.loadProjects(), 'p_ana');
    expect(visible.single.id, 'draft_ana');
    expect(visible.single.isDraft, isTrue, reason: 'aparece como Borrador');

    // "Guardar" (nombre/artista) sobre el mismo id finaliza el borrador.
    await saveCapturedProject(
      repo,
      id: 'draft_ana',
      name: 'Terminada',
      artistName: 'Ana',
      frames: [CapturedFrame.existing(id1)],
      isDraft: false,
    );
    visible = visibleFor(await repo.loadProjects(), 'p_ana');
    expect(visible.single.isDraft, isFalse);
    expect(visible.single.name, 'Terminada');
  });

  test('versiones respetan el perfil y restaurar recupera los cuadros',
      () async {
    profile.activeProfileId = 'p_ana';
    final id1 = await repo.addFrame(_png(300, 300));
    final id2 = await repo.addFrame(_png(300, 300));
    await saveCapturedProject(repo,
        id: 'proj_v', name: 'P', artistName: 'Ana',
        frames: [CapturedFrame.existing(id1), CapturedFrame.existing(id2)]);

    await saveVersion(repo, parentId: 'proj_v', frameIds: [id1, id2], author: 'Ana');
    final versions = await listVersions(repo, 'proj_v');
    expect(versions, hasLength(1));
    expect(versions.single.ownerProfileId, 'p_ana');
    // Las versiones no ensucian "Mis proyectos" (parentId != null).
    expect(visibleFor(await repo.loadProjects(), 'p_ana').map((p) => p.id),
        ['proj_v']);
    // Restaurar: los cuadros de la versión siguen disponibles.
    for (final fid in versions.single.photoPaths) {
      expect(await repo.loadFrameBytes(fid), isNotNull);
    }
  });

  test('borrar un proyecto lo quita y no vuelve al recargar', () async {
    profile.activeProfileId = 'p_ana';
    await saveCapturedProject(repo,
        id: 'to_delete', name: 'X', artistName: 'Ana',
        frames: [CapturedFrame.raw(_png(320, 240))]);
    expect(visibleFor(await repo.loadProjects(), 'p_ana'), hasLength(1));

    await repo.deleteProject('to_delete');
    expect(visibleFor(await repo.loadProjects(), 'p_ana'), isEmpty);

    // "Recargar": reabrir el repo.
    await Hive.close();
    Hive.init(tempDir.path);
    final repo2 = HiveProjectRepository();
    await repo2.init();
    expect(visibleFor(await repo2.loadProjects(), 'p_ana'), isEmpty);
  });
}
