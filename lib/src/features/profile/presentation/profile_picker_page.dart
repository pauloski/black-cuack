import 'dart:math';

import 'package:flutter/material.dart';

import 'package:blackcuack_studio/src/core/config/repositories.dart';
import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/profile/data/profile_service.dart';
import 'package:blackcuack_studio/src/features/profile/domain/profile_model.dart';
import 'package:blackcuack_studio/src/features/workshop/data/workshop_service.dart';

const _avatars = ['🦆', '🐱', '🐶', '🦊', '🐸', '🐼', '🐯', '🦉'];
// Roles del taller (HDU aula). "Otro" habilita un campo de texto libre.
const _roles = ['Animador', 'Cámara', 'Director', 'Otro'];
// "Dibujos" para la clave de imágenes (demo).
const _keyIcons = [
  '⭐', '🌙', '☀️', '🌈', '🍎', '🌵', '🚀', '🎈', '🐟', '🦋', '🌸', '⚽'
];

class ProfilePickerPage extends StatefulWidget {
  const ProfilePickerPage({super.key});

  @override
  State<ProfilePickerPage> createState() => _ProfilePickerPageState();
}

class _ProfilePickerPageState extends State<ProfilePickerPage> {
  List<Profile> _profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ProfileService.list();
    if (!mounted) return;
    setState(() {
      _profiles = list;
      _loading = false;
    });
  }

  Future<void> _enter(Profile p) async {
    await ProfileService.setActive(p.id);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  /// Borra un perfil (mantener presionado). Confirma primero.
  Future<void> _confirmDeleteProfile(Profile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('¿BORRAR PERFIL?',
            style: TextStyle(
                fontFamily: 'Lexend', color: AppColors.danger, fontSize: 15)),
        content: Text('Se quitará "${p.nickname}". Sus proyectos no se borran.',
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('BORRAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ProfileService.delete(p.id);
      _load();
    }
  }

  /// Reinicia TODOS los datos de prueba: perfiles, proyectos y la sala. Útil para
  /// empezar a evaluar desde cero.
  Future<void> _confirmResetAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('¿REINICIAR TODO?',
            style: TextStyle(
                fontFamily: 'Lexend', color: AppColors.danger, fontSize: 15)),
        content: const Text(
          'Borra TODOS los perfiles, proyectos y la sala de este dispositivo. '
          'No se puede deshacer. (Solo para empezar a evaluar desde cero.)',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('CANCELAR',
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('BORRAR TODO',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ProfileService.deleteAll();
    await projectRepository.clearAll();
    await WorkshopService.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  /// Al tocar un perfil: si tiene clave, se pide; si no (perfil antiguo), entra.
  void _onProfileTap(Profile p) {
    if (p.imageKey.length == 3) {
      _showKeyEntry(p);
    } else {
      // Perfil sin clave (p. ej. compañero creado rápido): la crea la primera
      // vez que entra, y desde ahí su perfil queda protegido.
      _setKeyThenEnter(p);
    }
  }

  /// Primera entrada de un perfil sin clave: crea sus 3 imágenes y entra.
  Future<void> _setKeyThenEnter(Profile p) async {
    final key = await _pickKey(title: '¡Crea tu clave, ${p.nickname}!');
    if (key == null) return; // canceló: no entra
    final updated = Profile(
      id: p.id,
      nickname: p.nickname,
      avatar: p.avatar,
      imageKey: key,
      role: p.role,
    );
    await ProfileService.save(updated);
    if (!mounted) return;
    await _enter(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('¿QUIÉN ANIMA?',
            style: TextStyle(
                fontFamily: 'Lexend', color: AppColors.primary, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded,
                color: Colors.white38, size: 20),
            tooltip: 'Reiniciar datos de prueba',
            onPressed: _confirmResetAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2))
          : Column(
              children: [
                const SizedBox(height: 8),
                if (activeWorkshopCode.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.meeting_room_rounded,
                            color: AppColors.primary, size: 14),
                        const SizedBox(width: 6),
                        Text('Sala $activeWorkshopCode',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontFamily: 'Lexend',
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                Text(
                  _profiles.isEmpty
                      ? 'Crea tu perfil para empezar'
                      : 'Toca tu perfil para entrar',
                  style: const TextStyle(
                      color: Colors.white54,
                      fontFamily: 'Lexend',
                      fontSize: 14),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          ..._profiles.map((p) => _profileTile(p)),
                          _createTile(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _profileTile(Profile p) {
    return SizedBox(
      width: 92,
      child: GestureDetector(
        onTap: () => _onProfileTap(p),
        onLongPress: () => _confirmDeleteProfile(p),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.surface,
              child: Text(p.avatar, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 8),
            Text(p.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white70, fontFamily: 'Lexend', fontSize: 13)),
            if (p.role.isNotEmpty)
              Text(p.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'Lexend',
                      fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _createTile() {
    return SizedBox(
      width: 92,
      child: GestureDetector(
        onTap: _showCreate,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.surface,
              child: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 8),
            const Text('Crear perfil',
                style: TextStyle(
                    color: Colors.white38, fontFamily: 'Lexend', fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Celda de un dibujo de la clave (con insignia de orden si está elegido) ──
  Widget _keyIconTile({
    required int index,
    required int order, // -1 si no está elegido
    required VoidCallback onTap,
  }) {
    final selected = order != -1;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.primary : Colors.white10,
                width: selected ? 2 : 1,
              ),
            ),
            // El dibujo SIEMPRE se ve; el número es una insignia encima.
            child: Text(_keyIcons[index], style: const TextStyle(fontSize: 24)),
          ),
          if (selected)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Text('${order + 1}',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Entrada con clave de imágenes ──────────────────────────────────────────
  void _showKeyEntry(Profile p) {
    final entered = <int>[];
    bool error = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.surface,
                child: Text(p.avatar, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(height: 8),
              Text(p.nickname,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Lexend',
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              if (p.role.isNotEmpty)
                Text(p.role,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontFamily: 'Lexend',
                        fontSize: 12)),
              const SizedBox(height: 10),
              Text(
                error
                    ? 'Esa no es tu clave. Intenta de nuevo.'
                    : 'Toca tus 3 dibujos en orden',
                style: TextStyle(
                    color: error ? AppColors.danger : Colors.white54,
                    fontFamily: 'Lexend',
                    fontSize: 13),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_keyIcons.length, (i) {
                  return _keyIconTile(
                    index: i,
                    order: entered.indexOf(i),
                    onTap: () {
                      setSheet(() {
                        error = false;
                        if (entered.contains(i)) {
                          entered.remove(i);
                        } else if (entered.length < 3) {
                          entered.add(i);
                        }
                      });
                      if (entered.length == 3) {
                        final ok = _listEq(entered, p.imageKey);
                        if (ok) {
                          Navigator.pop(ctx);
                          _enter(p);
                        } else {
                          setSheet(() {
                            error = true;
                            entered.clear();
                          });
                        }
                      }
                    },
                  );
                }),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _forgotKey(p);
                },
                child: const Text('¿Olvidaste tu clave?',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Recuperar clave: confirmación de adulto + elegir clave nueva ───────────
  Future<void> _forgotKey(Profile p) async {
    final ok = await _adultGate();
    if (!ok || !mounted) return;
    final newKey = await _pickKey(
      title: 'Elige una clave nueva para ${p.nickname}',
    );
    if (newKey == null || !mounted) return;
    // Mismo id → los proyectos del perfil se conservan.
    await ProfileService.save(Profile(
      id: p.id,
      nickname: p.nickname,
      avatar: p.avatar,
      imageKey: newKey,
      role: p.role,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Nueva clave de ${p.nickname}: ${newKey.map((i) => _keyIcons[i]).join(' ')}',
            style: const TextStyle(fontFamily: 'Lexend')),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 5),
      ),
    );
    _load();
  }

  /// Confirmación de adulto sencilla: una suma. Evita que un niño cambie la
  /// clave de otro sin ayuda.
  Future<bool> _adultGate() async {
    final a = 3 + Random().nextInt(6); // 3..8
    final b = 4 + Random().nextInt(6); // 4..9
    final ctrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('AYUDA DE UN ADULTO',
            style: TextStyle(
                fontFamily: 'Lexend', color: AppColors.primary, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Para cambiar la clave, resuelve:',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 10),
            Text('$a + $b = ?',
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Lexend',
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (v) =>
                  Navigator.pop(ctx, int.tryParse(v.trim()) == a + b),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('CANCELAR', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () =>
                Navigator.pop(ctx, int.tryParse(ctrl.text.trim()) == a + b),
            child: const Text('CONTINUAR',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (result == true) return true;
    if (result == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Respuesta incorrecta'),
        backgroundColor: AppColors.danger,
      ));
    }
    return false;
  }

  /// Hoja reutilizable para elegir 3 dibujos en orden. Devuelve los índices.
  Future<List<int>?> _pickKey({required String title}) {
    final key = <int>[];
    return showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontFamily: 'Lexend',
                      fontSize: 15)),
              const SizedBox(height: 6),
              Text('Toca 3 dibujos en orden · ${key.length}/3',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: List.generate(_keyIcons.length, (i) {
                  return _keyIconTile(
                    index: i,
                    order: key.indexOf(i),
                    onTap: () => setSheet(() {
                      if (key.contains(i)) {
                        key.remove(i);
                      } else if (key.length < 3) {
                        key.add(i);
                      }
                    }),
                  );
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: key.length == 3
                      ? () => Navigator.pop(ctx, List<int>.of(key))
                      : null,
                  child: const Text('LISTO',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _listEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // ── Crear perfil ────────────────────────────────────────────────────────────
  void _showCreate() {
    final nameCtrl = TextEditingController();
    final otherRoleCtrl = TextEditingController();
    String avatar = _avatars.first;
    String role = ''; // '' = sin rol; o uno de _roles; 'Otro' usa otherRoleCtrl
    final key = <int>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NUEVO PERFIL',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontFamily: 'Lexend',
                        fontSize: 16)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Apodo',
                    labelStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Avatar',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _avatars
                      .map((a) => GestureDetector(
                            onTap: () => setSheet(() => avatar = a),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: avatar == a
                                  ? AppColors.primary
                                  : AppColors.surface,
                              child:
                                  Text(a, style: const TextStyle(fontSize: 22)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text('Rol en el taller',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _roles.map((r) {
                    final sel = role == r;
                    return ChoiceChip(
                      label: Text(r),
                      selected: sel,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                          color: sel ? Colors.black : Colors.white70,
                          fontFamily: 'Lexend',
                          fontSize: 12),
                      backgroundColor: Colors.white10,
                      selectedColor: AppColors.primary,
                      onSelected: (_) => setSheet(() => role = sel ? '' : r),
                    );
                  }).toList(),
                ),
                if (role == 'Otro') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: otherRoleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: '¿Cuál rol?',
                      labelStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text('Clave de imágenes (elige 3 en orden) · ${key.length}/3',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: List.generate(_keyIcons.length, (i) {
                    return _keyIconTile(
                      index: i,
                      order: key.indexOf(i),
                      onTap: () => setSheet(() {
                        if (key.contains(i)) {
                          key.remove(i);
                        } else if (key.length < 3) {
                          key.add(i);
                        }
                      }),
                    );
                  }),
                ),
                if (key.length == 3) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Tu clave es: ${key.map((i) => _keyIcons[i]).join(' ')}  ¡Recuérdala!',
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Lexend',
                          fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty || key.length != 3) return;
                      final finalRole = role == 'Otro'
                          ? otherRoleCtrl.text.trim()
                          : role;
                      final p = Profile(
                        id: 'p_${DateTime.now().microsecondsSinceEpoch}',
                        nickname: name,
                        avatar: avatar,
                        imageKey: List<int>.of(key),
                        role: finalRole,
                      );
                      await ProfileService.save(p);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _load();
                    },
                    child: const Text('CREAR',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
