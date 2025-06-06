import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ReporteAccidenteScreen extends StatefulWidget {
  const ReporteAccidenteScreen({super.key});

  @override
  State<ReporteAccidenteScreen> createState() => _ReporteAccidenteScreenState();
}

class _ReporteAccidenteScreenState extends State<ReporteAccidenteScreen> {
  final String apiUrl = '${Config.baseUrl}/accidentes';
  final Map<String, TextEditingController> controllers = {
    'nombre': TextEditingController(),
    'apellido': TextEditingController(),
    'numero_documento': TextEditingController(),
    'genero': TextEditingController(),
    'seguro_medico': TextEditingController(),
    'reporte_accidente': TextEditingController(),
    'fecha_reporte': TextEditingController(),
    'ubicacion': TextEditingController(),
    'EPS': TextEditingController(),
    'estado': TextEditingController(),
  };

  String? selectedAmbulanciaId;
  String? selectedAmbulanciaPlaca;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadAmbulanciaFromLocalStorage();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _loadAmbulanciaFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final id = prefs.getInt('ambulancia_id');
      selectedAmbulanciaId = id?.toString();
      selectedAmbulanciaPlaca = prefs.getString('ambulancia_placa');
    });
  }

  Future<void> createReporte() async {
    for (var entry in controllers.entries) {
      if (entry.value.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "⚠️ El campo '${_labelForField(entry.key)}' es obligatorio."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (selectedAmbulanciaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Debes tener asignada una ambulancia."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mapeo para backend
    final generoMap = {
      "Hombre": "MASCULINO",
      "Mujer": "FEMENINO",
      "Otro": "OTRO"
    };

    final estadoMap = {
      "Estable": "LEVE",
      "Crítico": "CRITICO",
      "Observación": "MODERADO",
    };

    final Map<String, dynamic> data = {};
    for (var key in controllers.keys) {
      var value = controllers[key]!.text;

      if (key == 'genero') value = generoMap[value] ?? value;
      if (key == 'estado') value = estadoMap[value] ?? value;
      if (key == 'fecha_reporte' && selectedDate != null) {
        value = selectedDate!.toIso8601String();
      }

      data[key] = value;
    }

    data['ambulancia_id'] = int.tryParse(selectedAmbulanciaId!);

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Reporte agregado exitosamente"),
          backgroundColor: Colors.green,
        ),
      );
      for (var controller in controllers.values) {
        controller.clear();
      }
      setState(() {
        selectedDate = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Error al crear reporte: ${response.body}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('reporteAccidenteScreen'),
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
              'Reporte de Accidente',
              style: TextStyle(fontSize: 22, color: Colors.white),
            ),
            const Spacer(),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.house),
              tooltip: 'Inicio',
              color: Colors.white,
              onPressed: () => Navigator.pushNamed(context, '/'),
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
              tooltip: 'Cerrar sesión',
              color: Colors.white,
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token');
                await prefs.remove('ambulancia_id');
                await prefs.remove('ambulancia_placa');
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
        toolbarHeight: 90,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF89F7FE), Color(0xFFA3E4D7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(30),
          width: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Formulario Accidente",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                ...controllers.entries.map((entry) {
                  switch (entry.key) {
                    case 'genero':
                      return _buildDropdownField(
                          entry.value, 'Género', ['Hombre', 'Mujer', 'Otro']);
                    case 'seguro_medico':
                      return _buildDropdownField(entry.value, 'Seguro Médico', [
                        'SURA',
                        'Coomeva',
                        'MedPlus',
                        'AXA Colpatria',
                        'Aliansalud',
                        'Colmédica',
                        'Seguros Bolívar',
                        'Mapfre',
                        'Liberty',
                        'Sanitas'
                      ]);
                    case 'EPS':
                      return _buildDropdownField(entry.value, 'EPS', [
                        'Nueva EPS',
                        'Sanitas',
                        'SURA',
                        'Coomeva',
                        'Salud Total',
                        'Cafesalud',
                        'Compensar',
                        'Famisanar',
                        'Medimás',
                        'Aliansalud'
                      ]);
                    case 'estado':
                      return _buildDropdownField(entry.value, 'Estado',
                          ['Estable', 'Crítico', 'Observación']);
                    case 'fecha_reporte':
                      return _buildDateField(entry.value, 'Fecha del Reporte');
                    default:
                      return _buildTextField(
                          entry.value, _labelForField(entry.key));
                  }
                }),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: TextFormField(
                    key: ValueKey(selectedAmbulanciaPlaca),
                    initialValue:
                        selectedAmbulanciaPlaca ?? 'Ambulancia no asignada',
                    style: const TextStyle(color: Colors.black),
                    decoration: _inputDecoration("Ambulancia asignada"),
                    enabled: false,
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: createReporte,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 30),
                    backgroundColor: const Color(0xFF66A6FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Guardar Reporte",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.black),
        decoration: _inputDecoration(label),
      ),
    );
  }

  Widget _buildDropdownField(
      TextEditingController controller, String label, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        style: const TextStyle(color: Colors.black),
        decoration: _inputDecoration(label),
        dropdownColor: Colors.white,
        iconEnabledColor: Colors.black,
        items: options.map((value) {
          return DropdownMenuItem(
            value: value,
            child: Text(value, style: const TextStyle(color: Colors.black)),
          );
        }).toList(),
        onChanged: (value) => setState(() => controller.text = value ?? ''),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          if (picked != null) {
            setState(() {
              selectedDate = picked;
              controller.text = picked.toIso8601String().split("T").first;
            });
          }
        },
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.black),
            decoration: _inputDecoration(label),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle:
          const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  String _labelForField(String key) {
    switch (key) {
      case 'nombre':
        return 'Nombre';
      case 'apellido':
        return 'Apellido';
      case 'numero_documento':
        return 'Número de Documento';
      case 'genero':
        return 'Género';
      case 'seguro_medico':
        return 'Seguro Médico';
      case 'reporte_accidente':
        return 'Reporte Accidente';
      case 'fecha_reporte':
        return 'Fecha del Reporte';
      case 'ubicacion':
        return 'Ubicación';
      case 'EPS':
        return 'EPS';
      case 'estado':
        return 'Estado';
      default:
        return key;
    }
  }
}
