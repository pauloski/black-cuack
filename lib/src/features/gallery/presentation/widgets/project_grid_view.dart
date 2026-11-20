import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/features/auth/data/project_service.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/movie_player_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/camera_page.dart';

class ProjectGridView extends StatefulWidget {
  final double bottomPadding;
  const ProjectGridView({super.key, this.bottomPadding = 0});

  @override
  State<ProjectGridView> createState() => _ProjectGridViewState();
}

class _ProjectGridViewState extends State<ProjectGridView> {
  late final ProjectService _projectService;

  @override
  void initState() {
    super.initState();
    _projectService = ProjectService();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QuackProject>>(
      stream: _projectService.getProjectsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.secondary, strokeWidth: 2),
          );
        }
        final proyectos = snapshot.data ?? [];
        if (proyectos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_filter_outlined, color: Colors.white12, size: 56),
                SizedBox(height: 14),
                Text('Sin proyectos todavía',
                  style: TextStyle(color: Colors.white38, fontFamily: 'Lexend', fontSize: 15)),
                SizedBox(height: 6),
                Text('Crea tu primera animación',
                  style: TextStyle(color: Colors.white24, fontFamily: 'Lexend', fontSize: 12)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.only(bottom: widget.bottomPadding),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.88,
          ),
          itemCount: proyectos.length,
          itemBuilder: (context, index) {
            final p = proyectos[index];
            final String? previewUrl = p.photoPaths.isNotEmpty ? p.photoPaths[0] : null;
            return _ProjectCard(
              project: p,
              previewUrl: previewUrl,
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MoviePlayerPage(project: p)),
              ),
              onEdit: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CameraPage(projectToLoad: p)),
              ),
              onDelete: () => _confirmDelete(context, p),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, QuackProject project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.danger, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('¿ELIMINAR?',
          style: TextStyle(fontFamily: 'Lexend', color: AppColors.danger, fontSize: 16),
          textAlign: TextAlign.center),
        content: Text(
          "'${project.name}' será eliminado permanentemente.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontFamily: 'Lexend', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await _projectService.deleteProjectFull(project.id, project.photoPaths);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proyecto eliminado'),
                    backgroundColor: AppColors.danger),
                );
              }
            },
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Project card with overlay action buttons ──────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final QuackProject project;
  final String? previewUrl;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.previewUrl,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Card body
          Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    image: (previewUrl != null && previewUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: kIsWeb
                                ? NetworkImage(previewUrl!) as ImageProvider
                                : FileImage(File(previewUrl!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: previewUrl == null || previewUrl!.isEmpty
                      ? const Center(
                          child: Icon(Icons.movie_filter_rounded,
                            color: Colors.white12, size: 36))
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${project.date.day}/${project.date.month}',
                      style: const TextStyle(
                        color: Colors.white30,
                        fontFamily: 'Lexend',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Overlay: edit + delete buttons on top-right of thumbnail
          Positioned(
            top: 6,
            right: 6,
            child: Row(
              children: [
                _OverlayBtn(
                  icon: Icons.edit_rounded,
                  color: AppColors.primary,
                  onTap: onEdit,
                ),
                const SizedBox(width: 5),
                _OverlayBtn(
                  icon: Icons.delete_rounded,
                  color: AppColors.danger,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OverlayBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }
}
