import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart'; // Para debugPrint

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

  // 3. LEER LA GALERÍA DEL GRUPO
  Stream<List<QuackProject>> getWorkshopProjects(String workshopCode) {
    if (workshopCode.isEmpty) return Stream.value([]);

    return _db.collectionGroup('projects').snapshots().map((snapshot) {
      final projects = snapshot.docs
          .map((doc) => QuackProject.fromJson(doc.data()))
          .where((p) {
            return p.workshopCode == workshopCode && p.isPublished == true;
          })
          .toList();

      projects.sort((a, b) => b.date.compareTo(a.date));
      return projects;
    });
  }

  // 4. 🧹 BORRADO TOTAL (Firestore + Storage)
  // Ahora requiere las rutas de las fotos para poder borrarlas físicamente
  Future<void> deleteProjectFull(
    String projectId,
    List<String> photoUrls,
  ) async {
    if (_userId.isEmpty) return;

    try {
      print("🧹 Iniciando limpieza profunda del proyecto: $projectId");

      // A. Borrar archivos físicos en Storage
      for (String url in photoUrls) {
        try {
          if (url.contains('firebasestorage')) {
            // Solo intentar borrar si es link de Firebase
            await _storage.refFromURL(url).delete();
            debugPrint("🗑️ Foto borrada de Storage");
          }
        } catch (e) {
          debugPrint(
            "⚠️ No se pudo borrar foto en Storage (puede que no exista): $e",
          );
        }
      }

      // B. Borrar el documento en Firestore
      await _db
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .doc(projectId)
          .delete();

      print("🦆 Proyecto y fotos eliminados de la charca.");
    } catch (e) {
      print("Error al realizar borrado total: $e");
    }
  }

  // 5. BORRAR CUENTA
  Future<void> deleteUserAccount() async {
    if (_userId.isEmpty) return;
    try {
      final projects = await _db
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .get();

      // Limpiamos Storage de cada proyecto antes de borrar la cuenta
      for (var doc in projects.docs) {
        final data = QuackProject.fromJson(doc.data());
        await deleteProjectFull(data.id, data.photoPaths);
      }

      await _db.collection('users').doc(_userId).delete();
      await _auth.currentUser?.delete();
      print("🦆 Cuenta y Storage limpiados para siempre");
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
