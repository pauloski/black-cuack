/// Perfil local de estudiante (demo, sin nube): apodo, avatar (emoji) y una
/// "clave de imágenes" = 3 dibujos en orden (índices de un set). No sale del
/// dispositivo.
class Profile {
  final String id;
  final String nickname;
  final String avatar; // emoji
  final List<int> imageKey; // 3 índices
  // Rol en el taller (HDU aula): 'Animador', 'Cámara', 'Director' o texto libre.
  // '' = sin rol asignado.
  final String role;

  Profile({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.imageKey,
    this.role = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nickname': nickname,
        'avatar': avatar,
        'imageKey': imageKey,
        'role': role,
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] ?? '',
        nickname: json['nickname'] ?? '',
        avatar: json['avatar'] ?? '🦆',
        imageKey: (json['imageKey'] as List?)?.map((e) => e as int).toList() ??
            const [],
        role: json['role'] ?? '',
      );
}
