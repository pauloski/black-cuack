import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';

class ProjectStorage {
  static const String _key = 'quack_projects';

  // --- GUARDAR O ACTUALIZAR PROYECTO ---
  static Future<void> saveProject(QuackProject project) async {
    final prefs = await SharedPreferences.getInstance();
    final List<QuackProject> currentProjects = await loadProjects();
    
    // Buscamos si el proyecto ya existe por su ID
    final int index = currentProjects.indexWhere((p) => p.id == project.id);

    if (index != -1) {
      // Si ya existe (EDICIÓN), lo reemplazamos en su lugar
      currentProjects[index] = project;
    } else {
      // Si es nuevo (NUEVO PROYECTO), lo insertamos al principio
      currentProjects.insert(0, project);
    }

    final String encodedData = jsonEncode(
      currentProjects.map((p) => p.toJson()).toList(),
    );
    await prefs.setString(_key, encodedData);
  }

  // --- ELIMINAR PROYECTO ---
  static Future<void> deleteProject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<QuackProject> currentProjects = await loadProjects();
    
    // Filtramos la lista para quitar el proyecto con el ID seleccionado
    currentProjects.removeWhere((p) => p.id == id);

    final String encodedData = jsonEncode(
      currentProjects.map((p) => p.toJson()).toList(),
    );
    await prefs.setString(_key, encodedData);
  }

  // --- CARGAR PROYECTOS ---
  static Future<List<QuackProject>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];

    final List decodedData = jsonDecode(data);
    return decodedData.map((item) => QuackProject.fromJson(item)).toList();
  }
}