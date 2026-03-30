class QuackProject {
  final String id;
  final String name;
  final String artistName;
  final List<String> photoPaths;
  final DateTime date;
  final bool isPublished;
  final String? workshopCode;
  final String userId; // ✅ Agregamos el campo de ID de usuario

  QuackProject({
    required this.id,
    required this.name,
    this.artistName = 'Artista Anónimo',
    required this.photoPaths,
    required this.date,
    this.isPublished = false,
    this.workshopCode,
    this.userId = '', // ✅ Valor por defecto por si acaso
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
    );
  }
}
