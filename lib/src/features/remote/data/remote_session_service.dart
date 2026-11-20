import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

class RemoteSessionService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  String get _userId => _auth.currentUser?.uid ?? 'anonymous';

  String generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> createSession() async {
    final code = generateCode();
    await _db.collection('sessions').doc(code).set({
      'studioUserId': _userId,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    debugPrint('📡 Sesión remota creada: $code');
    return code;
  }

  Future<void> closeSession(String code) async {
    try {
      await _db.collection('sessions').doc(code).update({'isActive': false});
      debugPrint('📡 Sesión $code cerrada');
    } catch (e) {
      debugPrint('⚠️ Error cerrando sesión: $e');
    }
  }

  Future<bool> sessionIsActive(String code) async {
    try {
      final doc = await _db.collection('sessions').doc(code.toUpperCase()).get();
      return doc.exists && (doc.data()?['isActive'] == true);
    } catch (e) {
      debugPrint('⚠️ Error verificando sesión: $e');
      return false;
    }
  }

  Stream<List<String>> getFrameUrlsStream(String code) {
    return _db
        .collection('sessions')
        .doc(code)
        .collection('frames')
        .orderBy('index')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d['url'] as String).toList())
        .handleError((e) {
      debugPrint('⚠️ Error en stream de frames ($code): $e');
      return <String>[];
    });
  }

  Future<void> uploadFrame(String code, String imagePath) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('sessions/$code/frame_$timestamp.jpg');

    if (kIsWeb) {
      final response = await http.get(Uri.parse(imagePath));
      await ref.putData(
        response.bodyBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
    } else {
      await ref.putFile(File(imagePath));
    }

    final url = await ref.getDownloadURL();

    final snap = await _db
        .collection('sessions')
        .doc(code)
        .collection('frames')
        .get();

    await _db.collection('sessions').doc(code).collection('frames').add({
      'url': url,
      'index': snap.docs.length,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('🦆 Frame subido a sesión $code (total: ${snap.docs.length + 1})');
  }
}
