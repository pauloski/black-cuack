import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Comprime un cuadro a JPEG para la demo local:
/// - aplica la orientación EXIF (bake),
/// - aplana el canal alfa sobre **blanco** (JPEG no tiene alfa),
/// - reduce el lado mayor a [maxSide] **sin ampliar** y conservando la proporción,
/// - codifica JPEG con [quality].
///
/// Si los bytes no se pueden decodificar como imagen, devuelve [input] sin tocar.
Uint8List compressFrameJpeg(
  Uint8List input, {
  int maxSide = 1280,
  int quality = 85,
}) {
  var image = img.decodeImage(input);
  if (image == null) return input;

  // 1) Orientación EXIF aplicada a los píxeles.
  image = img.bakeOrientation(image);

  // 2) Aplanar alfa sobre blanco.
  if (image.hasAlpha) {
    final bg = img.Image(width: image.width, height: image.height);
    img.fill(bg, color: img.ColorRgb8(255, 255, 255));
    image = img.compositeImage(bg, image);
  }

  // 3) Reducir el lado mayor a maxSide (nunca ampliar).
  final longest = image.width >= image.height ? image.width : image.height;
  if (longest > maxSide) {
    if (image.width >= image.height) {
      image = img.copyResize(image, width: maxSide);
    } else {
      image = img.copyResize(image, height: maxSide);
    }
  }

  return img.encodeJpg(image, quality: quality);
}
