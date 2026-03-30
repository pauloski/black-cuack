import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:http/http.dart' as http;

class ProjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // 1. GUARDAR PROYECTO (AHORA CON IDENTIDAD Y PRIVACIDAD)
  Future<void> saveProject(QuackProject project) async {
    if (_userId.isEmpty) return;

    try {
      print(
        "🦆 Iniciando subida paralela de ${project.photoPaths.length} fotos...",
      );

      final List<Future<String>> uploadTasks = [];
      for (int i = 0; i < project.photoPaths.length; i++) {
        String path = project.photoPaths[i];
        uploadTasks.add(_processAndUploadImage(path, project.id, i));
      }

      List<String> cloudUrls = await Future.wait(uploadTasks);

      // Guardamos con los nuevos campos del modelo
      await _db
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .doc(project.id)
          .set({
            'id': project.id,
            'name': project.name,
            'artistName': project.artistName, // ✅ Identidad
            'date': project.date.toIso8601String(),
            'photoPaths': cloudUrls,
            'isPublished': project.isPublished, // ✅ Privacidad
            'workshopCode': project.workshopCode, // ✅ Grupo
            'userId': _userId,
            'lastModified': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      print("🦆 ¡Proyecto '${project.name}' guardado correctamente!");
    } catch (e) {
      print("Error en saveProject: $e");
      rethrow;
    }
  }

  // Función auxiliar de procesamiento (Sin cambios, funciona perfecto)
  Future<String> _processAndUploadImage(
    String path,
    String projectId,
    int index,
  ) async {
    if (path.startsWith('http')) return path;

    String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}_$index.jpg';
    Reference ref = _storage.ref().child(
      'users/$_userId/projects/$projectId/$fileName',
    );

    if (kIsWeb) {
      final response = await http.get(Uri.parse(path));
      await ref.putData(
        response.bodyBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
    } else {
      await ref.putFile(File(path));
    }
    return await ref.getDownloadURL();
  }

  // 2. LEER PROYECTOS PERSONALES (MIS QUACKS)
  Stream<List<QuackProject>> getProjectsStream() {
    if (_userId.isEmpty) return Stream.value([]);

    return _db
        .collection('users')
        .doc(_userId)
        .collection('projects')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => QuackProject.fromJson(doc.data()))
              .toList();
        });
  }

  // 3. LEER LA CHARCA (FILTRADO POR CÓDIGO Y PUBLICACIÓN)
  // ✅ Crucial para el taller: Solo muestra lo que el autor decidió compartir
  Stream<List<QuackProject>> getWorkshopProjects(String workshopCode) {
    return _db
        .collectionGroup('projects')
        .where('workshopCode', isEqualTo: workshopCode) // ✅ Solo este taller
        .where('isPublished', isEqualTo: true) // ✅ Solo lo publicado
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => QuackProject.fromJson(doc.data()))
              .toList();
        });
  }

  // 4. BORRAR PROYECTO Y DATOS (REQUISITO GOOGLE PLAY)
  Future<void> deleteProject(String projectId) async {
    if (_userId.isEmpty) return;
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .doc(projectId)
          .delete();
      print("🦆 Proyecto eliminado");
    } catch (e) {
      print("Error al borrar: $e");
    }
  }

  // 5. BORRAR CUENTA COMPLETA (OBLIGATORIO GOOGLE PLAY)
  Future<void> deleteUserAccount() async {
    if (_userId.isEmpty) return;
    try {
      // 1. Borrar documentos de Firestore
      final projects = await _db
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .get();
      for (var doc in projects.docs) {
        await doc.reference.delete();
      }
      await _db.collection('users').doc(_userId).delete();

      // 2. Borrar del sistema de Auth
      await _auth.currentUser?.delete();
      print("🦆 Cuenta eliminada para siempre");
    } catch (e) {
      print("Error al eliminar cuenta: $e");
      rethrow;
    }
  }
}
