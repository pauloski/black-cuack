import 'package:flutter/foundation.dart' show debugPrint;
import 'package:package_info_plus/package_info_plus.dart';

/// Versión de la app leída de **una sola fuente**: pubspec.yaml, vía
/// [PackageInfo] (en web, el `version.json` que genera `flutter build web`).
/// Se carga una vez en el arranque ([loadAppVersion]) y se usa en Ajustes y en el
/// overlay de `?debug=1`. El respaldo solo aplica si PackageInfo no responde.
String appVersion = '0.1.0';

/// Etiqueta lista para mostrar: "BlackQuack Studio · v0.1.0".
String get appVersionLabel => 'BlackQuack Studio · v$appVersion';

Future<void> loadAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    if (info.version.isNotEmpty) appVersion = info.version;
  } catch (e) {
    debugPrint('No se pudo leer la versión (se usa respaldo $appVersion): $e');
  }
}
