import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. REGISTRAR USUARIO
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      // Una vez creado, enviamos el correo de verificación inmediatamente
      if (result.user != null) {
        await sendEmailVerification(result.user!);
      }
      
      return result.user;
    } catch (e) {
      print("Error en registro: $e");
      return null;
    }
  }

  // 2. INICIAR SESIÓN
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      print("Error en login: $e");
      return null;
    }
  }

  // 3. ENVIAR VERIFICACIÓN DE EMAIL (La que necesitabas)
  Future<void> sendEmailVerification(User user) async {
    try {
      await user.sendEmailVerification();
      print("🦆 Correo de verificación enviado a: ${user.email}");
    } catch (e) {
      print("Error al enviar verificación: $e");
    }
  }

  // 4. RECUPERAR CONTRASEÑA
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error al enviar reset: $e");
      rethrow;
    }
  }

  // 5. CERRAR SESIÓN
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Extra: Obtener el usuario actual para chequear si verificó
  User? get currentUser => _auth.currentUser;
}