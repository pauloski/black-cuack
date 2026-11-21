import 'package:flutter/foundation.dart';

/// Overlay de depuración activable con `?debug=1` en la URL (web). Permite medir
/// en un celular/tablet **Android** (abriendo la demo en Chrome) sin consola.
final bool kShowDebugOverlay =
    kIsWeb && Uri.base.queryParameters['debug'] == '1';

/// Último dato de compresión (ms/cuadro), mostrado en el overlay.
final ValueNotifier<String> compressionDebug = ValueNotifier<String>('—');
