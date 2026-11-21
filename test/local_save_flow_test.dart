import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:image/image.dart' as img;

import 'package:blackcuack_studio/src/features/gallery/data/hive_project_repository.dart';
import 'package:blackcuack_studio/src/core/services/local_project_service.dart';

Uint8List _png(int w, int h) {
  final im = img.Image(width: w, height: h);
  img.fill(im, color: img.ColorRgb8(20, 160, 120));
  return Uint8List.fromList(img.encodePng(im));
}

void main() {
  late Directory tempDir;
  late HiveProjectRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bq_save_test');
    Hive.init(tempDir.path);
    repo = HiveProjectRepository();
    await repo.init();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(HiveProjectRepository.projectsBoxName);
    await Hive.deleteBoxFromDisk(HiveProjectRepository.framesBoxName);
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('guarda N cuadros nuevos (comprimidos) y los recupera', () async {
    final frames = [
      CapturedFrame.raw(_png(2000, 1000)),
      CapturedFrame.raw(_png(800, 600)),
      CapturedFrame.raw(_png(400, 400)),
    ];
    final p = await saveCapturedProject(
      repo,
      id: 'p1',
      name: 'Demo',
      artistName: 'Pato',
      frames: frames,
    );
    expect(p.photoPaths.length, 3);

    final loaded = await repo.loadFrames('p1');
    expect(loaded.length, 3);
    // Comprimidos a JPEG y con lado mayor <= 1280.
    for (final b in loaded) {
      expect(b[0], 0xFF);
      expect(b[1], 0xD8);
      final dec = img.decodeJpg(b)!;
      expect(dec.width <= 1280 && dec.height <= 1280, isTrue);
    }
  });

  test('reabrir, añadir uno y guardar → N+1 con ids intactos y sin recomprimir',
      () async {
    // Guardado inicial: 2 cuadros nuevos.
    final first = await saveCapturedProject(
      repo,
      id: 'p2',
      name: 'Demo',
      artistName: 'Pato',
      frames: [CapturedFrame.raw(_png(600, 400)), CapturedFrame.raw(_png(600, 400))],
    );
    final originalIds = List<String>.from(first.photoPaths);
    expect(originalIds.length, 2);
    final bytesBefore = [
      await repo.loadFrameBytes(originalIds[0]),
      await repo.loadFrameBytes(originalIds[1]),
    ];

    // Reabrir: los cuadros existentes conservan su id; se añade uno nuevo.
    final second = await saveCapturedProject(
      repo,
      id: 'p2',
      name: 'Demo',
      artistName: 'Pato',
      frames: [
        CapturedFrame.existing(originalIds[0]),
        CapturedFrame.existing(originalIds[1]),
        CapturedFrame.raw(_png(600, 400)),
      ],
    );

    expect(second.photoPaths.length, 3);
    // Los dos primeros ids no cambian.
    expect(second.photoPaths.sublist(0, 2), originalIds);
    // Y sus bytes son idénticos (no se recomprimieron).
    expect(await repo.loadFrameBytes(originalIds[0]), bytesBefore[0]);
    expect(await repo.loadFrameBytes(originalIds[1]), bytesBefore[1]);
    // El tercero es un id nuevo y distinto.
    expect(originalIds.contains(second.photoPaths[2]), isFalse);
  });

  test('borrador: sus cuadros NO son huérfanos y "guardar" lo finaliza',
      () async {
    final id1 = await repo.addFrame(_png(400, 400));
    await saveDraft(repo, id: 'd1', frameIds: [id1]);

    final draft = await repo.getProject('d1');
    expect(draft, isNotNull);
    expect(draft!.isDraft, isTrue);

    // Los cuadros del borrador están referenciados → no se podan.
    final removed = await repo.pruneOrphanFrames();
    expect(removed, 0);
    expect(await repo.loadFrameBytes(id1), isNotNull);

    // "Guardar" (poner nombre/artista) finaliza el borrador.
    final fin = await saveCapturedProject(
      repo,
      id: 'd1',
      name: 'Mi obra',
      artistName: 'Pato',
      frames: [CapturedFrame.existing(id1)],
      isDraft: false,
    );
    expect(fin.isDraft, isFalse);
    expect((await repo.getProject('d1'))!.isDraft, isFalse);
  });

  test('versiones: comparten cuadros, se listan por proyecto y registran nº',
      () async {
    final id1 = await repo.addFrame(_png(300, 300));
    final id2 = await repo.addFrame(_png(300, 300));
    await saveCapturedProject(repo,
        id: 'proj', name: 'P', artistName: 'Pato',
        frames: [CapturedFrame.existing(id1), CapturedFrame.existing(id2)]);

    await saveVersion(repo,
        parentId: 'proj', frameIds: [id1, id2], author: 'Pato');
    await saveVersion(repo, parentId: 'proj', frameIds: [id1], author: 'Pato');

    final versions = await listVersions(repo, 'proj');
    expect(versions.length, 2);
    expect(versions.first.photoPaths.length, 1); // la más reciente
    expect(versions.last.photoPaths.length, 2);

    // Comparten cuadros: nada se poda (todo referenciado).
    expect(await repo.pruneOrphanFrames(), 0);
    expect(await repo.loadFrameBytes(id1), isNotNull);
  });
}
