// Pantalla completa + bloqueo de orientación, con interfaz única.
// En web usa las APIs del navegador; en VM/nativo es no-op (ver stub).
export 'screen_lock_stub.dart' if (dart.library.html) 'screen_lock_web.dart';
