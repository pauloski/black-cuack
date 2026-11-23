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
  // Perfil local dueño (HDU6): cada perfil ve solo sus proyectos. '' = general.
  final String ownerProfileId;
  // Autoría de versión (HDU5/aula): rol del autor al guardar (ej. 'Director')
  // e indicador de si es una versión colaborativa del grupo entero.
  final String authorRole;
  final bool isCollaborative;
  // Equipo del proyecto (HDU aula): ids de los perfiles asociados (dueño +
  // compañeros). El proyecto aparece en "Mis proyectos" de cada miembro.
  final List<String> memberProfileIds;

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
    this.ownerProfileId = '',
    this.authorRole = '',
    this.isCollaborative = false,
    this.memberProfileIds = const [],
  });

  QuackProject copyWith({
    String? name,
    String? artistName,
    List<String>? photoPaths,
    DateTime? date,
    bool? isPublished,
    String? workshopCode,
    String? userId,
    bool? isDraft,
    String? aspect,
    String? parentId,
    String? ownerProfileId,
    String? authorRole,
    bool? isCollaborative,
    List<String>? memberProfileIds,
  }) {
    return QuackProject(
      id: id,
      name: name ?? this.name,
      artistName: artistName ?? this.artistName,
      photoPaths: photoPaths ?? this.photoPaths,
      date: date ?? this.date,
      isPublished: isPublished ?? this.isPublished,
      workshopCode: workshopCode ?? this.workshopCode,
      userId: userId ?? this.userId,
      isDraft: isDraft ?? this.isDraft,
      aspect: aspect ?? this.aspect,
      parentId: parentId ?? this.parentId,
      ownerProfileId: ownerProfileId ?? this.ownerProfileId,
      authorRole: authorRole ?? this.authorRole,
      isCollaborative: isCollaborative ?? this.isCollaborative,
      memberProfileIds: memberProfileIds ?? this.memberProfileIds,
    );
  }

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
    'ownerProfileId': ownerProfileId,
    'authorRole': authorRole,
    'isCollaborative': isCollaborative,
    'memberProfileIds': memberProfileIds,
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
      ownerProfileId: json['ownerProfileId'] ?? '',
      authorRole: json['authorRole'] ?? '',
      isCollaborative: json['isCollaborative'] ?? false,
      memberProfileIds: (json['memberProfileIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
