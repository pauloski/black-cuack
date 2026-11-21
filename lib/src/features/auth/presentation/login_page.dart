import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:blackcuack_studio/src/features/auth/data/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _showEmail = false; // formulario de correo oculto por defecto

  // ── Entrada principal: sin email (local-first) ────────────────────────────
  void _enterAsGuest() {
    // El intento anónimo corre en segundo plano con timeout; la entrada NO lo
    // espera (así funciona sin conexión y no se cuelga).
    unawaited(_tryAnonymous());
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _tryAnonymous() async {
    try {
      await _authService
          .signInAnonymously()
          .timeout(const Duration(seconds: 4));
    } on TimeoutException {
      debugPrint('Inicio anónimo: timeout (seguimos sin conexión).');
    } catch (e) {
      debugPrint('Inicio anónimo falló: $e');
    }
  }

  // ── Entrada con correo (docentes) ─────────────────────────────────────────
  void _handleAuth() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Completa todos los campos", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      await (_isLoginMode
          ? _authService.signIn(email, password)
          : _authService.signUp(email, password));
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar("Error inesperado. Entra como invitado.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Escribe tu email primero", isError: true);
      return;
    }
    try {
      await _authService.sendPasswordResetEmail(email);
      _showSnackBar("¡Correo enviado! Revisa tu bandeja 📬");
    } catch (e) {
      _showSnackBar("No encontramos ese email", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Lexend')),
        backgroundColor:
            isError ? const Color(0xFFFF4D4D) : const Color(0xFFBC87FE),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Center(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/images/logo-login.svg',
                        height: 154),
                    const SizedBox(height: 44),

                    // ── Botón principal: entrar sin email ──────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _enterAsGuest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB800),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'ENTRAR AL TALLER',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lexend',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Enlace discreto para docentes ──────────────────────
                    TextButton(
                      onPressed: () =>
                          setState(() => _showEmail = !_showEmail),
                      child: Text(
                        _showEmail
                            ? 'Ocultar'
                            : 'Soy docente · entrar con correo',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ),

                    if (_showEmail) ..._buildEmailForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmailForm() {
    return [
      const SizedBox(height: 6),
      _buildTextField(_emailController, 'Email', Icons.email_outlined),
      const SizedBox(height: 16),
      _buildTextField(_passwordController, 'Password', Icons.lock_outline,
          isObscure: true),
      if (_isLoginMode)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _handleForgotPassword,
            child: const Text("¿Olvidaste tu contraseña?",
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontFamily: 'Lexend')),
          ),
        ),
      const SizedBox(height: 8),
      if (_isLoading)
        const CircularProgressIndicator(color: Color(0xFFBC87FE))
      else ...[
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _handleAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBC87FE),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: Text(
              _isLoginMode ? 'ENTRAR CON CORREO' : 'REGISTRARME',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lexend'),
            ),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
          child: Text(
            _isLoginMode ? '¿No tienes cuenta? REGÍSTRATE' : 'YA TENGO CUENTA',
            style: const TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ),
      ],
    ];
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isObscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      style: const TextStyle(color: Colors.white, fontFamily: 'Lexend'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: Icon(icon,
            color: const Color(0xFFBC87FE).withValues(alpha: 0.7), size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFFFB800)),
        ),
      ),
    );
  }
}
