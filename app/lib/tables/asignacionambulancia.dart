import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart'; // Importa tu configuración con la baseUrl

class AsignacionAmbulanciaTable extends StatefulWidget {
  const AsignacionAmbulanciaTable({super.key});

  @override
  _AsignacionAmbulanciaScreenState createState() =>
      _AsignacionAmbulanciaScreenState();
}

class _AsignacionAmbulanciaScreenState
    extends State<AsignacionAmbulanciaTable> {
  List asignaciones = [];
  List ambulancias = [];
  List personal = [];

  final String baseUrl = Config.baseUrl;

  late ScrollController _horizController;
  late ScrollController _vertController;

  @override
  void initState() {
    super.initState();
    _horizController = ScrollController();
    _vertController = ScrollController();
    fetchAllData();
  }

  @override
  void dispose() {
    _horizController.dispose();
    _vertController.dispose();
    super.dispose();
  }

  Future<void> fetchAllData() async {
    try {
      final asignacionRes = await http.get(Uri.parse('$baseUrl/asignacion'));
      final ambulanciaRes = await http.get(Uri.parse('$baseUrl/ambulancias'));
      final personalRes = await http.get(Uri.parse('$baseUrl/personal'));

      if (asignacionRes.statusCode == 200 &&
          ambulanciaRes.statusCode == 200 &&
          personalRes.statusCode == 200) {
        setState(() {
          asignaciones = json.decode(asignacionRes.body);
          ambulancias = json.decode(ambulanciaRes.body);
          personal = json.decode(personalRes.body);
        });
      } else {
        _mostrarErrorSnackBar('⚠️ Error al cargar los datos');
      }
    } catch (e) {
      _mostrarErrorSnackBar('⚠️ Error de conexión con el servidor');
      debugPrint('Error al obtener los datos: $e');
    }
  }

  Future<void> crearAsignacion(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/asignacion'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        fetchAllData();
        _mostrarExitoSnackBar('✅ Asignación creada correctamente');
      } else {
        _procesarErrorBackend(response, 'crear');
      }
    } catch (e) {
      _mostrarErrorSnackBar('⚠️ Error de conexión con el servidor');
      debugPrint('Error al crear asignación: $e');
    }
  }

  Future<void> editarAsignacion(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/asignacion/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        fetchAllData();
        _mostrarExitoSnackBar('✅ Asignación actualizada correctamente');
      } else {
        _procesarErrorBackend(response, 'editar');
      }
    } catch (e) {
      _mostrarErrorSnackBar('⚠️ Error de conexión con el servidor');
      debugPrint('Error al editar asignación: $e');
    }
  }

  Future<void> eliminarAsignacion(int id) async {
    await http.delete(Uri.parse('$baseUrl/asignacion/$id'));
    fetchAllData();
  }

  void _procesarErrorBackend(http.Response response, String operacion) {
    final errorData = json.decode(response.body);
    String mensajeError = errorData['mensaje'] ?? 'Error desconocido';

    if (mensajeError.contains('conductor asignado')) {
      mensajeError = 'No se puede asignar más de un conductor a una misma ambulancia';
    } else if (mensajeError.contains('enfermero asignado')) {
      mensajeError = 'No se puede asignar más de un enfermero a una misma ambulancia';
    } else if (mensajeError.contains('paramedico asignado')) {
      mensajeError = 'No se puede asignar más de un paramédico a una misma ambulancia';
    } else if (mensajeError.contains('ya está asignado')) {
      if (mensajeError.contains('enfermero')) {
        mensajeError = 'Un enfermero no puede estar asignado a más de una ambulancia';
      } else if (mensajeError.contains('paramedico')) {
        mensajeError = 'Un paramédico no puede estar asignado a más de una ambulancia';
      } else {
        mensajeError = 'No se puede asignar una persona a más de una ambulancia';
      }
    } else if (mensajeError.contains('No se puede asignar un administrador')) {
      mensajeError = 'No se permite asignar personal con rol de administrador';
    }

    _mostrarErrorSnackBar('⚠️ $mensajeError');
  }

  void _mostrarExitoSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarErrorSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void mostrarFormulario({Map? asignacion}) {
    final personalCtrl = TextEditingController(
        text: asignacion != null ? asignacion['personal_id'].toString() : '');
    final ambulanciaCtrl = TextEditingController(
        text: asignacion != null ? asignacion['ambulancia_id'].toString() : '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          asignacion == null ? 'Crear Asignación' : 'Editar Asignación',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: asignacion != null ? asignacion['personal_id'] : null,
              decoration: const InputDecoration(labelText: 'Personal'),
              items: personal
                  .where((p) => p['rol'] != 'ADMINISTRADOR')
                  .map<DropdownMenuItem<int>>((p) {
                final rolNombre = p['rol'] ?? 'Desconocido';
                return DropdownMenuItem<int>(
                  value: p['id'],
                  child: Text('${p['nombre']} - $rolNombre'),
                );
              }).toList(),
              onChanged: (v) => personalCtrl.text = v.toString(),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: asignacion != null ? asignacion['ambulancia_id'] : null,
              decoration: const InputDecoration(labelText: 'Ambulancia'),
              items: ambulancias.map<DropdownMenuItem<int>>((a) {
                return DropdownMenuItem<int>(
                  value: a['id'],
                  child: Text(a['placa']),
                );
              }).toList(),
              onChanged: (v) => ambulanciaCtrl.text = v.toString(),
            ),
          ],
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
                'personal_id': int.parse(personalCtrl.text),
                'ambulancia_id': int.parse(ambulanciaCtrl.text),
              };
              if (asignacion == null) {
                crearAsignacion(data);
              } else {
                editarAsignacion(asignacion['id'], data);
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colCount =
        asignaciones.isNotEmpty ? asignaciones.first.keys.length + 1 : 1;
    final minWidth = colCount * 150.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Asignación de Ambulancias'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                ),
                onPressed: () => mostrarFormulario(),
                child: const Text('Nueva Asignación',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
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
                        child: DataTable(
                          headingRowColor:
                              WidgetStateProperty.all(const Color(0xFF1976D2)),
                          headingTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          dataRowHeight: 56,
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Personal')),
                            DataColumn(label: Text('Ambulancia')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: asignaciones
                              .map((asig) {
                                final persona = personal.firstWhere(
                                  (p) => p['id'] == asig['personal_id'],
                                  orElse: () => {
                                    'nombre': 'Desconocido',
                                    'rol': 'Desconocido',
                                  },
                                );
                                final rolNombre = persona['rol'] ?? 'Desconocido';
                                if (rolNombre == 'ADMINISTRADOR') return null;

                                final placa = ambulancias.firstWhere(
                                  (a) => a['id'] == asig['ambulancia_id'],
                                  orElse: () => {'placa': 'Desconocida'},
                                )['placa'];

                                return DataRow(cells: [
                                  DataCell(Text('${asig['id']}')),
                                  DataCell(Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(persona['nombre'] ?? ''),
                                      Text('Rol: $rolNombre',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700])),
                                    ],
                                  )),
                                  DataCell(Text(placa)),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () =>
                                            mostrarFormulario(asignacion: asig),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            eliminarAsignacion(asig['id']),
                                      ),
                                    ],
                                  )),
                                ]);
                              })
                              .whereType<DataRow>()
                              .toList(),
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
