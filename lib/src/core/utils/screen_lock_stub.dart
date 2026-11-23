// Implementación nativa (VM / Android / iOS): controla pantalla completa y
// bloqueo de orientación con SystemChrome. A diferencia de web, aquí SÍ se puede
// FORZAR la rotación del dispositivo, así que un proyecto 16:9 gira la app a
// horizontal solo y un 9:16 la fija en vertical, sin depender del autogiro del
// sistema. (En web se usa screen_lock_web.dart, que solo puede pedir el bloqueo.)
import 'package:flutter/services.dart';

Future<void> enterFullscreen() async {
  // Oculta barras de estado/navegación durante la captura (modo quiosco ligero).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

Future<void> exitFullscreen() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

/// Fuerza la orientación que exige la relación del proyecto.
/// Devuelve true: en nativo el bloqueo siempre se aplica.
Future<bool> lockOrientation(String aspect) async {
  final orientations = aspect == '16:9'
      // Horizontal: permite ambos lados para que el usuario gire a cualquier flanco.
      ? const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]
      // Vertical: solo hacia arriba (evita quedar al revés).
      : const [DeviceOrientation.portraitUp];
  await SystemChrome.setPreferredOrientations(orientations);
  return true;
}

/// Libera el bloqueo al salir del editor: vuelve a permitir todas las orientaciones.
Future<void> unlockOrientation() async {
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
}
