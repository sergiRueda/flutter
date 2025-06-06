import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class RegisterPublicScreen extends StatefulWidget {
  const RegisterPublicScreen({super.key});

  @override
  State<RegisterPublicScreen> createState() => _RegisterPublicScreenState();
}

class _RegisterPublicScreenState extends State<RegisterPublicScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final Map<String, String> rolesMap = {
    "Administrador": "ADMINISTRADOR",
    "Conductor": "CONDUCTOR",
    "Enfermero": "ENFERMERO",
    "Paramédico": "PARAMEDICO",
  };
  String selectedReadableRole = "Conductor";

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('rol');
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> _registrarUsuario() async {
    final nombre = nombreController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (nombre.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son obligatorios')),
      );
      return;
    }

    final response = await ApiService.registerUser(
      nombre: nombre,
      email: email,
      password: password,
      personalRol: rolesMap[selectedReadableRole]!,
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario registrado exitosamente')),
      );
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/login');
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC2E9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF86929F),
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
              'Registro Público',
              style: TextStyle(fontSize: 22, color: Colors.white),
            ),
            const Spacer(),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
              tooltip: 'Cerrar sesión',
              color: Colors.white,
              onPressed: _logout,
            ),
          ],
        ),
        toolbarHeight: 90,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 500,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFF0F5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Registro',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1089D3),
                    shadows: [
                      Shadow(
                        color: Colors.black12,
                        offset: Offset(0, 3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildInput("Nombre", nombreController),
                const SizedBox(height: 15),
                _buildInput("Email", emailController),
                const SizedBox(height: 15),
                _buildInput("Contraseña", passwordController, obscureText: true),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedReadableRole,
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    labelStyle: const TextStyle(color: Colors.black87),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color.fromARGB(255, 117, 232, 240),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  items: rolesMap.keys.map((String visible) {
                    return DropdownMenuItem<String>(
                      value: visible,
                      child: Text(visible),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedReadableRole = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _registrarUsuario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A11CB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shadowColor: Colors.black45,
                    elevation: 8,
                  ),
                  child: const Text("Registrar"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController controller,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 16, color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF1089D3), width: 2),
        ),
      ),
    );
  }
}
