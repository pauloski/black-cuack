import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart' show XFile;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

/// Un `XFile` de **sesión** creado a partir de bytes para que la cámara/visor
/// (que renderizan por ruta) muestren cuadros que viven en el repo local.
///
/// En web usa un blob URL que **debe revocarse** con [revoke] al dejar de usarlo
/// (evita fugas). En nativo escribe un archivo temporal.
class SessionImage {
  final XFile file;
  final String? _blobUrl;

  SessionImage._(this.file, this._blobUrl);

  void revoke() {
    final url = _blobUrl;
    if (url != null) {
      try {
        html.Url.revokeObjectUrl(url);
      } catch (_) {}
    }
  }
}

/// Crea un [SessionImage] a partir de [bytes].
Future<SessionImage> sessionImageFromBytes(
  Uint8List bytes, {
  String ext = 'jpg',
}) async {
  if (kIsWeb) {
    final url = html.Url.createObjectUrlFromBlob(html.Blob(<dynamic>[bytes]));
    return SessionImage._(XFile(url), url);
  }
  final dir = await getTemporaryDirectory();
  final path =
      '${dir.path}/sess_${DateTime.now().microsecondsSinceEpoch}_${bytes.length}.$ext';
  await File(path).writeAsBytes(bytes);
  return SessionImage._(XFile(path), null);
}
