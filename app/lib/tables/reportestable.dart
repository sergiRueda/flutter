import 'dart:convert';
import '../config.dart'; // Ajusta la ruta según tu estructura
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReportesViajesTable extends StatefulWidget {
  const ReportesViajesTable({super.key});

  @override
  State<ReportesViajesTable> createState() => _ReportesViajesTableState();
}

class _ReportesViajesTableState extends State<ReportesViajesTable> {
  final String baseUrl = '${Config.baseUrl}'; // URL base sin errores

  List reportes = [];
  List personas = [];
  List hospitales = [];

  // Aquí puedes seguir con initState, fetch y demás métodos...

  late ScrollController _horizController;
  late ScrollController _vertController;

  @override
  void initState() {
    super.initState();
    _horizController = ScrollController();
    _vertController = ScrollController();
    fetchData();
  }

  @override
  void dispose() {
    _horizController.dispose();
    _vertController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    final reportesRes = await http.get(Uri.parse('$baseUrl/reportes'));
    final personasRes = await http.get(Uri.parse('$baseUrl/accidentes'));
    final hospitalesRes = await http.get(Uri.parse('$baseUrl/hospitales'));

    if (reportesRes.statusCode == 200 &&
        personasRes.statusCode == 200 &&
        hospitalesRes.statusCode == 200) {
      setState(() {
        reportes = json.decode(reportesRes.body);
        personas = json.decode(personasRes.body);
        hospitales = json.decode(hospitalesRes.body);
      });
    } else {
      debugPrint('Error al cargar datos');
    }
  }

  Future<void> crearReporte(Map<String, dynamic> data) async {
    await http.post(
      Uri.parse('$baseUrl/reportes'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    fetchData();
  }

  Future<void> editarReporte(int id, Map<String, dynamic> data) async {
    await http.put(
      Uri.parse('$baseUrl/reportes/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    fetchData();
  }

  Future<void> eliminarReporte(int id) async {
    await http.delete(Uri.parse('$baseUrl/reportes/$id'));
    fetchData();
  }

  void mostrarFormulario({Map? reporte}) {
    int? personaId = reporte?['accidente_id'];
    String? puntoF = reporte?['punto_f'];

    final tiempoCtrl = TextEditingController(text: reporte?['tiempo'] ?? '');
    final ubicacionCtrl = TextEditingController();

    if (personaId != null) {
      final p =
          personas.firstWhere((p) => p['id'] == personaId, orElse: () => null);
      if (p != null) ubicacionCtrl.text = p['ubicacion'] ?? '';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(reporte == null ? 'Nuevo Reporte' : 'Editar Reporte'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: personaId,
                decoration: const InputDecoration(labelText: 'Persona'),
                items: personas.map<DropdownMenuItem<int>>((p) {
                  return DropdownMenuItem(
                    value: p['id'],
                    child: Text('${p['nombre']} ${p['apellido']}'),
                  );
                }).toList(),
                onChanged: (v) {
                  personaId = v;
                  final p = personas.firstWhere((p) => p['id'] == v,
                      orElse: () => null);
                  if (p != null) ubicacionCtrl.text = p['ubicacion'] ?? '';
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tiempoCtrl,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Tiempo'),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    tiempoCtrl.text =
                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ubicacionCtrl,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Ubicación'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: puntoF,
                decoration: const InputDecoration(labelText: 'Punto Fin'),
                items: hospitales.map<DropdownMenuItem<String>>((h) {
                  return DropdownMenuItem(
                    value: h['nombre'],
                    child: Text(h['nombre']),
                  );
                }).toList(),
                onChanged: (v) => puntoF = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
            onPressed: () {
              final data = {
                'accidente_id': personaId,
                'tiempo': tiempoCtrl.text,
                'ubicacion': ubicacionCtrl.text,
                'punto_f': puntoF,
              };
              if (reporte == null) {
                crearReporte(data);
              } else {
                editarReporte(reporte['id'], data);
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget buildDataTable(double minWidth) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFF1976D2)),
      headingTextStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      dataRowHeight: 56,
      columnSpacing: 24,
      columns: const [
        DataColumn(label: Text('Persona')),
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Tiempo')),
        DataColumn(label: Text('Ubicación')),
        DataColumn(label: Text('Punto F')),
        DataColumn(label: Text('Acciones')),
      ],
      rows: reportes.map<DataRow>((r) {
        final p = personas.firstWhere((p) => p['id'] == r['accidente_id'],
            orElse: () =>
                {'nombre': 'Desconocido', 'apellido': '', 'ubicacion': ''});
        return DataRow(cells: [
          DataCell(Text('${p['nombre']} ${p['apellido']}',
              style: const TextStyle(color: Colors.black))),
          DataCell(Text(r['id'].toString(),
              style: const TextStyle(color: Colors.black))),
          DataCell(Text(r['tiempo'] ?? '',
              style: const TextStyle(color: Colors.black))),
          DataCell(Text(p['ubicacion'] ?? '',
              style: const TextStyle(color: Colors.black))),
          DataCell(Text(r['punto_f'] ?? '',
              style: const TextStyle(color: Colors.black))),
          DataCell(Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => mostrarFormulario(reporte: r)),
              IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => eliminarReporte(r['id'])),
            ],
          )),
        ]);
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 6 columnas * 150px ancho mínimo
    const minWidth = 6 * 150.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Reportes de Viajes'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => mostrarFormulario(),
                child: const Text('Nuevo Reporte',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Scrollbar(
                  controller: _horizController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizController,
                    scrollDirection: Axis.horizontal,
                    child: Scrollbar(
                      controller: _vertController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        controller: _vertController,
                        scrollDirection: Axis.vertical,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: minWidth),
                          child: buildDataTable(minWidth),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
