import 'package:camera/camera.dart';

/// Elige la cámara **trasera** (la que apunta a la mesa en stop motion).
///
/// - Si hay varias traseras (gran angular, ultra gran angular…), usa la primera,
///   que suele ser la principal.
/// - Si no hay trasera (p. ej. la webcam del Mac, que es frontal/externa), usa la
///   primera cámara disponible, sin error.
///
/// [cams] no debe estar vacío (el llamador lo garantiza).
CameraDescription pickBackCamera(List<CameraDescription> cams) {
  for (final c in cams) {
    if (c.lensDirection == CameraLensDirection.back) return c;
  }
  return cams.first;
}
