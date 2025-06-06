import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart'; // Importa tu configuración con la baseUrl

class ApiService {
  // baseUrl debe ser estática para poder usar en métodos estáticos
  static final String baseUrl = Config.baseUrl;

  /// Registro de usuarios
  static Future<http.Response> registerUser({
    required String nombre,
    required String email,
    required String password,
    required String personalRol,
  }) async {
    final url = Uri.parse("${baseUrl}/signin");

    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'contrasena': password,
        'personal_rol': personalRol,
      }),
    );
  }

  /// Inicio de sesión (modificado para guardar ambulancia asignada)
  static Future<Map<String, dynamic>> loginUser({
    required String nombre,
    required String contrasena,
  }) async {
    final url = Uri.parse("${baseUrl}/login");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre': nombre, 'contrasena': contrasena}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data["token"];
      final rol = data["rol"];
      final userId = data["id"];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('rol', rol);
      await prefs.setInt('user_id', userId);
      await prefs.setString('nombre_usuario', data["nombre_usuario"] ?? "");

      // 🔍 Buscar ambulancia asignada
      final asignacionResponse = await http.get(
        Uri.parse("${baseUrl}/asignacion"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (asignacionResponse.statusCode == 200) {
        final List asignaciones = jsonDecode(asignacionResponse.body);

        final asignacion = asignaciones.cast<Map<String, dynamic>>().firstWhere(
              (a) => a['personal_id'] == userId,
              orElse: () => {},
            );

        if (asignacion.isNotEmpty && asignacion['ambulancia'] != null) {
          final ambulancia = asignacion['ambulancia'];
          await prefs.setString('ambulancia_placa', ambulancia['placa'] ?? '');
          await prefs.setInt('ambulancia_id', ambulancia['id']);
        } else {
          await prefs.remove('ambulancia_placa');
          await prefs.remove('ambulancia_id');
        }
      }

      return {
        'success': true,
        'token': token,
        'rol': rol,
        'user_id': userId,
      };
    } else {
      return {
        'success': false,
        'mensaje': 'Usuario o contraseña incorrectos',
      };
    }
  }

  /// Obtener datos del usuario desde el backend
  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      return {'success': false, 'mensaje': 'Token no encontrado.'};
    }

    final url = Uri.parse("${baseUrl}/user_data");

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data.containsKey('id')) {
        await prefs.setInt('user_id', data['id']);
      }

      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'mensaje': 'No se pudo obtener los datos del usuario.',
      };
    }
  }

  /// Obtener solo el ID del usuario actual
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('user_id')) {
      return prefs.getInt('user_id');
    }

    final result = await getUserData();
    if (result['success']) {
      final data = result['data'];
      return data['id'];
    }

    return null;
  }
}
