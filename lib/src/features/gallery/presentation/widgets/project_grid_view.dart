import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:blackcuack_studio/src/core/config/repositories.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/profile/data/profile_service.dart'
    show activeProfileId;
import 'package:blackcuack_studio/src/features/gallery/domain/project_model.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/movie_player_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/camera_page.dart';

class ProjectGridView extends StatefulWidget {
  final double bottomPadding;
  const ProjectGridView({super.key, this.bottomPadding = 0});

  @override
  State<ProjectGridView> createState() => _ProjectGridViewState();
}

class _ProjectGridViewState extends State<ProjectGridView> {
  late Future<List<QuackProject>> _future;

  @override
  void initState() {
    super.initState();
    _future = projectRepository.loadProjects();
  }

  void _reload() {
    setState(() => _future = projectRepository.loadProjects());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuackProject>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppColors.secondary, strokeWidth: 2),
          );
        }
        // Un borrador con 0 cuadros no aparece; las versiones (parentId) tampoco.
        final proyectos = (snapshot.data ?? [])
            .where((p) =>
                p.photoPaths.isNotEmpty &&
                p.parentId == null &&
                p.ownerProfileId == activeProfileId)
            .toList();
        if (proyectos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_filter_outlined,
                    color: Colors.white12, size: 56),
                SizedBox(height: 14),
                Text('Sin proyectos todavía',
                    style: TextStyle(
                        color: Colors.white38,
                        fontFamily: 'Lexend',
                        fontSize: 15)),
                SizedBox(height: 6),
                Text('Crea tu primera animación',
                    style: TextStyle(
                        color: Colors.white24,
                        fontFamily: 'Lexend',
                        fontSize: 12)),
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
            final String? firstId =
                p.photoPaths.isNotEmpty ? p.photoPaths.first : null;
            return _ProjectCard(
              project: p,
              previewFrameId: firstId,
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MoviePlayerPage(project: p)),
              ),
              onEdit: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CameraPage(projectToLoad: p)),
                );
                _reload();
              },
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
            style: TextStyle(
                fontFamily: 'Lexend', color: AppColors.danger, fontSize: 16),
            textAlign: TextAlign.center),
        content: Text(
          "'${project.name}' será eliminado permanentemente.",
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white54, fontFamily: 'Lexend', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await projectRepository.deleteProject(project.id);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Proyecto eliminado'),
                    backgroundColor: AppColors.danger),
              );
              _reload();
            },
            child: const Text('ELIMINAR',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Project card with overlay action buttons ──────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final QuackProject project;
  final String? previewFrameId;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectCard({
    required this.project,
    required this.previewFrameId,
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
          Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    color: AppColors.surface,
                    child: _Thumbnail(frameId: previewFrameId),
                  ),
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

/// Miniatura del primer cuadro, leída como **bytes** del repo local
/// (`Image.memory`), para que persista tras recargar (sin depender de CORS).
class _Thumbnail extends StatelessWidget {
  final String? frameId;
  const _Thumbnail({required this.frameId});

  @override
  Widget build(BuildContext context) {
    final id = frameId;
    if (id == null) return _placeholder();
    return FutureBuilder<Uint8List?>(
      future: projectRepository.loadFrameBytes(id),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) return _placeholder();
        return Image.memory(bytes, fit: BoxFit.cover,
            gaplessPlayback: true);
      },
    );
  }

  Widget _placeholder() => const Center(
        child: Icon(Icons.movie_filter_rounded,
            color: Colors.white12, size: 36),
      );
}

class _OverlayBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OverlayBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }
}
