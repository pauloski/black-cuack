import 'dart:math';

/// Generador de ids único y estable, **seguro en web**.
///
/// Importante: en Dart compilado a JS los corrimientos de bits son de 32 bits,
/// así que `1 << 32` vale 0 y `Random().nextInt(1 << 32)` lanza RangeError en el
/// navegador (aunque funcione en la VM de las pruebas). Por eso aquí NO se usan
/// corrimientos: la aleatoriedad se arma con sorteos de 16 bits (`0x10000`), que
/// son literales planos válidos en todas las plataformas.
final Random _rng = Random.secure();

String _rand16() => _rng.nextInt(0x10000).toRadixString(16).padLeft(4, '0');

/// 64 bits de aleatoriedad en hexadecimal (16 dígitos).
String _rand64Hex() => '${_rand16()}${_rand16()}${_rand16()}${_rand16()}';

/// Id de cuadro: `f_<microsegundos-hex>_<64 bits aleatorios>`.
/// El segundo segmento (timestamp) lo usa la poda de huérfanos para fechar el id.
String newFrameId() {
  final ts = DateTime.now().microsecondsSinceEpoch;
  return 'f_${ts.toRadixString(16)}_${_rand64Hex()}';
}
