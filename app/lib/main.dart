import 'package:flutter/material.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/reporte.dart';
import 'screens/administrador.dart';
import 'screens/accidente.dart';
import 'screens/mapa_ruta_screen.dart';
import 'screens/home.dart';
import 'screens/eps.dart';
import 'screens/registerusuario.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: '/home', // Cambiado a login para probar inicio sesión
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/registerusuario': (context) => const RegisterPublicScreen(),
        '/login': (context) => const LoginScreen(),
        '/reporte': (context) => ReporteViajeScreen(),
        '/accidente': (context) => ReporteAccidenteScreen(),
        '/administrador': (context) => const AdminHomeScreen(),
        '/conductor': (context) => const MapaRutaScreen(),
        '/home': (context) => const HomeScreen(),
        '/eps': (context) => const EpsAliadasScreen(),
      },
    );
  }
}
