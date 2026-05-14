import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

String _mapFirebaseError(dynamic e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'user-not-found':     return 'No existe una cuenta con ese email.';
      case 'wrong-password':     return 'Contraseña incorrecta.';
      case 'invalid-credential': return 'Email o contraseña incorrectos.';
      case 'email-already-in-use': return 'Ese email ya está registrado.';
      case 'weak-password':      return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':      return 'El formato del email no es válido.';
      case 'too-many-requests':  return 'Demasiados intentos. Espera un momento.';
      case 'network-request-failed': return 'Sin conexión. Verifica tu red.';
    }
  }
  return 'Error inesperado. Intenta de nuevo.';
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User> signUp(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) await sendEmailVerification(result.user!);
      return result.user!;
    } catch (e) {
      debugPrint("Error en registro: $e");
      throw AuthException(_mapFirebaseError(e));
    }
  }

  Future<User> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user!;
    } catch (e) {
      debugPrint("Error en login: $e");
      throw AuthException(_mapFirebaseError(e));
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      debugPrint("🦆 Entrando como Artista Invitado: ${result.user?.uid}");
      return result.user;
    } catch (e) {
      debugPrint("⚠️ Error en login anónimo: $e");
      return null;
    }
  }

  Future<void> sendEmailVerification(User user) async {
    try {
      await user.sendEmailVerification();
      debugPrint("🦆 Correo de verificación enviado a: ${user.email}");
    } catch (e) {
      debugPrint("Error al enviar verificación: $e");
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint("Error al enviar reset: $e");
      throw AuthException(_mapFirebaseError(e));
    }
  }

  Future<void> signOut() async => _auth.signOut();

  User? get currentUser => _auth.currentUser;
}
