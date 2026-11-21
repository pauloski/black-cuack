// Corre también en el navegador:  flutter test --platform chrome test/id_gen_test.dart
//
// Este test habría atrapado el RangeError de producción: en Dart→JS los
// corrimientos de 32 bits dan 0, y `nextInt(1 << 32)` lanzaba. newFrameId() ya no
// usa corrimientos, así que no debe lanzar en ninguna plataforma.
import 'package:flutter_test/flutter_test.dart';

import 'package:blackcuack_studio/src/core/utils/id_gen.dart';

void main() {
  test('newFrameId no lanza y tiene el formato f_<ts>_<rand> (web y VM)', () {
    final id = newFrameId();
    expect(id, startsWith('f_'));
    final parts = id.split('_');
    expect(parts.length, 3);
    // El segmento de timestamp es hexadecimal parseable (lo usa la poda).
    expect(int.tryParse(parts[1], radix: 16), isNotNull);
    // 64 bits aleatorios = 16 dígitos hex.
    expect(parts[2].length, 16);
    expect(int.tryParse(parts[2], radix: 16), isNotNull);
  });

  test('genera miles de ids únicos sin lanzar', () {
    final ids = <String>{};
    for (var i = 0; i < 5000; i++) {
      final id = newFrameId();
      expect(ids.add(id), isTrue, reason: 'id repetido: $id');
    }
    expect(ids.length, 5000);
  });
}
