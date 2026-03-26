import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:universal_html/html.dart' as html;

class VideoCreator {
  // Ahora export acepta el parámetro onProgress como obligatorio
  static Future<void> export(
    List<String> imagePaths, 
    double fps, 
    {required Function(double) onProgress} // <-- CORREGIDO: con llaves y required
  ) async {
    if (kIsWeb) {
      await _exportWeb(imagePaths, fps, onProgress);
    } else {
      await _exportMobile(imagePaths, fps);
    }
  }

  // --- LÓGICA PARA CHROME CON PROGRESO ---
  static Future<void> _exportWeb(
    List<String> imagePaths, 
    double fps, 
    Function(double) onProgress
  ) async {
    final encoder = img.GifEncoder(delay: (100 / fps).round(), repeat: 0);

    for (int i = 0; i < imagePaths.length; i++) {
      // Enviamos el progreso real a la interfaz
      onProgress((i + 1) / imagePaths.length);

      final response = await html.HttpRequest.request(imagePaths[i], responseType: "arraybuffer");
      final bytes = Uint8List.view(response.response);
      final decodedFrame = img.decodeImage(bytes);
      
      if (decodedFrame != null) {
        encoder.addFrame(decodedFrame);
      }
    }

    final gifBytes = encoder.finish();

    if (gifBytes != null) {
      final blob = html.Blob([gifBytes], 'image/gif');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "quack_studio_export.gif")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  // --- LÓGICA PARA CELULAR (ANDROID/IOS) ---
  static Future<void> _exportMobile(List<String> imagePaths, double fps) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath = '${tempDir.path}/quack_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final File listFile = File('${tempDir.path}/images.txt');
      
      String fileContent = "";
      for (String path in imagePaths) {
        fileContent += "file '$path'\nduration ${1 / fps}\n";
      }
      if (imagePaths.isNotEmpty) fileContent += "file '${imagePaths.last}'\n";
      
      await listFile.writeAsString(fileContent);

      final String command = "-y -f concat -safe 0 -i ${listFile.path} -vsync vfr -pix_fmt yuv420p $outputPath";
      await FFmpegKit.execute(command);
    } catch (e) {
      print("Error en exportación móvil: $e");
    }
  }
}