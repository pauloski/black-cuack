import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;

class BackgroundEraser {
  /// Borra el soporte en un frame con:
  /// - Feathering gaussiano en el borde de la máscara
  /// - Corrección de color (sesgo) para reducir la costura
  static Future<String> eraseSingleFrame({
    required String framePath,
    required String referencePath,
    required List<Offset> maskPoints,
    required double brushRadiusPx,
  }) async {
    final refBytes = await _fetchBytes(referencePath);
    final refImage = img.decodeImage(refBytes);
    if (refImage == null) throw Exception('No se pudo decodificar el frame de referencia');

    final frameBytes = await _fetchBytes(framePath);
    final frame = img.decodeImage(frameBytes);
    if (frame == null) throw Exception('No se pudo decodificar el frame');

    final w = refImage.width;
    final h = refImage.height;

    // Feather radius proporcional al pincel, acotado para rendimiento
    final featherRadius = (brushRadiusPx * 0.12).round().clamp(8, 24);

    final mask = _buildMask(w, h, maskPoints, brushRadiusPx);
    final alpha = _buildFeatheredAlpha(mask, w, h, featherRadius);
    final bias = _computeBorderBias(frame, refImage, alpha);
    _blendWithAlpha(frame, refImage, alpha, bias);

    final out = img.encodeJpg(frame, quality: 90);
    return _save(out, framePath);
  }

  // ── Feathering ───────────────────────────────────────────────────────────────

  /// Construye un alpha suavizado aplicando gaussian blur al mask binario.
  static Float32List _buildFeatheredAlpha(
      List<bool> mask, int w, int h, int featherRadius) {
    // Crea imagen RGB donde blanco = área pintada, negro = fondo
    final maskImg = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final v = mask[y * w + x] ? 255 : 0;
        maskImg.setPixel(x, y, img.ColorRgb8(v, v, v));
      }
    }

    final blurred = img.gaussianBlur(maskImg, radius: featherRadius);

    final alpha = Float32List(w * h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        alpha[y * w + x] =
            ((blurred.getPixel(x, y).r as double) / 255.0).clamp(0.0, 1.0);
      }
    }
    return alpha;
  }

  // ── Corrección de color ──────────────────────────────────────────────────────

  /// Estima el sesgo de color entre frame y referencia en la zona borde
  /// (alpha 0.05–0.40) para corregir diferencias de iluminación.
  static (double, double, double) _computeBorderBias(
    img.Image frame,
    img.Image ref,
    Float32List alpha,
  ) {
    final w = frame.width;
    final h = frame.height;
    double sumR = 0, sumG = 0, sumB = 0;
    int count = 0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final a = alpha[y * w + x];
        if (a < 0.05 || a > 0.40) continue;
        final fp = frame.getPixel(x, y);
        final rp = ref.getPixel(x, y);
        sumR += (fp.r as double) - (rp.r as double);
        sumG += (fp.g as double) - (rp.g as double);
        sumB += (fp.b as double) - (rp.b as double);
        count++;
      }
    }

    if (count == 0) return (0.0, 0.0, 0.0);
    return (sumR / count, sumG / count, sumB / count);
  }

  // ── Blend ────────────────────────────────────────────────────────────────────

  static void _blendWithAlpha(
    img.Image frame,
    img.Image ref,
    Float32List alpha,
    (double, double, double) bias,
  ) {
    final w = frame.width;
    final h = frame.height;
    final (br, bg, bb) = bias;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final a = alpha[y * w + x];
        if (a < 0.002) continue;

        final fp = frame.getPixel(x, y);
        final rp = ref.getPixel(x, y);

        // result = a * (ref + colorBias) + (1-a) * frame
        final r = (a * ((rp.r as double) + br) + (1 - a) * (fp.r as double))
            .clamp(0, 255)
            .round();
        final g = (a * ((rp.g as double) + bg) + (1 - a) * (fp.g as double))
            .clamp(0, 255)
            .round();
        final b = (a * ((rp.b as double) + bb) + (1 - a) * (fp.b as double))
            .clamp(0, 255)
            .round();

        frame.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }
  }

  // ── Mask builder ─────────────────────────────────────────────────────────────

  static List<bool> _buildMask(
    int w,
    int h,
    List<Offset> points,
    double radius,
  ) {
    final mask = List<bool>.filled(w * h, false);
    final ri = radius.ceil();
    final r2 = radius * radius;
    for (final p in points) {
      final cx = p.dx.round();
      final cy = p.dy.round();
      for (int dy = -ri; dy <= ri; dy++) {
        for (int dx = -ri; dx <= ri; dx++) {
          if (dx * dx + dy * dy > r2) continue;
          final px = cx + dx;
          final py = cy + dy;
          if (px < 0 || py < 0 || px >= w || py >= h) continue;
          mask[py * w + px] = true;
        }
      }
    }
    return mask;
  }

  // ── I/O ──────────────────────────────────────────────────────────────────────

  static Future<Uint8List> _fetchBytes(String path) async {
    if (path.startsWith('http') || path.startsWith('blob:')) {
      return (await http.get(Uri.parse(path))).bodyBytes;
    }
    return File(path).readAsBytes();
  }

  static Future<String> _save(Uint8List bytes, String originalPath) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'image/jpeg');
      return html.Url.createObjectUrlFromBlob(blob);
    }
    try {
      await File(originalPath).writeAsBytes(bytes);
      return originalPath;
    } catch (e) {
      debugPrint('BackgroundEraser._save: $e');
      rethrow;
    }
  }
}
