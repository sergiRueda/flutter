import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart'; 
class ReporteViajeScreen extends StatefulWidget {
  const ReporteViajeScreen({super.key});

  @override
  _ReporteViajeScreenState createState() => _ReporteViajeScreenState();
}

class _ReporteViajeScreenState extends State<ReporteViajeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tiempoController = TextEditingController();
  final TextEditingController _puntoInicialController = TextEditingController();

  List<dynamic> accidentes = [];
  List<dynamic> hospitales = [];
  int? _accidenteIdSeleccionado;
  String? _puntoFinalSeleccionado;

  @override
  void initState() {
    super.initState();
    verificarSesion();
    fetchDatos();
  }

  Future<void> verificarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> fetchDatos() async {
  final accidentesRes =
    await http.get(Uri.parse('${Config.baseUrl}/accidentes'));
final hospitalesRes =
    await http.get(Uri.parse('${Config.baseUrl}/hospitales'));
    if (accidentesRes.statusCode == 200 && hospitalesRes.statusCode == 200) {
      setState(() {
        accidentes = json.decode(accidentesRes.body);
        hospitales = json.decode(hospitalesRes.body);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al cargar datos de API")),
      );
    }
  }

  Future<void> _seleccionarHora() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
      setState(() {
        _tiempoController.text = formattedTime;
      });
    }
  }

  Future<void> _registrarReporte() async {
    if (_formKey.currentState!.validate()) {
      final Map<String, dynamic> requestBody = {
        "tiempo": _tiempoController.text,
        "punto_i": _puntoInicialController.text,
        "punto_f": _puntoFinalSeleccionado,
        "accidente_id": _accidenteIdSeleccionado,
      };

      final response = await http.post(
      Uri.parse('${Config.baseUrl}/reportes'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reporte registrado con éxito")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al registrar el reporte")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: _buildFondo(),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: _buildCaja(),
            width: 400,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Reporte del Viaje",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTimePickerField(),
                  _buildDropdownAccidentes(),
                  _buildUbicacionField(),
                  _buildDropdownHospitales(),
                  const SizedBox(height: 20),
                  _buildBotonRegistrar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF86929F),
      title: Row(
        children: [
          Image.asset('assets/images/logo_2.png', width: 170, height: 170),
          const SizedBox(width: 10),
          const Text('Reporte del Viaje',
              style: TextStyle(fontSize: 22, color: Colors.white)),
          const Spacer(),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.arrowRightFromBracket),
            tooltip: 'Cerrar sesión',
            color: Colors.white,
            onPressed: cerrarSesion,
          ),
        ],
      ),
      toolbarHeight: 90,
    );
  }

  BoxDecoration _buildFondo() => const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF89F7FE), Color(0xFFA3E4D7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );

  BoxDecoration _buildCaja() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2),
        ],
      );

  Widget _buildTimePickerField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: _seleccionarHora,
        child: AbsorbPointer(
          child: TextFormField(
            controller: _tiempoController,
            decoration: _buildInputDecoration("Tiempo (HH:MM:SS)"),
            validator: (value) =>
                value!.isEmpty ? "Ingrese el tiempo del viaje" : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownAccidentes() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<int>(
        value: _accidenteIdSeleccionado,
        decoration: _buildInputDecoration("Accidente / Persona"),
        items: accidentes.map<DropdownMenuItem<int>>((p) {
          return DropdownMenuItem<int>(
            value: p['id'],
            child: Text('${p['nombre']} ${p['apellido']}'),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _accidenteIdSeleccionado = value;
            final persona = accidentes.firstWhere((p) => p['id'] == value,
                orElse: () => null);
            _puntoInicialController.text = persona?['ubicacion'] ?? '';
          });
        },
        validator: (value) => value == null ? "Seleccione una persona" : null,
      ),
    );
  }

  Widget _buildUbicacionField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: _puntoInicialController,
        readOnly: true,
        decoration: _buildInputDecoration("Punto Inicial (ubicación)"),
        validator: (value) =>
            value!.isEmpty ? "La ubicación es obligatoria" : null,
      ),
    );
  }

  Widget _buildDropdownHospitales() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: _puntoFinalSeleccionado,
        decoration: _buildInputDecoration("Punto Final (hospital)"),
        items: hospitales.map<DropdownMenuItem<String>>((h) {
          return DropdownMenuItem<String>(
            value: h['nombre'],
            child: Text(h['nombre']),
          );
        }).toList(),
        onChanged: (value) => setState(() => _puntoFinalSeleccionado = value),
        validator: (value) => value == null ? "Seleccione un hospital" : null,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFF4A90E2), width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF66A6FF), width: 2),
      ),
    );
  }

  Widget _buildBotonRegistrar() {
    return ElevatedButton(
      onPressed: _registrarReporte,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: const Color(0xFF66A6FF),
      ),
      child: const Text(
        "Registrar",
        style: TextStyle(
            fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
