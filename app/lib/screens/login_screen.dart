import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController contrasenaController = TextEditingController();

  final String _claveDeVerificacion = "clave123"; // 🔑 Clave requerida

  Future<void> _login() async {
    final nombre = nombreController.text.trim();
    final contrasena = contrasenaController.text.trim();

    if (nombre.isEmpty || contrasena.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Por favor ingresa tu nombre y contraseña.")),
      );
      return;
    }

    final result = await ApiService.loginUser(
      nombre: nombre,
      contrasena: contrasena,
    );

    if (result['success']) {
      final rol = result['rol']?.toString().trim().toLowerCase();
      final token = result['token']?.toString();
      final rutasPorRol = {
        'administrador': '/administrador',
        'conductor': '/conductor',
        'enfermero': '/accidente',
        'paramédico': '/reporte',
      };

      final ruta = rutasPorRol[rol];

      if (ruta != null && token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('logueado', true);
        await prefs.setString('rol', rol ?? '');
        await prefs.setString('token', token);
        await prefs.setString('nombre_usuario', nombre);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión exitoso')),
        );

        await Future.delayed(
            const Duration(milliseconds: 500)); // pequeño delay para snackbar

        Navigator.pushNamedAndRemoveUntil(context, ruta, (_) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rol no reconocido o token inválido")),
        );
      }
    } else {
      final mensaje = result['mensaje'] ?? 'Error al iniciar sesión';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    }
  }

  Future<bool> _verificarClave(BuildContext context) async {
    final TextEditingController claveController = TextEditingController();

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Verificación de clave"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Ingresa la clave para acceder al registro:"),
                  const SizedBox(height: 10),
                  TextField(
                    controller: claveController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: "Clave",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final ingresada = claveController.text.trim();
                    if (ingresada == _claveDeVerificacion) {
                      Navigator.of(context).pop(true);
                    } else {
                      Navigator.of(context).pop(false);
                    }
                  },
                  child: const Text("Confirmar"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo_2.png',
              width: 170,
              height: 170,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text(
              'Iniciar Sesión',
              style: TextStyle(fontSize: 22, color: Colors.white),
            ),
            const Spacer(),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.house),
              tooltip: 'Inicio',
              color: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.userPlus),
              tooltip: 'Registrarse',
              color: Colors.white,
              onPressed: () async {
                final autorizado = await _verificarClave(context);
                if (autorizado) {
                  Navigator.pushNamed(context, '/register');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Clave incorrecta")),
                  );
                }
              },
            ),
          ],
        ),
        toolbarHeight: 90,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFFE1F5FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Iniciar Sesión", style: TextStyle(fontSize: 24)),
                _buildInput("Nombre", nombreController,
                    key: const Key('nombre')),
                const SizedBox(height: 12),
                _buildInput("Contraseña", contrasenaController,
                    obscureText: true, key: const Key('contrasena')),
                const SizedBox(height: 20),
                _buildGradientButton(),
                const SizedBox(height: 20),
                _buildRegisterButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController controller,
      {bool obscureText = false, Key? key}) {
    return TextField(
      key: key,
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      ),
    );
  }

  Widget _buildGradientButton() {
    return GestureDetector(
      key: const Key('loginButton'),
      onTap: _login,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFFB00020), Color(0xFFFF6F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          "🚑 Iniciar sesión",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/registerusuario');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF0288D1), Color(0xFF039BE5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          "👩‍⚕️ Registrarse personal",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
