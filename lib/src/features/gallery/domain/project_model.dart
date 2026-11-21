class QuackProject {
  final String id;
  final String name;
  final String artistName;
  final List<String> photoPaths;
  final DateTime date;
  final bool isPublished;
  final String? workshopCode;
  final String userId; // ✅ Agregamos el campo de ID de usuario
  // Borrador: proyecto en curso aún sin "Guardar" (título/artista). Protege sus
  // cuadros de la limpieza de huérfanos y permite reabrir tras un cierre.
  final bool isDraft;
  // Orientación fija del proyecto: '9:16' (vertical) o '16:9' (horizontal).
  final String aspect;
  // Si no es null, este registro es una **versión** del proyecto [parentId]
  // (comparte cuadros por id, no se duplica el almacenamiento).
  final String? parentId;

  QuackProject({
    required this.id,
    required this.name,
    this.artistName = 'Artista Anónimo',
    required this.photoPaths,
    required this.date,
    this.isPublished = false,
    this.workshopCode,
    this.userId = '', // ✅ Valor por defecto por si acaso
    this.isDraft = false,
    this.aspect = '9:16',
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'artistName': artistName,
    'photoPaths': photoPaths,
    'date': date.toIso8601String(),
    'isPublished': isPublished,
    'workshopCode': workshopCode,
    'userId': userId, // ✅ Lo incluimos en el mapa de salida
    'isDraft': isDraft,
    'aspect': aspect,
    'parentId': parentId,
  };

  factory QuackProject.fromJson(Map<String, dynamic> json) {
    return QuackProject(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Pato Sin Nombre',
      artistName: json['artistName'] ?? 'Artista Anónimo',
      // ✅ Conversión más segura para la lista de URLs
      photoPaths:
          (json['photoPaths'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      isPublished: json['isPublished'] ?? false,
      workshopCode: json['workshopCode'],
      userId: json['userId'] ?? '', // ✅ Lo recuperamos de Firebase
      isDraft: json['isDraft'] ?? false,
      aspect: json['aspect'] ?? '9:16',
      parentId: json['parentId'],
    );
  }
}
