// Implementación por defecto (VM / nativo): sin efecto. En nativo, la orientación
// se maneja con SystemChrome (tarea de la APK), no con APIs del navegador.

Future<void> enterFullscreen() async {}

Future<void> exitFullscreen() async {}

/// Devuelve true si logró bloquear la orientación. En el stub, siempre false.
Future<bool> lockOrientation(String aspect) async => false;

Future<void> unlockOrientation() async {}
