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

  // 1. GUARDAR PROYECTO
  Future<void> saveProject(QuackProject project) async {
    if (_userId.isEmpty) return;

    try {
      print("🦆 Iniciando subida de fotos a la nube...");

      final List<Future<String>> uploadTasks = [];
      for (int i = 0; i < project.photoPaths.length; i++) {
        uploadTasks.add(
          _processAndUploadImage(project.photoPaths[i], project.id, i),
        );
      }

      List<String> cloudUrls = await Future.wait(uploadTasks);

      await _db
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .doc(project.id)
          .set({
            'id': project.id,
            'name': project.name,
            'artistName': project.artistName,
            'date': project.date.toIso8601String(),
            'photoPaths': cloudUrls,
            'isPublished': project.isPublished,
            'workshopCode': project.workshopCode,
            'userId': _userId,
            'lastModified': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      print("🦆 ¡Proyecto '${project.name}' guardado correctamente!");
    } catch (e) {
      print("Error en saveProject: $e");
      rethrow;
    }
  }

  // 2. LEER PROYECTOS PERSONALES
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

  // 3. LEER LA GALERÍA DEL GRUPO (Crucial para la prueba entre cuentas)
  Stream<List<QuackProject>> getWorkshopProjects(String workshopCode) {
    if (workshopCode.isEmpty) return Stream.value([]);

    // 🦆 Quitamos los '.where' de Firebase para evitar errores de índice
    return _db.collectionGroup('projects').snapshots().map((snapshot) {
      // 🛠️ Filtramos manualmente en la App
      final projects = snapshot.docs
          .map((doc) => QuackProject.fromJson(doc.data()))
          .where((p) {
            // Solo proyectos que coincidan con el código y que estén publicados
            return p.workshopCode == workshopCode && p.isPublished == true;
          })
          .toList();

      // Orden manual: del más nuevo al más viejo
      projects.sort((a, b) => b.date.compareTo(a.date));

      print(
        "🦆 Galería Grupal: Cargados ${projects.length} proyectos para el código $workshopCode",
      );
      return projects;
    });
  }

  // 4. BORRAR PROYECTO (Requerido por tu ProjectGridView)
  Future<void> deleteProject(String projectId) async {
    if (_userId.isEmpty) return;
    try {
      await _db
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .doc(projectId)
          .delete();
      print("🦆 Proyecto eliminado de Firestore");
    } catch (e) {
      print("Error al borrar: $e");
    }
  }

  // 5. BORRAR CUENTA (Requerido por tu ProfilePage)
  Future<void> deleteUserAccount() async {
    if (_userId.isEmpty) return;
    try {
      // Borrar proyectos
      final projects = await _db
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .get();
      for (var doc in projects.docs) {
        await doc.reference.delete();
      }
      // Borrar usuario en DB y Auth
      await _db.collection('users').doc(_userId).delete();
      await _auth.currentUser?.delete();
      print("🦆 Cuenta eliminada para siempre");
    } catch (e) {
      print("Error al eliminar cuenta: $e");
      rethrow;
    }
  }

  // Función auxiliar de subida de fotos
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
}
