import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import 'package:blackcuack_studio/src/core/utils/frame_codec.dart'
    show cropImageToAspect;
import 'ffmpeg_web_stub.dart'
    if (dart.library.js_interop) 'ffmpeg_web.dart';

enum ExportFormat { gif, mp4, imageSequence }

class VideoCreator {
  // ── ENTRY POINT ──────────────────────────────────────────────────────────
  // [filename] sin extensión, ej: "mi_quack"
  // Returns: ruta de archivo en móvil, null en web (la descarga se dispara directo)
  // Para imageSequence en móvil retorna la ruta del ZIP
  static Future<String?> exportAs(
    ExportFormat format,
    List<String> imagePaths,
    double fps, {
    required String filename,
    required Function(double) onProgress,
    // Relación del proyecto (ancho/alto). Los cuadros se guardan sin recortar;
    // al exportar se recortan a este aspecto. null = sin recorte.
    double? aspect,
  }) async {
    switch (format) {
      case ExportFormat.gif:
        return _exportGif(imagePaths, fps, filename, onProgress, aspect);
      case ExportFormat.mp4:
        return _exportMp4(imagePaths, fps, filename, onProgress);
      case ExportFormat.imageSequence:
        return _exportImageSequenceZip(
            imagePaths, filename, onProgress, aspect);
    }
  }

  // ── GIF (web + mobile) ───────────────────────────────────────────────────
  static Future<String?> _exportGif(
    List<String> imagePaths,
    double fps,
    String filename,
    Function(double) onProgress,
    double? aspect,
  ) async {
    final frameDelay = (100 / fps).round();
    final encoder = img.GifEncoder(delay: frameDelay, repeat: 0);

    int added = 0;
    for (int i = 0; i < imagePaths.length; i++) {
      onProgress((i + 1) / imagePaths.length * 0.9);
      try {
        final bytes = await _fetchBytes(imagePaths[i]);
        img.Image? frame = img.decodeImage(bytes);
        if (frame != null) {
          if (aspect != null) frame = cropImageToAspect(frame, aspect);
          if (frame.width > 720) frame = img.copyResize(frame, width: 720);
          _applyWatermark(frame);
          encoder.addFrame(frame);
          added++;
        }
      } catch (e) {
        debugPrint('Error procesando frame $i: $e');
      }
    }

    onProgress(1.0);
    // Nunca producir un archivo vacío: si ningún cuadro se pudo leer, abortar.
    if (added == 0) return null;

    final gifBytes = encoder.finish();
    if (gifBytes == null) return null;

    final name = '$filename.gif';
    if (kIsWeb) {
      _downloadWeb(gifBytes, 'image/gif', name);
      return name;
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(gifBytes);
      return file.path;
    }
  }

  // ── MP4 (web via FFmpeg.wasm · mobile via FFmpegKit) ────────────────────
  static Future<String?> _exportMp4(
    List<String> imagePaths,
    double fps,
    String filename,
    Function(double) onProgress,
  ) async {
    if (kIsWeb) return _exportMp4Web(imagePaths, fps, filename, onProgress);
    return _exportMp4Mobile(imagePaths, fps, filename, onProgress);
  }

  static Future<String?> _exportMp4Web(
    List<String> imagePaths,
    double fps,
    String filename,
    Function(double) onProgress,
  ) async {
    try {
      onProgress(0.05);
      final frames = <Uint8List>[];
      for (int i = 0; i < imagePaths.length; i++) {
        frames.add(await _fetchBytes(imagePaths[i]));
        onProgress(0.05 + (i + 1) / imagePaths.length * 0.2);
      }

      final mp4Bytes = await WebFFmpeg.framesToMp4(
        frames,
        fps,
        onProgress: (p) => onProgress(0.25 + p * 0.75),
      );

      if (mp4Bytes == null) return null;
      final name = '$filename.mp4';
      _downloadWeb(mp4Bytes, 'video/mp4', name);
      return name;
    } catch (e) {
      debugPrint('Error exportación MP4 web: $e');
      return null;
    }
  }

  static Future<String?> _exportMp4Mobile(
    List<String> imagePaths,
    double fps,
    String filename,
    Function(double) onProgress,
  ) async {
    try {
      onProgress(0.1);
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/$filename.mp4';
      final listFile = File('${tempDir.path}/images_list.txt');

      String content = '';
      for (final path in imagePaths) {
        content += "file '$path'\nduration ${1 / fps}\n";
      }
      if (imagePaths.isNotEmpty) content += "file '${imagePaths.last}'\n";
      await listFile.writeAsString(content);
      onProgress(0.3);

      final cmd =
          '-y -f concat -safe 0 -i ${listFile.path} -c:v libx264 -crf 28 -preset superfast -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" $outputPath';
      final session = await FFmpegKit.execute(cmd);
      final rc = await session.getReturnCode();

      onProgress(1.0);
      return ReturnCode.isSuccess(rc) ? outputPath : null;
    } catch (e) {
      debugPrint('Error exportación MP4: $e');
      return null;
    }
  }

  // ── IMAGE SEQUENCE → ZIP (web + mobile) ──────────────────────────────────
  static Future<String?> _exportImageSequenceZip(
    List<String> imagePaths,
    String filename,
    Function(double) onProgress,
    double? aspect,
  ) async {
    final archive = Archive();

    for (int i = 0; i < imagePaths.length; i++) {
      onProgress((i + 1) / imagePaths.length * 0.85);
      try {
        final raw = await _fetchBytes(imagePaths[i]);
        var decoded = img.decodeImage(raw);
        if (decoded != null && aspect != null) {
          decoded = cropImageToAspect(decoded, aspect);
        }
        final bytes = decoded != null
            ? Uint8List.fromList(
                img.encodeJpg(_applyWatermark(decoded), quality: 90))
            : raw;
        final frameName = 'frame_${(i + 1).toString().padLeft(3, '0')}.jpg';
        archive.addFile(ArchiveFile(frameName, bytes.length, bytes));
      } catch (e) {
        debugPrint('Error añadiendo frame $i al ZIP: $e');
      }
    }

    onProgress(1.0);
    // Nunca producir un ZIP vacío (un archivo vacío igual pesa ~22 bytes):
    // si no se añadió ningún cuadro, abortar.
    if (archive.isEmpty) return null;

    final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive) ?? []);
    if (zipBytes.isEmpty) return null;

    final zipName = '$filename.zip';
    if (kIsWeb) {
      _downloadWeb(zipBytes, 'application/zip', zipName);
      return zipName;
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$zipName');
      await file.writeAsBytes(zipBytes);
      return file.path;
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────
  static Future<Uint8List> _fetchBytes(String path) async {
    // En web, las rutas de cuadro son `blob:` (captura) o `http(s)` (Storage);
    // `dart:io File` no existe en web. XHR (package:http) lee ambas.
    // En nativo se leen como archivo. Arreglo mínimo: habilita el GIF en web
    // (la reescritura por bytes desde el repositorio local llega en T3-T5).
    if (kIsWeb || path.startsWith('http') || path.startsWith('blob:')) {
      return (await http.get(Uri.parse(path))).bodyBytes;
    }
    return await File(path).readAsBytes();
  }

  /// Marca de agua "BlackQuack" (plan gratis) abajo a la izquierda.
  static img.Image _applyWatermark(img.Image im) {
    img.drawString(
      im,
      'BlackQuack',
      font: img.arial24,
      x: 8,
      y: im.height - 30,
      color: img.ColorRgba8(255, 255, 255, 200),
    );
    return im;
  }

  static void _downloadWeb(Uint8List bytes, String mime, String filename) {
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
