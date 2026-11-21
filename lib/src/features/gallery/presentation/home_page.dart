import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/core/widgets/ephemeral_banner.dart';
import 'package:blackcuack_studio/src/features/auth/data/group_service.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/camera_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/pages/group_details_page.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/widgets/project_grid_view.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const EphemeralStorageBanner(),
          Expanded(
            child: Stack(
        fit: StackFit.expand,
        children: [
          // GIF: la escena está en el centro del frame (1280×720).
          // Alignment.center muestra la zona útil; el borde negro del extremo
          // derecho queda naturalmente fuera del viewport en pantallas normales.
          Image.asset(
            'assets/images/bkg-home.gif',
            fit: BoxFit.fitHeight,
            alignment: Alignment.center,
            width: double.infinity,
            height: double.infinity,
          ),
          // Gradiente: sólido en la izquierda, se desvanece antes del centro
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.background,
                  AppColors.background,
                  AppColors.background.withOpacity(0.7),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.38, 0.55, 0.72],
              ),
            ),
          ),
          // Contenido — izquierda, agrupado verticalmente
          SafeArea(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Logo SVG — ancho completo, altura acotada ──────────
                      SizedBox(
                        width: double.infinity,
                        height: 160,
                        child: SvgPicture.asset(
                          'assets/images/logo-login.svg',
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Tagline ────────────────────────────────────────────
                      const Text(
                        'Crea historias, cuadro a cuadro.\nAnima tus ideas en stop-motion.',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 14,
                          color: Colors.white60,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Features ───────────────────────────────────────────
                      const _FeatureRow(
                        icon: Icons.camera_alt_rounded,
                        iconColor: AppColors.primary,
                        title: 'Captura',
                        subtitle: 'Toma fotos cuadro a cuadro y da vida a tus ideas.',
                      ),
                      const SizedBox(height: 14),
                      const _FeatureRow(
                        icon: Icons.group_rounded,
                        iconColor: AppColors.secondary,
                        title: 'Colabora',
                        subtitle: 'Trabaja en equipo y comparte tus proyectos.',
                      ),
                      const SizedBox(height: 14),
                      const _FeatureRow(
                        icon: Icons.play_arrow_rounded,
                        iconColor: AppColors.green,
                        title: 'Comparte',
                        subtitle: 'Exporta tu animación y compártela donde quieras.',
                      ),

                      const SizedBox(height: 32),

                      // ── Botones CTA ────────────────────────────────────────
                      SizedBox(width: double.infinity, child: _NewProjectButton()),
                      const SizedBox(height: 20),
                      SizedBox(width: double.infinity, child: _MyProjectsButton()),

                      const SizedBox(height: 16),
                      // Ajustes — discreto
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/profile'),
                        icon: const Icon(Icons.settings_outlined,
                            size: 13, color: Colors.white24),
                        label: const Text('Ajustes',
                            style: TextStyle(
                                color: Colors.white24,
                                fontFamily: 'Lexend',
                                fontSize: 12)),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature row ───────────────────────────────────────────────────────────────
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.black, size: 26),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 11,
                  color: Colors.white54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── New project CTA (yellow) ──────────────────────────────────────────────────
class _NewProjectButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CameraPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.black, size: 22),
            SizedBox(width: 8),
            Text(
              'Nuevo proyecto',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Workspace button (secondary dark) ────────────────────────────────────────
class _MyProjectsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const _WorkspacePage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_rounded, color: Colors.white70, size: 20),
            SizedBox(width: 8),
            Text(
              'Mi espacio de trabajo',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Workspace page (tabs: Proyectos + Grupos) ─────────────────────────────────
class _WorkspacePage extends StatefulWidget {
  const _WorkspacePage();

  @override
  State<_WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<_WorkspacePage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'BLACK',
                style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
              ),
              TextSpan(
                text: 'Q',
                style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
              ),
              TextSpan(
                text: 'UACK',
                style: TextStyle(fontFamily: 'Lexend', fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: AppColors.secondary, size: 26),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildTabBar(),
            const SizedBox(height: 16),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _ProjectsTab(onProjectCreated: () => setState(() {})),
                  const _GroupsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _tabItem(0, Icons.movie_filter_rounded, 'MIS PROYECTOS'),
          _tabItem(1, Icons.hub_rounded, 'MIS GRUPOS'),
        ],
      ),
    );
  }

  Widget _tabItem(int index, IconData icon, String label) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.13) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppColors.primary.withValues(alpha: 0.35) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isActive ? AppColors.primary : Colors.white38),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: isActive ? AppColors.primary : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab: Proyectos ────────────────────────────────────────────────────────────
class _ProjectsTab extends StatelessWidget {
  final VoidCallback onProjectCreated;
  const _ProjectsTab({required this.onProjectCreated});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Grid scrolls with bottom padding so it clears the fixed button
        const ProjectGridView(bottomPadding: 110),

