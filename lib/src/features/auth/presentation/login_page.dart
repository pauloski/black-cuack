import 'package:flutter/material.dart';
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

  // ✅ BOTÓN DE INVITADO INDESTRUCTIBLE (EL SALTO DE VALLA)
  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    try {
      // 1. Intentamos el login oficial de Firebase
      await _authService.signInAnonymously();

      // 2. Saltamos a la Home pase lo que pase
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // 3. Si hay error de red o Firebase, forzamos la entrada igual
      debugPrint("Bypass activado por error: $e");
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAuth() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("¡Faltan datos, Artista! 🦆", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final user = _isLoginMode
          ? await _authService.signIn(email, password)
          : await _authService.signUp(email, password);

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showSnackBar("Revisa tus datos o usa el modo Invitado", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error de acceso. Prueba como Invitado.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Lexend')),
        backgroundColor: isError
            ? const Color(0xFFFF4D4D)
            : const Color(0xFFBC87FE),
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
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.blur_on, size: 80, color: Color(0xFFC1FFFE)),
              const Text(
                'BLACKCUACK',
                style: TextStyle(
                  fontFamily: 'LuckiestGuy',
                  fontSize: 40,
                  color: Color(0xFFC1FFFE),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),

              _buildTextField(_emailController, 'Email', Icons.email_outlined),
              const SizedBox(height: 20),
              _buildTextField(
                _passwordController,
                'Password',
                Icons.lock_outline,
                isObscure: true,
              ),

              const SizedBox(height: 30),

              if (_isLoading)
                const CircularProgressIndicator(color: Color(0xFFBC87FE))
              else ...[
                // BOTÓN PRINCIPAL
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _handleAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoginMode
                          ? const Color(0xFFC1FFFE)
                          : const Color(0xFFBC87FE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      _isLoginMode ? 'ENTRAR AL TALLER' : 'REGISTRARME',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'LuckiestGuy',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // ✅ BOTÓN DE SALVACIÓN
                TextButton(
                  onPressed: _handleGuestLogin,
                  child: const Text(
                    "ENTRAR COMO ARTISTA INVITADO",
                    style: TextStyle(
                      color: Color(0xFFBC87FE),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),

                const Divider(color: Colors.white10, height: 40),

                TextButton(
                  onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                  child: Text(
                    _isLoginMode
                        ? '¿No tienes cuenta? REGÍSTRATE'
                        : 'YA TENGO CUENTA',
                    style: const TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
        prefixIcon: Icon(
          icon,
          color: const Color(0xFFBC87FE).withOpacity(0.7),
          size: 20,
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFC1FFFE)),
        ),
      ),
    );
  }
}
