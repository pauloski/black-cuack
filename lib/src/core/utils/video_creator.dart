import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img; 
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;

class VideoCreator {
  static Future<String?> export(
    List<String> imagePaths, 
    double fps, 
    {required Function(double) onProgress}
  ) async {
    if (kIsWeb) {
      return await _exportWeb(imagePaths, fps, onProgress);
    } else {
      return await _exportMobile(imagePaths, fps, onProgress);
    }
  }

  // --- WEB OPTIMIZADO (MÁS RÁPIDO) ---
  static Future<String?> _exportWeb(List<String> imagePaths, double fps, Function(double) onProgress) async {
    // Reducimos el delay para que el GIF sea fluido según los FPS
    final int frameDelay = (100 / fps).round();
    final encoder = img.GifEncoder(delay: frameDelay, repeat: 0);

    for (int i = 0; i < imagePaths.length; i++) {
      // Actualizamos progreso
      onProgress((i + 1) / imagePaths.length);
      
      try {
        final response = await http.get(Uri.parse(imagePaths[i]));
        final Uint8List bytes = response.bodyBytes;
        
        // Decodificamos la imagen
        img.Image? frame = img.decodeImage(bytes);
        
        if (frame != null) {
          // --- OPTIMIZACIÓN DE VELOCIDAD ---
          // Si la imagen es muy grande, la redimensionamos a 720p máximo.
          // Esto hace que el GIF se genere 3 veces más rápido y pese mucho menos.
          if (frame.width > 720) {
            frame = img.copyResize(frame, width: 720);
          }
          
          encoder.addFrame(frame);
        }
      } catch (e) {
        print("Error procesando frame $i: $e");
      }
    }

    final gifBytes = encoder.finish();
    
    if (gifBytes != null) {
      final blob = html.Blob([gifBytes], 'image/gif');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "quack_${DateTime.now().millisecondsSinceEpoch}.gif")
        ..click();
      
      html.Url.revokeObjectUrl(url);
    }
    
    return null; 
  }

  // --- MÓVIL OPTIMIZADO (MP4 LIGERO) ---
  static Future<String?> _exportMobile(List<String> imagePaths, double fps, Function(double) onProgress) async {
    try {
      onProgress(0.1);
      final Directory tempDir = await getTemporaryDirectory();
      final String outputPath = '${tempDir.path}/quack_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final File listFile = File('${tempDir.path}/images.txt');
      
      String fileContent = "";
      for (String path in imagePaths) {
        fileContent += "file '$path'\nduration ${1 / fps}\n";
      }
      if (imagePaths.isNotEmpty) fileContent += "file '${imagePaths.last}'\n";
      await listFile.writeAsString(fileContent);

      onProgress(0.3);

      // Comando optimizado: crf 28 (buena calidad/poco peso) + preset superfast
      final String command = "-y -f concat -safe 0 -i ${listFile.path} -c:v libx264 -crf 28 -preset superfast -pix_fmt yuv420p -vf \"scale=trunc(iw/2)*2:trunc(ih/2)*2\" $outputPath";
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      onProgress(1.0);
      return ReturnCode.isSuccess(returnCode) ? outputPath : null;
    } catch (e) {
      print("Error exportación móvil: $e");
      return null;
    }
  }
}