class QuackProject {
  final String id;
  final String name;
  final List<String> photoPaths;
  final DateTime date;

  QuackProject({
    required this.id,
    required this.name,
    required this.photoPaths,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'photoPaths': photoPaths,
    'date': date.toIso8601String(),
  };

  factory QuackProject.fromJson(Map<String, dynamic> json) => QuackProject(
    id: json['id'],
    name: json['name'],
    photoPaths: List<String>.from(json['photoPaths']),
    date: DateTime.parse(json['date']),
  );
}