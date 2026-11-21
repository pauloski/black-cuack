import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:blackcuack_studio/src/features/profile/domain/profile_model.dart';

/// Perfil activo (demo). Vacío = sin perfil (biblioteca general).
String activeProfileId = '';

/// Almacén local de perfiles (Hive). Hive ya se inicializa en initRepositories.
class ProfileService {
  static const String boxName = 'bq_profiles';
  static const String _activeKey = 'bq_active_profile';

  static Future<Box<String>> _box() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box<String>(boxName);
    return Hive.openBox<String>(boxName);
  }

  static Future<List<Profile>> list() async {
    final box = await _box();
    return box.values
        .map((j) => Profile.fromJson(jsonDecode(j) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(Profile p) async {
    final box = await _box();
    await box.put(p.id, jsonEncode(p.toJson()));
  }

  /// Carga el perfil activo persistido (si existe) a [activeProfileId].
  static Future<void> loadActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      activeProfileId = prefs.getString(_activeKey) ?? '';
    } catch (_) {
      activeProfileId = '';
    }
  }

  static Future<void> setActive(String id) async {
    activeProfileId = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeKey, id);
    } catch (_) {}
  }
}
