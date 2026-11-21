// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
// Archivo exclusivo de web (se selecciona por conditional import); usa dart:html
// a propósito para las APIs de pantalla completa y orientación del navegador.
//
// Implementación web: pantalla completa + bloqueo de orientación.
// En Android, el navegador solo permite bloquear la orientación en pantalla
// completa, por eso se piden juntas. Todo es best-effort: si el navegador rechaza
// algo, la app igual detecta el desajuste por MediaQuery y muestra el aviso.
import 'dart:async';
import 'dart:html' as html;

Future<void> enterFullscreen() async {
  try {
    final el = html.document.documentElement;
    if (el != null && html.document.fullscreenElement == null) {
      await el.requestFullscreen();
    }
  } catch (_) {/* el navegador puede exigir gesto del usuario */}
}

Future<void> exitFullscreen() async {
  try {
    if (html.document.fullscreenElement != null) {
      html.document.exitFullscreen();
    }
  } catch (_) {}
}

Future<bool> lockOrientation(String aspect) async {
  try {
    final orientation = html.window.screen?.orientation;
    if (orientation == null) return false;
    final mode = aspect == '16:9' ? 'landscape' : 'portrait';
    await orientation.lock(mode);
    return true;
  } catch (_) {
    return false; // sin pantalla completa, o no soportado
  }
}

Future<void> unlockOrientation() async {
  try {
    html.window.screen?.orientation?.unlock();
  } catch (_) {}
}
