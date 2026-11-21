import 'package:firebase_auth/firebase_auth.dart';

/// Acceso a funciones de nube (grupos, publicar al taller).
///
/// Requiere una **cuenta real** (no invitado anónimo). El inicio anónimo en
/// segundo plano hace que `currentUser` no sea `null`, por eso NO basta con
/// `currentUser == null`: un invitado quedaría habilitado. Aquí exigimos que el
/// usuario exista y **no** sea anónimo.
///
/// La conexión no se verifica por separado: haber iniciado una cuenta real
/// implica conexión previa, y las operaciones de nube fallan de forma controlada
/// sin red.
bool get hasCloudAccount {
  final u = FirebaseAuth.instance.currentUser;
  return u != null && !u.isAnonymous;
}
