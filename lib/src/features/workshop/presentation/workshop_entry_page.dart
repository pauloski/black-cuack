import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:blackcuack_studio/src/core/theme/blackcuack_widgets.dart';
import 'package:blackcuack_studio/src/core/utils/group_utils.dart';
import 'package:blackcuack_studio/src/features/workshop/data/workshop_service.dart';

/// Rol de acceso: el docente CREA una sala (código + QR para compartir); el
/// estudiante INGRESA el código que le dieron.
enum WorkshopMode { student, teacher }

/// Ingreso al TALLER/SALA (DEMO, dummy y local). No valida contra backend: solo
/// etiqueta los proyectos con el código de sala. Tras entrar → `/profiles`.
class WorkshopEntryPage extends StatefulWidget {
  const WorkshopEntryPage({super.key});

  @override
  State<WorkshopEntryPage> createState() => _WorkshopEntryPageState();
}

class _WorkshopEntryPageState extends State<WorkshopEntryPage> {
  final _codeCtrl = TextEditingController();
  WorkshopMode _mode = WorkshopMode.student;
  String _teacherCode = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is WorkshopMode) _mode = arg;
    if (_mode == WorkshopMode.teacher && _teacherCode.isEmpty) {
      _teacherCode = GroupUtils.generateGroupCode();
    }
  }

  Future<void> _enter(String code) async {
    final c = code.trim();
    if (c.isEmpty) return;
    await WorkshopService.setActive(c);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/profiles');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white54),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _mode == WorkshopMode.teacher
                  ? _teacherBody()
                  : _studentBody(),
            ),
          ),
        ),
      ),
    );
  }

  // ── Estudiante: ingresa el código ──────────────────────────────────────────
  Widget _studentBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.meeting_room_rounded,
            color: AppColors.primary, size: 56),
        const SizedBox(height: 16),
        const Text('Ingresa a tu sala',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Lexend',
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Escribe el código que te dio tu profe.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 28),
        TextField(
          controller: _codeCtrl,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          maxLength: 5,
          style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Lexend',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 8),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'CÓDIGO',
            hintStyle: const TextStyle(
                color: Colors.white24, letterSpacing: 4, fontSize: 20),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: _enter,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _codeCtrl.text.trim().isEmpty
                ? null
                : () => _enter(_codeCtrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: Colors.white10,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('ENTRAR',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lexend',
                    fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // ── Docente: crea la sala (código + QR) ────────────────────────────────────
  Widget _teacherBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Tu sala de clase',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Lexend',
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text(
          'Comparte este código o el QR con tus estudiantes para que entren a la sala.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: QrImageView(
              data: _teacherCode, size: 170, backgroundColor: Colors.white),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _teacherCode));
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Código copiado', style: TextStyle(fontFamily: 'Lexend')),
              backgroundColor: AppColors.secondary,
              duration: Duration(seconds: 2),
            ));
          },
          child: Text(
            _teacherCode,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Lexend',
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 8),
          ),
        ),
        TextButton.icon(
          onPressed: () =>
              setState(() => _teacherCode = GroupUtils.generateGroupCode()),
          icon: const Icon(Icons.refresh_rounded,
              color: Colors.white38, size: 16),
          label: const Text('Generar otro',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _enter(_teacherCode),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('ENTRAR A LA SALA',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Lexend',
                    fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
