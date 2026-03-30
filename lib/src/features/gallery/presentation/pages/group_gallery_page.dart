import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart';

class GroupGalleryPage extends StatelessWidget {
  final String groupName;
  final String groupCode;

  const GroupGalleryPage({
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
        // ✅ Aquí es donde el ProjectService busca los Quacks de ambas cuentas
        stream: _projectService.getWorkshopProjects(groupCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFBC87FE)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("🦆", style: TextStyle(fontSize: 50)),
                  const SizedBox(height: 15),
                  Text(
                    "¡AÚN NO HAY QUACKS EN ESTE GRUPO!",
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          final projects = snapshot.data!;

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
              return _buildProjectCard(project);
            },
          );
        },
      ),
    );
  }

  Widget _buildProjectCard(QuackProject project) {
    return Container(
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
                project
                    .photoPaths
                    .last, // Mostramos la última foto como portada
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black26,
                  child: const Icon(Icons.broken_image, color: Colors.white10),
                ),
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
    );
  }
}
