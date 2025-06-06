import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/tables/hospitalesTables.dart';
import 'package:app/tables/personalTable.dart';
import 'package:app/tables/ambulanciatable.dart';
import 'package:app/tables/asignacionambulancia.dart';
import 'package:app/tables/accidentetable.dart';
import 'package:app/tables/reportestable.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String? selectedSection;
  String? userRole;

  final List<Map<String, dynamic>> sections = [
    {
      'title': 'Gestión de Personal',
      'id': 'personal',
      'icon': FontAwesomeIcons.userNurse
    },
    {
      'title': 'Gestión de Ambulancias',
      'id': 'ambulancias',
      'icon': FontAwesomeIcons.truckMedical
    },
    {
      'title': 'Gestión de Accidente',
      'id': 'FormularioAccidente',
      'icon': FontAwesomeIcons.carBurst
    },
    {
      'title': 'Gestión de Hospitales',
      'id': 'hospital',
      'icon': FontAwesomeIcons.hospital
    },
    {
      'title': 'Reporte de Viaje',
      'id': 'ReporteViaje',
      'icon': FontAwesomeIcons.fileMedical
    },
    {
      'title': 'Asignación Ambulancia',
      'id': 'Asignacionambulancia',
      'icon': FontAwesomeIcons.syringe
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final rol = prefs.getString('rol');
    setState(() {
      userRole = rol;
    });
    print("ROL GUARDADO: $rol");

    if (rol == null || rol.toLowerCase() != 'administrador') {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Acceso denegado. Solo administradores')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('rol');
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 4,
        toolbarHeight: 90,
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
              'Administrador - Sistema de Ambulancias',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white),
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
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: sections.map((section) {
              return GestureDetector(
                onTap: () {
                  setState(() => selectedSection = section['id']);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 170,
                  height: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedSection == section['id']
                        ? const Color(0xFF1976D2)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        section['icon'],
                        size: 30,
                        color: selectedSection == section['id']
                            ? Colors.white
                            : const Color(0xFF1976D2),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        section['title'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedSection == section['id']
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 25),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: selectedSection == null
                  ? const Center(
                      child: Text(
                        '🧭 Selecciona una sección del sistema',
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : SectionContent(sectionId: selectedSection!),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionContent extends StatelessWidget {
  final String sectionId;

  const SectionContent({super.key, required this.sectionId});

  @override
  Widget build(BuildContext context) {
    switch (sectionId) {
      case 'personal':
        return PersonalTable();
      case 'ambulancias':
        return AmbulanciasTable();
      case 'FormularioAccidente':
        return const ReportesAccidenteTable();
      case 'hospital':
        return HospitalesTable();
      case 'Asignacionambulancia':
        return AsignacionAmbulanciaTable();
      case 'ReporteViaje':
        return const ReportesViajesTable();
      default:
        return const Center(child: Text('Sección no encontrada'));
    }
  }
}
