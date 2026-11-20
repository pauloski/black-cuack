import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;

@JS('_ffmpegLoad')
external JSPromise<JSAny?> _ffmpegLoad();

@JS('_ffmpegWriteFile')
external void _ffmpegWriteFile(JSString name, JSUint8Array data);

@JS('_ffmpegRun')
external JSPromise<JSAny?> _ffmpegRun(JSString cmd);

@JS('_ffmpegReadFile')
external JSUint8Array _ffmpegReadFile(JSString name);

@JS('_ffmpegUnlink')
external void _ffmpegUnlink(JSString name);

class WebFFmpeg {
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    await _ffmpegLoad().toDart;
    _loaded = true;
  }

  static Future<Uint8List?> framesToMp4(
    List<Uint8List> frames,
    double fps, {
    Function(double)? onProgress,
  }) async {
    try {
      await load();
      onProgress?.call(0.1);

      for (int i = 0; i < frames.length; i++) {
        final name = 'frame_${i.toString().padLeft(3, '0')}.jpg';
        _ffmpegWriteFile(name.toJS, frames[i].toJS);
        onProgress?.call(0.1 + (i + 1) / frames.length * 0.5);
      }

      final fpsStr = fps.toStringAsFixed(2);
      final cmd =
          '-framerate $fpsStr -i frame_%03d.jpg -c:v libx264 -pix_fmt yuv420p output.mp4';
      await _ffmpegRun(cmd.toJS).toDart;
      onProgress?.call(0.9);

      final result = _ffmpegReadFile('output.mp4'.toJS);
      final bytes = result.toDart;

      for (int i = 0; i < frames.length; i++) {
        _ffmpegUnlink('frame_${i.toString().padLeft(3, '0')}.jpg'.toJS);
      }
      _ffmpegUnlink('output.mp4'.toJS);

      onProgress?.call(1.0);
      return bytes;
    } catch (e) {
      debugPrint('WebFFmpeg error: $e');
      return null;
    }
  }
}
