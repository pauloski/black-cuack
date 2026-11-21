import 'package:flutter/material.dart';

import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/features/profile/data/profile_service.dart';
import 'package:blackcuack_studio/src/features/profile/domain/profile_model.dart';

const _avatars = ['🦆', '🐱', '🐶', '🦊', '🐸', '🐼', '🐯', '🦉'];
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
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2))
          : GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(24),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                ..._profiles.map((p) => _profileTile(p)),
                _createTile(),
              ],
            ),
    );
  }

  Widget _profileTile(Profile p) {
    return GestureDetector(
      onTap: () => _enter(p),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.surface,
            child: Text(p.avatar, style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(height: 8),
          Text(p.nickname,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white70, fontFamily: 'Lexend', fontSize: 13)),
        ],
      ),
    );
  }

  Widget _createTile() {
    return GestureDetector(
      onTap: _showCreate,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }

  void _showCreate() {
    final nameCtrl = TextEditingController();
    String avatar = _avatars.first;
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
                Text('Clave de imágenes (elige 3 en orden) · ${key.length}/3',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_keyIcons.length, (i) {
                    final order = key.indexOf(i);
                    final sel = order != -1;
                    return GestureDetector(
                      onTap: () => setSheet(() {
                        if (sel) {
                          key.remove(i);
                        } else if (key.length < 3) {
                          key.add(i);
                        }
                      }),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sel ? '${order + 1}' : _keyIcons[i],
                          style: TextStyle(
                              fontSize: sel ? 18 : 22,
                              color: sel ? Colors.black : null,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                ),
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
                      final p = Profile(
                        id: 'p_${DateTime.now().microsecondsSinceEpoch}',
                        nickname: name,
                        avatar: avatar,
                        imageKey: List<int>.of(key),
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