        // Fixed bottom button with fade gradient
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background.withOpacity(0), AppColors.background],
                stops: const [0.0, 0.45],
              ),
            ),
            child: GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CameraPage()),
                );
                onProjectCreated();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.black, size: 20),
                    SizedBox(width: 8),
                    Text('Nuevo proyecto',
                      style: TextStyle(fontFamily: 'Lexend',
                        fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab: Grupos ───────────────────────────────────────────────────────────────
class _GroupsTab extends StatefulWidget {
  const _GroupsTab();

  @override
  State<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<_GroupsTab> {
  final _groupService = GroupService();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _groupService.getMyGroupsStream(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return _buildEmptyState();
            }
            final docs = snap.data!.docs;
            final owned = docs.where((d) => d['ownerId'] == _uid).toList();
            final joined = docs.where((d) => d['ownerId'] != _uid).toList();
            return ListView(
              padding: const EdgeInsets.only(bottom: 110),
              children: [
                if (owned.isNotEmpty) ...[
                  _sectionLabel('MIS GRUPOS'),
                  ...owned.map((d) => _GroupCard(doc: d)),
                  const SizedBox(height: 8),
                ],
                if (joined.isNotEmpty) ...[
                  if (owned.isNotEmpty) _sectionLabel('ME UNÍ'),
                  ...joined.map((d) => _GroupCard(doc: d)),
                ],
              ],
            );
          },
        ),
        // Fixed bottom bar
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _buildBottomBar(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.hub_outlined, color: Colors.white12, size: 56),
          SizedBox(height: 16),
          Text('Sin grupos todavía',
            style: TextStyle(color: Colors.white38, fontFamily: 'Lexend', fontSize: 15)),
          SizedBox(height: 6),
          Text('Crea un grupo o únete con un código',
            style: TextStyle(color: Colors.white24, fontFamily: 'Lexend', fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background.withOpacity(0), AppColors.background],
          stops: const [0.0, 0.45],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _handleCreate,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.black, size: 18),
                    SizedBox(width: 6),
                    Text('Crear grupo',
                      style: TextStyle(color: Colors.black, fontFamily: 'Lexend',
                        fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _handleJoin,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link_rounded, color: Colors.white54, size: 18),
                    SizedBox(width: 6),
                    Text('Unirse',
                      style: TextStyle(color: Colors.white60, fontFamily: 'Lexend',
                        fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 6),
    child: Text(
      label,
      style: const TextStyle(
        fontFamily: 'Lexend', fontWeight: FontWeight.bold,
        color: Colors.white24, fontSize: 10, letterSpacing: 1.5,
      ),
    ),
  );

  Future<void> _handleCreate() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('NOMBRE DEL GRUPO',
          style: TextStyle(fontFamily: 'Lexend', color: AppColors.primary)),
        content: TextField(
          controller: ctrl, autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Ej: Taller de Lunes',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('CREAR', style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      final code = await _groupService.createGroup(name.trim());
      if (mounted && code != null) _showCodeDialog(code);
    }
  }

  Future<void> _handleJoin() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('UNIRSE A UN GRUPO',
          style: TextStyle(fontFamily: 'Lexend', color: AppColors.secondary)),
        content: TextField(
          controller: ctrl, autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 5,
          style: const TextStyle(color: Colors.white, letterSpacing: 4, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'CÓDIGO',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true, fillColor: Colors.black26, counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () async {
              if (ctrl.text.length == 5) {
                final ok = await _groupService.joinGroup(ctrl.text);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    backgroundColor: ok ? AppColors.secondary : AppColors.danger,
                    content: Text(ok ? '¡Te uniste al grupo!' : 'Código no encontrado'),
                  ));
                }
              }
            },
            child: const Text('UNIRME', style: TextStyle(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }

  void _showCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.primary),
        ),
        title: const Text('¡GRUPO LISTO!',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Lexend', color: AppColors.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Dicta este código a tus amigos:',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            Text(code,
              style: const TextStyle(fontSize: 40, fontFamily: 'Lexend', color: Colors.white, letterSpacing: 8)),
          ],
        ),
        actions: [
          Center(child: QuackButton(text: 'ENTENDIDO', onPressed: () => Navigator.pop(context))),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ── Group card ────────────────────────────────────────────────────────────────
class _GroupCard extends StatelessWidget {
  final DocumentSnapshot doc;
  const _GroupCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final name = (doc['name'] ?? 'Sin nombre') as String;
    final code = (doc['code'] ?? '') as String;
    final isOwner = doc['ownerId'] == FirebaseAuth.instance.currentUser?.uid;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GroupDetailsPage(groupName: name, groupCode: code)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.hub_rounded,
                    color: isOwner ? AppColors.primary : AppColors.secondary,
                    size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                        style: const TextStyle(color: Colors.white,
                          fontFamily: 'Lexend', fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('Código: $code',
                        style: const TextStyle(color: Colors.white30,
                          fontFamily: 'Lexend', fontSize: 11)),
                    ],
                  ),
                ),
                if (isOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('admin',
                      style: TextStyle(color: AppColors.primary,
                        fontFamily: 'Lexend', fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 10),
                const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 22),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Colors.white10),
        ],
      ),
    );
  }
}


// ── (unused stub kept for route compatibility) ────────────────────────────────
class _ProjectsListPage extends StatelessWidget {
  const _ProjectsListPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'MIS PROYECTOS',
          style: TextStyle(fontFamily: 'Lexend', color: AppColors.primary, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 26),
            tooltip: 'Nuevo proyecto',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CameraPage()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: ProjectGridView(),
      ),
    );
  }
}
