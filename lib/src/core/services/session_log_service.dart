import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive_ce/hive.dart';

/// Registro local mínimo de actividad de la sesión (capturas y versiones) por
/// sala y perfil. **Sin UI**: deja los datos listos para que un futuro dashboard
/// docente los lea (CLAUDE.md §8: dashboard fuera de esta semana, pero los datos
/// se registran ya). Append-only en Hive; nunca debe romper la creación.
class SessionLogService {
  static const String boxName = 'bq_session_log';

  static Future<Box<String>> _box() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box<String>(boxName);
    return Hive.openBox<String>(boxName);
  }

  /// [type]: 'capture' | 'version'.
  static Future<void> log({
    required String type,
    required String workshopCode,
    required String profileId,
    String projectId = '',
  }) async {
    try {
      final box = await _box();
      await box.add(jsonEncode({
        'ts': DateTime.now().toIso8601String(),
        'type': type,
        'workshopCode': workshopCode,
        'profileId': profileId,
        'projectId': projectId,
      }));
    } catch (e) {
      debugPrint('session log falló (ignorado): $e');
    }
  }

  /// Todos los eventos (para depuración / dashboard futuro).
  static Future<List<Map<String, dynamic>>> all() async {
    try {
      final box = await _box();
      return box.values
          .map((j) => jsonDecode(j) as Map<String, dynamic>)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
