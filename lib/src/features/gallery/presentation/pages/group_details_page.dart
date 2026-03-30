import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/movie_player_page.dart';

class GroupDetailsPage extends StatelessWidget {
  final String groupName;
  final String groupCode;

  const GroupDetailsPage({
    super.key,
    required this.groupName,
    required this.groupCode,
  });

  @override
  Widget build(BuildContext context) {
    final ProjectService _projectService = ProjectService();

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              groupName.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'LuckiestGuy',
                color: Color(0xFFC1FFFE),
                fontSize: 18,
              ),
            ),
            Text(
              "CÓDIGO: $groupCode",
              style: const TextStyle(
                fontFamily: 'Lexend',
                color: Colors.white24,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<QuackProject>>(
        stream: _projectService.getWorkshopProjects(groupCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFBC87FE)),
            );
          }

          final projects = snapshot.data ?? [];

          if (projects.isEmpty) {
            return Center(
              child: Text(
                "¡AÚN NO HAY QUACKS COMPARTIDOS!",
                style: TextStyle(
                  fontFamily: 'Lexend',
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 12,
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.8,
            ),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];

              // 🔥 CAMBIO CLAVE: El GestureDetector ahora envuelve TODO y tiene comportamiento de Link
              return MouseRegion(
                cursor: SystemMouseCursors.click, // ✅ Activa la manito en Web
                child: GestureDetector(
                  behavior:
                      HitTestBehavior.opaque, // ✅ Detecta clics en toda el área
                  onTap: () {
                    print("🦆 Tocaste el proyecto: ${project.name}");
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MoviePlayerPage(project: project),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                            child: Image.network(
                              project.photoPaths.isNotEmpty
                                  ? project.photoPaths.last
                                  : '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, e, s) =>
                                  Container(color: Colors.black26),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFFC1FFFE),
                                  fontFamily: 'LuckiestGuy',
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "POR: ${project.artistName}",
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontFamily: 'Lexend',
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
