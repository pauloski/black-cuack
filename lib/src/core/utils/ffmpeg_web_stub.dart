import 'dart:typed_data';

class WebFFmpeg {
  static Future<void> load() async {}

  static Future<Uint8List?> framesToMp4(
    List<Uint8List> frames,
    double fps, {
    Function(double)? onProgress,
  }) async => null;
}
