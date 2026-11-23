import 'package:shared_preferences/shared_preferences.dart';

/// Sala/taller activo (DEMO, local y dummy). Vacío = sin sala.
///
/// No hay backend: unirse a una sala solo guarda su código localmente; el
/// código etiqueta los proyectos (`workshopCode`) para que un dispositivo
/// compartido muestre "los proyectos del grupo". El docente "crea" una sala
/// generando un código (ver `generateGroupCode`). Es coherente con el principio
/// local-first: funciona sin conexión. La sala real con backend es futura.
String activeWorkshopCode = '';

class WorkshopService {
  static const String _activeKey = 'bq_active_workshop';

  /// Carga la sala activa persistida (si existe) a [activeWorkshopCode].
  static Future<void> loadActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      activeWorkshopCode = prefs.getString(_activeKey) ?? '';
    } catch (_) {
      activeWorkshopCode = '';
    }
  }

  static Future<void> setActive(String code) async {
    activeWorkshopCode = code.trim().toUpperCase();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeKey, activeWorkshopCode);
    } catch (_) {}
  }

  static Future<void> clear() async {
    activeWorkshopCode = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeKey);
    } catch (_) {}
  }
}
