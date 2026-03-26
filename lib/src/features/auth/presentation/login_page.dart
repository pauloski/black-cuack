import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:blackcuack_studio/src/features/auth/data/auth_service.dart';
import 'package:blackcuack_studio/src/features/gallery/presentation/home_page.dart'; 

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
  bool _isLoginMode = true; // <--- Esta es la clave del cambio

  void _handleAuth() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Por favor, completa los campos.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    // Usamos _isLoginMode para decidir qué función llamar
    final user = _isLoginMode 
        ? await _authService.signIn(email, password)
        : await _authService.signUp(email, password);

    if (user != null) {
      if (!_isLoginMode) {
        // Si se acaba de registrar
        await _authService.signOut(); 
        _showSnackBar("¡Cuenta creada! Verifica tu email antes de entrar.");
        setState(() {
          _isLoginMode = true; // Lo devolvemos al login automáticamente
          _passwordController.clear();
        });
      } else {
        // Si es login normal
        await user.reload();
        if (FirebaseAuth.instance.currentUser!.emailVerified) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        } else {
          await _authService.signOut();
          _showSnackBar("Debes verificar tu correo primero.", isError: true);
        }
      }
    } else {
      _showSnackBar("Error: Revisa tus datos.", isError: true);
    }
    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : Colors.greenAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('BLACKCUACK', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 42)),
              const SizedBox(height: 10),
              // Título dinámico
              Text(_isLoginMode ? "Inicia sesión" : "Crea tu cuenta de Artista", 
                style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 40),
              
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
              ),
              const SizedBox(height: 30),

              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                // Botón Principal que cambia de nombre
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _handleAuth,
                    style: ElevatedButton.styleFrom(backgroundColor: _isLoginMode ? colors.primary : colors.secondary),
                    child: Text(_isLoginMode ? 'ENTRAR' : 'CREAR CUENTA', 
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                if (_isLoginMode)
                  TextButton(
                    onPressed: () => _authService.sendPasswordResetEmail(_emailController.text), 
                    child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: Colors.grey))
                  ),
                
                const Divider(height: 40),

                // El "Interruptor" entre Login y Registro
                TextButton(
                  onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                  child: Text(
                    _isLoginMode ? '¿No tienes cuenta? REGÍSTRATE AQUÍ' : '¿Ya tienes cuenta? INICIA SESIÓN',
                    style: TextStyle(color: _isLoginMode ? colors.secondary : colors.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}