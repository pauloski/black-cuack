class QuackProject {
  final String id;
  final String name;
  final String artistName; // 🦆 Nombre del autor (obligatorio para el taller)
  final List<String> photoPaths;
  final DateTime date;
  final bool isPublished; // 🚀 Controla la privacidad (¿Va a la Charca?)
  final String? workshopCode; // 🔑 El código que une al grupo

  QuackProject({
    required this.id,
    required this.name,
    this.artistName = 'Artista Anónimo',
    required this.photoPaths,
    required this.date,
    this.isPublished = false,
    this.workshopCode,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'artistName': artistName,
    'photoPaths': photoPaths,
    'date': date.toIso8601String(),
    'isPublished': isPublished,
    'workshopCode': workshopCode,
  };

  factory QuackProject.fromJson(Map<String, dynamic> json) => QuackProject(
    id: json['id'] ?? '',
    name: json['name'] ?? 'Pato Sin Nombre',
    artistName: json['artistName'] ?? 'Artista Anónimo',
    photoPaths: List<String>.from(json['photoPaths'] ?? []),
    date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    isPublished: json['isPublished'] ?? false,
    workshopCode: json['workshopCode'],
  );
}
