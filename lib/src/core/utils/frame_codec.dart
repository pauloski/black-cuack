import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image/image.dart' as img;

/// Comprime un cuadro a JPEG para la demo local:
/// - aplica la orientación EXIF (bake),
/// - aplana el canal alfa sobre **blanco** (JPEG no tiene alfa),
/// - reduce el lado mayor a [maxSide] **sin ampliar** y conservando la proporción,
/// - codifica JPEG con [quality].
///
/// Si los bytes no se pueden decodificar como imagen, devuelve [input] sin tocar.
/// Relación de aspecto (ancho/alto) a partir de '9:16' o '16:9'.
double aspectValue(String aspect) => aspect == '16:9' ? 16 / 9 : 9 / 16;

Uint8List compressFrameJpeg(
  Uint8List input, {
  int maxSide = 1280,
  int quality = 85,
  double? aspect,
}) {
  // Blindaje: un cuadro NUNCA se pierde por un fallo de compresión. Si cualquier
  // paso del códec lanza (formato raro de cámara web, memoria, etc.), se devuelve
  // la imagen original tal cual. Así "Guardar" nunca falla por la compresión.
  try {
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

    // 2b) Recorte centrado a la relación de aspecto del proyecto (HDU2).
    if (aspect != null) {
      image = _cropToAspect(image, aspect);
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

    // 4) Sin metadatos: se descartan EXIF/GPS (ubicación) al recodificar.
    image.exif = img.ExifData();

    return img.encodeJpg(image, quality: quality);
  } catch (e) {
    debugPrint('⚠️ compresión falló; se guarda el cuadro original: $e');
    return input;
  }
}

/// Recorte centrado a la relación [aspect] (ancho/alto).
img.Image _cropToAspect(img.Image im, double aspect) {
  final current = im.width / im.height;
  if ((current - aspect).abs() < 0.001) return im;
  int w, h;
  if (current > aspect) {
    h = im.height;
    w = (h * aspect).round();
  } else {
    w = im.width;
    h = (w / aspect).round();
  }
  final x = ((im.width - w) / 2).round();
  final y = ((im.height - h) / 2).round();
  return img.copyCrop(im, x: x, y: y, width: w, height: h);
}
