import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class ReportesAccidenteTable extends StatefulWidget {
  const ReportesAccidenteTable({super.key});

  @override
  State<ReportesAccidenteTable> createState() => _ReportesAccidenteTableState();
}

class _ReportesAccidenteTableState extends State<ReportesAccidenteTable> {
  final String apiUrl = '${Config.baseUrl}/accidentes';
  final String ambulanciasUrl = '${Config.baseUrl}/ambulancias';

  List<Map<String, dynamic>> reportes = [];
  List<Map<String, dynamic>> ambulancias = [];
  bool isLoading = true;

  late ScrollController _horizontalController;
  late ScrollController _verticalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = ScrollController();
    _verticalController = ScrollController();
    fetchData();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchReportes(),
      _fetchAmbulancias(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _fetchReportes() async {
    try {
      final resp = await http.get(Uri.parse(apiUrl));
      if (resp.statusCode == 200) {
        reportes = List<Map<String, dynamic>>.from(json.decode(resp.body));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchAmbulancias() async {
    try {
      final resp = await http.get(Uri.parse(ambulanciasUrl));
      if (resp.statusCode == 200) {
        ambulancias = List<Map<String, dynamic>>.from(json.decode(resp.body));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> createReporte(Map<String, dynamic> datos) async {
    final resp = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(datos),
    );
    if (resp.statusCode == 201) fetchData();
  }

  Future<void> updateReporte(int id, Map<String, dynamic> datos) async {
    final resp = await http.put(
      Uri.parse('$apiUrl/$id'),
      headers: {"Content-Type": "application/json"},
      body: json.encode(datos),
    );
    if (resp.statusCode == 200) fetchData();
  }

  Future<void> deleteReporte(int id) async {
    final resp = await http.delete(Uri.parse('$apiUrl/$id'));
    if (resp.statusCode == 200 || resp.statusCode == 204) fetchData();
  }

  void showForm({Map<String, dynamic>? reporte}) {
    final controllers = <String, TextEditingController>{};
    final fields = [
      'nombre',
      'apellido',
      'numero_documento',
      'genero',
      'seguro_medico',
      'reporte_accidente',
      'fecha_reporte',
      'ubicacion',
      'EPS',
      'estado',
    ];

    String generoEnumToLabel(String value) {
      switch (value.toUpperCase()) {
        case 'M':
        case 'MASCULINO':
          return 'Hombre';
        case 'F':
        case 'FEMENINO':
          return 'Mujer';
        case 'OTRO':
          return 'Otro';
        default:
          return value;
      }
    }

    String estadoEnumToLabel(String value) {
      switch (value.toUpperCase()) {
        case 'LEVE':
          return 'Estable';
        case 'CRITICO':
          return 'Crítico';
        case 'MODERADO':
          return 'Bajo Observación';
        case 'GRAVE':
          return 'Grave';
        default:
          return value;
      }
    }

    for (var key in fields) {
      String value = reporte != null ? reporte[key]?.toString() ?? '' : '';
      if (key == 'genero') value = generoEnumToLabel(value);
      if (key == 'estado') value = estadoEnumToLabel(value);
      controllers[key] = TextEditingController(text: value);
    }

    String? selectedAmbId = reporte?['ambulancia_id']?.toString();
    DateTime? selectedDate = reporte != null && reporte['fecha_reporte'] != null
        ? DateTime.tryParse(reporte['fecha_reporte'])
        : null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(reporte == null ? 'Crear Reporte' : 'Editar Reporte'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...fields.map((key) {
                if (key == 'fecha_reporte') {
                  return TextField(
                    controller: controllers[key],
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Fecha del Reporte'),
                    onTap: () async {
                      final pick = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pick != null) {
                        selectedDate = pick;
                        controllers[key]!.text = pick.toIso8601String().split('T').first;
                      }
                    },
                  );
                }
                if (key == 'genero') {
                  final opts = ['Hombre', 'Mujer', 'Otro'];
                  return DropdownButtonFormField<String>(
                    value: opts.contains(controllers[key]!.text) ? controllers[key]!.text : null,
                    decoration: const InputDecoration(labelText: 'Género'),
                    items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                    onChanged: (v) => controllers[key]!.text = v!,
                  );
                }
                if (key == 'estado') {
                  final opts = ['Estable', 'Crítico', 'Bajo Observación', 'Grave'];
                  return DropdownButtonFormField<String>(
                    value: opts.contains(controllers[key]!.text) ? controllers[key]!.text : null,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                    onChanged: (v) => controllers[key]!.text = v!,
                  );
                }
                if (key == 'seguro_medico') {
                  final opts = ['SURA', 'Coomeva', 'MedPlus', 'AXA Colpatria', 'Aliansalud'];
                  return DropdownButtonFormField<String>(
                    value: controllers[key]!.text.isEmpty ? null : controllers[key]!.text,
                    decoration: const InputDecoration(labelText: 'Seguro Médico'),
                    items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                    onChanged: (v) => controllers[key]!.text = v!,
                  );
                }
                if (key == 'EPS') {
                  final opts = ['Nueva EPS', 'Sanitas', 'SURA', 'Coomeva'];
                  return DropdownButtonFormField<String>(
                    value: controllers[key]!.text.isEmpty ? null : controllers[key]!.text,
                    decoration: const InputDecoration(labelText: 'EPS'),
                    items: opts.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                    onChanged: (v) => controllers[key]!.text = v!,
                  );
                }
                return TextField(
                  controller: controllers[key],
                  decoration: InputDecoration(labelText: key),
                );
              }),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedAmbId,
                decoration: const InputDecoration(labelText: 'Ambulancia'),
                items: ambulancias
                    .map((a) => DropdownMenuItem(
                          value: a['id'].toString(),
                          child: Text(a['placa']),
                        ))
                    .toList(),
                onChanged: (v) => selectedAmbId = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(reporte == null ? 'Crear' : 'Actualizar'),
            onPressed: () {
              final data = <String, dynamic>{};
              for (var key in fields) {
                data[key] = controllers[key]!.text;
              }

              final generoMap = {
                "Hombre": "MASCULINO",
                "Mujer": "FEMENINO",
                "Otro": "OTRO",
                "M": "MASCULINO",
                "F": "FEMENINO"
              };
              final estadoMap = {
                "Estable": "LEVE",
                "Crítico": "CRITICO",
                "Bajo Observación": "MODERADO",
                "Grave": "GRAVE",
                "critico": "CRITICO",
                "leve": "LEVE"
              };

              final rawGenero = controllers['genero']!.text;
              final rawEstado = controllers['estado']!.text;

              data['genero'] = generoMap[rawGenero] ?? rawGenero;
              data['estado'] = estadoMap[rawEstado] ?? rawEstado;

              data['fecha_reporte'] = selectedDate?.toIso8601String();
              data['ambulancia_id'] = int.tryParse(selectedAmbId ?? '');

              if (reporte == null) {
                createReporte(data);
              } else {
                updateReporte(reporte['id'], data);
              }

              Navigator.of(context).pop();
            },
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => showForm(),
            child: const Text('Agregar Reporte', style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 20),
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : Expanded(
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    child: Scrollbar(
                      controller: _horizontalController,
                      thumbVisibility: true,
                      notificationPredicate: (notif) => notif.depth == 1,
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingTextStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          dataTextStyle: const TextStyle(
                            color: Colors.black,
                          ),
                          columns: [
                            ...reportes.isNotEmpty
                                ? reportes.first.keys.map((key) => DataColumn(label: Text(key))).toList()
                                : [],
                            const DataColumn(label: Text('Acciones')),
                            const DataColumn(label: Text('Ambulancia')),
                          ],
                          rows: reportes.map((e) {
                            final amb = ambulancias.firstWhere(
                              (a) => a['id'] == e['ambulancia_id'],
                              orElse: () => {},
                            );
                            final placaAmbulancia = (amb.isNotEmpty && amb.containsKey('placa')) ? amb['placa'] : '—';
                            return DataRow(
                              cells: [
                                ...e.values.map((v) => DataCell(Text(v?.toString() ?? '—'))).toList(),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => showForm(reporte: e),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => deleteReporte(e['id']),
                                    ),
                                  ],
                                )),
                                DataCell(Text(placaAmbulancia)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
