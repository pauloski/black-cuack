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

  // 1. GUARDAR PROYECTO (OPTIMIZADO CON SUBIDA PARALELA)
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

      await _db
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .doc(project.id)
          .set({
            'id': project.id,
            'name': project.name,
            'date': project.date.toIso8601String(),
            'photoPaths': cloudUrls,
            'lastModified': FieldValue.serverTimestamp(),
            'userId':
                _userId, // Añadimos esto para saber de quién es en la galería grupal
          }, SetOptions(merge: true));

      print("🦆 ¡Todo guardado a la velocidad del rayo!");
    } catch (e) {
      print("Error en saveProject: $e");
      rethrow;
    }
  }

  // Función auxiliar para procesar imágenes
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
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return QuackProject(
              id: data['id'],
              name: data['name'],
              date: DateTime.parse(data['date']),
              photoPaths: List<String>.from(data['photoPaths'] ?? []),
            );
          }).toList();
        });
  }

  // 3. LEER TODOS LOS PROYECTOS DEL TALLER (GALERÍA GRUPAL)
  // Esta función permite ver lo que todos están cocinando
  Stream<List<QuackProject>> getAllWorkshopProjects() {
    return _db
        .collectionGroup('projects')
        .orderBy('date', descending: true)
        .snapshots()
        .handleError((error) {
          print(
            "🦆 Error en la Charca: $error",
          ); // Esto nos dirá qué pasa en la consola
        })
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return QuackProject(
              id:
                  data['id'] ??
                  doc.id, // Si no tiene ID, usamos el del documento
              name: data['name'] ?? 'Pato Sin Nombre',
              date: data['date'] != null
                  ? DateTime.parse(data['date'])
                  : DateTime.now(),
              photoPaths: List<String>.from(data['photoPaths'] ?? []),
            );
          }).toList();
        });
  }

  // 4. BORRAR PROYECTO
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
}
