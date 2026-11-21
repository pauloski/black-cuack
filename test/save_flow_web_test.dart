// Ciclo de guardado que corre EN EL NAVEGADOR:
//   flutter test --platform chrome test/save_flow_web_test.dart
//
// Usa InMemoryProjectRepository (sin Hive ni dart:io) para que compile en web, y
// ejerce addFrame → newFrameId en JS. Con el bug de `1 << 32` esto lanzaba
// RangeError en Chrome (pero pasaba en la VM). Cubre guardar, borrador y versión,
// con y sin perfil activo.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:blackcuack_studio/src/features/gallery/data/in_memory_project_repository.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/core/services/local_project_service.dart';
import 'package:blackcuack_studio/src/features/profile/data/profile_service.dart'
    as profile;

Uint8List _png(int w, int h) {
  final im = img.Image(width: w, height: h);
  img.fill(im, color: img.ColorRgb8(40, 120, 200));
  return Uint8List.fromList(img.encodePng(im));
}

List<QuackProject> _visible(List<QuackProject> all, String profileId) => all
    .where((p) =>
        p.photoPaths.isNotEmpty &&
        p.parentId == null &&
        p.ownerProfileId == profileId)
    .toList();

void main() {
  late InMemoryProjectRepository repo;

  setUp(() {
    repo = InMemoryProjectRepository();
    profile.activeProfileId = '';
  });

  test('capturar → Guardar → Mis proyectos (sin perfil), en web', () async {
    final p = await saveCapturedProject(
      repo,
      id: 'p1',
      name: 'Mi Animación',
      artistName: 'Pato',
      frames: [CapturedFrame.raw(_png(640, 480)), CapturedFrame.raw(_png(640, 480))],
    );
    expect(p.photoPaths, hasLength(2));
    // Cada cuadro recibió un id válido (en web esto fallaba antes del fix).
    for (final id in p.photoPaths) {
      expect(id, startsWith('f_'));
      expect(await repo.loadFrameBytes(id), isNotNull);
    }
    expect(_visible(await repo.loadProjects(), '').map((e) => e.id), ['p1']);
    expect(await repo.loadFrames('p1'), hasLength(2));
  });

  test('borrador y versión funcionan con perfil (web)', () async {
    profile.activeProfileId = 'p_ana';
    final id1 = await repo.addFrame(_png(400, 400));

    await saveDraft(repo, id: 'd1', frameIds: [id1]);
    final draft = _visible(await repo.loadProjects(), 'p_ana').single;
    expect(draft.isDraft, isTrue);

    await saveCapturedProject(repo,
        id: 'd1', name: 'Final', artistName: 'Ana',
        frames: [CapturedFrame.existing(id1)], isDraft: false);
    expect(_visible(await repo.loadProjects(), 'p_ana').single.isDraft, isFalse);

    await saveVersion(repo, parentId: 'd1', frameIds: [id1], author: 'Ana');
    expect(await listVersions(repo, 'd1'), hasLength(1));
  });
}
