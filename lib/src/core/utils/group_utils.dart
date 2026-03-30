import 'dart:math';

class GroupUtils {
  // 🦆 Alfabeto "limpio": Sin O, 0, I, 1 para evitar errores de los niños
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generateGroupCode() {
    final rnd = Random();
    // Generamos 5 caracteres aleatorios y los unimos
    return List.generate(
      5,
      (index) => _chars[rnd.nextInt(_chars.length)],
    ).join();
  }
}
