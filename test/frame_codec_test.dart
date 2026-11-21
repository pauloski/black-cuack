import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:blackcuack_studio/src/core/utils/frame_codec.dart';

bool _isJpeg(Uint8List b) => b.length > 3 && b[0] == 0xFF && b[1] == 0xD8;

void main() {
  test('reduce el lado mayor a 1280 conservando la proporción', () {
    final src = img.Image(width: 2000, height: 1000);
    img.fill(src, color: img.ColorRgb8(10, 120, 200));
    final input = Uint8List.fromList(img.encodePng(src));

    final out = compressFrameJpeg(input, maxSide: 1280);
    expect(_isJpeg(out), isTrue, reason: 'la salida debe ser JPEG');

    final dec = img.decodeJpg(out)!;
    expect(dec.width, 1280);
    expect(dec.height, 640); // 2000:1000 == 1280:640
  });

  test('no amplía una imagen menor que 1280', () {
    final src = img.Image(width: 800, height: 600);
    img.fill(src, color: img.ColorRgb8(0, 0, 0));
    final input = Uint8List.fromList(img.encodePng(src));

    final out = compressFrameJpeg(input, maxSide: 1280);
    final dec = img.decodeJpg(out)!;
    expect(dec.width, 800);
    expect(dec.height, 600);
  });

  test('aplana el alfa sobre blanco', () {
    // Imagen totalmente transparente.
    final src = img.Image(width: 20, height: 20, numChannels: 4);
    img.fill(src, color: img.ColorRgba8(0, 0, 0, 0));
    final input = Uint8List.fromList(img.encodePng(src));

    final out = compressFrameJpeg(input, maxSide: 1280);
    final dec = img.decodeJpg(out)!;
    final p = dec.getPixel(0, 0);
    // Sin alfa (JPEG) y el fondo transparente quedó blanco.
    expect(p.r, greaterThanOrEqualTo(250));
    expect(p.g, greaterThanOrEqualTo(250));
    expect(p.b, greaterThanOrEqualTo(250));
  });

  test('aplica la orientación EXIF (bake)', () {
    // 40 ancho x 80 alto, con orientación 6 (rotar 90°): al hornear queda 80x40.
    final src = img.Image(width: 40, height: 80);
    img.fill(src, color: img.ColorRgb8(200, 50, 50));
    src.exif.imageIfd.orientation = 6;
    final input = Uint8List.fromList(img.encodeJpg(src));

    final out = compressFrameJpeg(input, maxSide: 1280);
    final dec = img.decodeJpg(out)!;
    expect(dec.width, 80);
    expect(dec.height, 40);
  });

  test('recorta a 9:16 (vertical) y a 16:9 (horizontal)', () {
    // Entrada apaisada 2000x1000 → recorte a 9:16 (≈0.5625).
    final wide = img.Image(width: 2000, height: 1000);
    img.fill(wide, color: img.ColorRgb8(1, 2, 3));
    final v = img.decodeJpg(compressFrameJpeg(
      Uint8List.fromList(img.encodePng(wide)),
      aspect: aspectValue('9:16'),
    ))!;
    expect((v.width / v.height - 9 / 16).abs() < 0.02, isTrue);

    // Entrada vertical 1000x2000 → recorte a 16:9 (≈1.777).
    final tall = img.Image(width: 1000, height: 2000);
    img.fill(tall, color: img.ColorRgb8(1, 2, 3));
    final h = img.decodeJpg(compressFrameJpeg(
      Uint8List.fromList(img.encodePng(tall)),
      aspect: aspectValue('16:9'),
    ))!;
    expect((h.width / h.height - 16 / 9).abs() < 0.02, isTrue);
  });

  test('la salida no lleva metadatos EXIF (ni ubicación)', () {
    final src = img.Image(width: 100, height: 100);
    img.fill(src, color: img.ColorRgb8(5, 5, 5));
    src.exif.imageIfd.orientation = 3; // metadato de origen
    final out = compressFrameJpeg(Uint8List.fromList(img.encodeJpg(src)));
    final dec = img.decodeJpg(out)!;
    expect(dec.exif.isEmpty, isTrue, reason: 'EXIF/GPS descartados');
  });

  test('bytes no decodificables: devuelve la entrada sin lanzar (no pierde cuadro)',
      () {
    final garbage = Uint8List.fromList(
        List<int>.generate(64, (i) => (i * 7 + 3) % 256));
    late Uint8List out;
    expect(() => out = compressFrameJpeg(garbage, aspect: aspectValue('9:16')),
        returnsNormally);
    expect(out, garbage, reason: 'se guarda el cuadro original como respaldo');
  });

  test('salida JPEG para una entrada JPEG normal', () {
    final src = img.Image(width: 100, height: 100);
    img.fill(src, color: img.ColorRgb8(123, 222, 64));
    final input = Uint8List.fromList(img.encodeJpg(src));

    final out = compressFrameJpeg(input, maxSide: 1280);
    expect(_isJpeg(out), isTrue);
    final dec = img.decodeJpg(out)!;
    expect(dec.width, 100);
    expect(dec.height, 100);
  });
}
