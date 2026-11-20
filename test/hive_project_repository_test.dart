import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:blackcuack_studio/src/features/gallery/data/hive_project_repository.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';

void main() {
  late Directory tempDir;
  late HiveProjectRepository repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bq_hive_test');
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

  QuackProject project(String id, List<String> frameIds) => QuackProject(
        id: id,
        name: 'Proyecto $id',
        photoPaths: frameIds,
        date: DateTime.now(),
      );

  test('guarda y recupera N cuadros como bytes idénticos y en orden', () async {
    final frames =
        List.generate(5, (i) => Uint8List.fromList([i, i + 10, i + 20]));
    final ids = <String>[];
    for (final f in frames) {
      ids.add(await repo.addFrame(f));
    }

    await repo.saveProject(project('p1', ids));

    final loaded = await repo.loadFrames('p1');
    expect(loaded.length, 5);
    for (var i = 0; i < 5; i++) {
      expect(loaded[i], equals(frames[i]));
    }
    // Los ids son únicos y estables.
    expect(ids.toSet().length, 5);
  });

  test('duplicar un cuadro comparte bytes sin copiarlos', () async {
    final id = await repo.addFrame(Uint8List.fromList([9, 9, 9]));
    await repo.saveProject(project('p2', [id, id]));

    final loaded = await repo.loadFrames('p2');
    expect(loaded.length, 2);
    expect(loaded[0], equals(loaded[1]));
  });

  test('versiones comparten cuadros; borrar una conserva los compartidos',
      () async {
    final id = await repo.addFrame(Uint8List.fromList([1, 2, 3]));
    await repo.saveProject(project('v1', [id]));
    await repo.saveProject(project('v2', [id]));

    await repo.deleteProject('v1');
    expect(await repo.loadFrameBytes(id), isNotNull,
        reason: 'v2 aún referencia el cuadro');

    await repo.deleteProject('v2');
    expect(await repo.loadFrameBytes(id), isNull,
        reason: 'ya nadie lo referencia');
  });

  test('pruneOrphanFrames elimina cuadros sin proyecto', () async {
    final id = await repo.addFrame(Uint8List.fromList([7]));
    expect(await repo.loadFrameBytes(id), isNotNull);

    final removed = await repo.pruneOrphanFrames();
    expect(removed, 1);
    expect(await repo.loadFrameBytes(id), isNull);
  });

  test('loadProjects devuelve los proyectos del más reciente al más antiguo',
      () async {
    await repo.saveProject(QuackProject(
        id: 'a', name: 'A', photoPaths: const [], date: DateTime(2026, 1, 1)));
    await repo.saveProject(QuackProject(
        id: 'b', name: 'B', photoPaths: const [], date: DateTime(2026, 6, 1)));

    final list = await repo.loadProjects();
    expect(list.map((p) => p.id).toList(), ['b', 'a']);
  });
}
