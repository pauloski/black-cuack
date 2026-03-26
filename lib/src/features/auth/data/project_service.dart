import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // <--- NUEVA
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:http/http.dart' as http; // Útil para subir desde la web

class ProjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // 1. GUARDAR O ACTUALIZAR UN PROYECTO (CON SUBIDA DE IMÁGENES)
  Future<void> saveProject(QuackProject project) async {
    if (_userId.isEmpty) return;

    try {
      List<String> cloudUrls = [];

      // SUBIDA DE IMÁGENES A STORAGE
      for (int i = 0; i < project.photoPaths.length; i++) {
        String path = project.photoPaths[i];

        // Si ya es una URL de internet (http), no la subimos de nuevo
        if (path.startsWith('http')) {
          cloudUrls.add(path);
          continue;
        }

        // Creamos una referencia única para la imagen en Storage
        String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        Reference ref = _storage.ref().child('users/$_userId/projects/${project.id}/$fileName');

        String downloadUrl;
        
        if (kIsWeb) {
          // Lógica especial para WEB (usando bytes)
          final response = await http.get(Uri.parse(path));
          final bytes = response.bodyBytes;
          await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
          downloadUrl = await ref.getDownloadURL();
        } else {
          // Lógica para MÓVIL (usando File)
          await ref.putFile(File(path));
          downloadUrl = await ref.getDownloadURL();
        }

        cloudUrls.add(downloadUrl);
      }

      // GUARDAR DATOS EN FIRESTORE CON LAS URLs REALES
      await _db
          .collection('users')
          .doc(_userId)
          .collection('projects')
          .doc(project.id)
          .set({
        'id': project.id,
        'name': project.name,
        'date': project.date.toIso8601String(),
        'photoPaths': cloudUrls, // <--- Ahora son URLs eternas de Google
        'lastModified': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print("🦆 Proyecto y fotos guardados en la nube exitosamente!");
    } catch (e) {
      print("Error en saveProject: $e");
      rethrow;
    }
  }

  // 2. LEER PROYECTOS (Igual que antes, pero ahora traerá URLs reales)
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

  // 3. BORRAR PROYECTO (Debería borrar también las fotos en Storage después)
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
      
      // Nota: Borrar los archivos de Storage requiere un bucle extra, 
      // lo podemos añadir luego para no complicar el código ahora.
    } catch (e) {
      print("Error al borrar: $e");
    }
  }
}