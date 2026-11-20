import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:blackcuack_studio/src/features/gallery/data/in_memory_project_repository.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';

void main() {
  late InMemoryProjectRepository repo;

  setUp(() => repo = InMemoryProjectRepository());

  test('respaldo en memoria: guarda, recupera y comparte/borra cuadros',
      () async {
    final id = await repo.addFrame(Uint8List.fromList([1, 2, 3]));
    await repo.saveProject(QuackProject(
        id: 'a', name: 'A', photoPaths: [id], date: DateTime.now()));
    await repo.saveProject(QuackProject(
        id: 'b', name: 'B', photoPaths: [id], date: DateTime.now()));

    expect((await repo.loadProjects()).length, 2);
    expect(await repo.loadFrameBytes(id), Uint8List.fromList([1, 2, 3]));

    await repo.deleteProject('a');
    expect(await repo.loadFrameBytes(id), isNotNull, reason: 'b aún lo usa');
    await repo.deleteProject('b');
    expect(await repo.loadFrameBytes(id), isNull);
  });
}
