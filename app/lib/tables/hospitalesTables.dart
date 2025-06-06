import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart'; // Importa tu configuración con la baseUrl
class HospitalesTable extends StatefulWidget {
  const HospitalesTable({super.key});

  @override
  _HospitalesTableState createState() => _HospitalesTableState();
}

class _HospitalesTableState extends State<HospitalesTable> {
 final String apiUrl = '${Config.baseUrl}/hospitales';

  List<dynamic> hospitals = [];
  bool isLoading = true;
  String? errorMessage;

  late ScrollController _horizController;
  late ScrollController _vertController;

  @override
  void initState() {
    super.initState();
    _horizController = ScrollController();
    _vertController = ScrollController();
    fetchHospitals();
  }

  @override
  void dispose() {
    _horizController.dispose();
    _vertController.dispose();
    super.dispose();
  }

  Future<void> fetchHospitals() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        hospitals = json.decode(response.body);
        errorMessage = null;
      } else {
        throw Exception('Error al obtener hospitales');
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteHospital(int id) async {
    final response = await http.delete(Uri.parse('$apiUrl/$id'));
    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hospital eliminado')),
      );
      fetchHospitals();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar hospital')),
      );
    }
  }

  void showEditDialog({Map<String, dynamic>? hospital}) {
    final nameController =
        TextEditingController(text: hospital?['nombre'] ?? '');
    final addressController =
        TextEditingController(text: hospital?['direccion'] ?? '');
    final capacityController = TextEditingController(
        text: hospital?['capacidad_atencion']?.toString() ?? '');
    String selectedCategory = hospital?['categoria'] ?? 'General';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title:
                Text(hospital == null ? 'Agregar Hospital' : 'Editar Hospital'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                  ),
                  TextField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacidad'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      'General',
                      'Especializado',
                      'Clinica',
                      'Emergencias'
                    ].map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (hospital == null) {
                    addHospital(
                      nameController.text,
                      addressController.text,
                      capacityController.text,
                      selectedCategory,
                    );
                  } else {
                    updateHospital(
                      hospital['id'],
                      nameController.text,
                      addressController.text,
                      capacityController.text,
                      selectedCategory,
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> addHospital(
      String name, String address, String capacity, String category) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': name,
        'direccion': address,
        'capacidad_atencion': int.tryParse(capacity) ?? 0,
        'categoria': category,
      }),
    );
    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hospital agregado')),
      );
      fetchHospitals();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al agregar hospital')),
      );
    }
  }

  Future<void> updateHospital(int id, String name, String address,
      String capacity, String category) async {
    final response = await http.put(
      Uri.parse('$apiUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': name,
        'direccion': address,
        'capacidad_atencion': int.tryParse(capacity) ?? 0,
        'categoria': category,
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hospital actualizado')),
      );
      fetchHospitals();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar hospital')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ancho mínimo = columnas * 150
    final colCount = hospitals.isNotEmpty ? hospitals.first.keys.length + 1 : 1;
    final minWidth = colCount * 150.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Gestionar Hospitales'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(errorMessage!,
                      style: const TextStyle(color: Colors.red)))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C853),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed: () => showEditDialog(),
                          child: const Text('Agregar Hospital',
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
                                  offset: const Offset(0, 4))
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
                                    constraints:
                                        BoxConstraints(minWidth: minWidth),
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                          const Color(0xFF1976D2)),
                                      headingTextStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                      dataRowHeight: 56,
                                      columnSpacing: 24,
                                      columns: const [
                                        DataColumn(
                                            label: Text('ID',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Nombre',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Dirección',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Capacidad',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Categoría',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Acciones',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                      ],
                                      rows: hospitals.map((hospital) {
                                        return DataRow(cells: [
                                          DataCell(Text(
                                              hospital['id'].toString(),
                                              style: const TextStyle(
                                                  color: Colors.black))),
                                          DataCell(Text(hospital['nombre'],
                                              style: const TextStyle(
                                                  color: Colors.black))),
                                          DataCell(Text(hospital['direccion'],
                                              style: const TextStyle(
                                                  color: Colors.black))),
                                          DataCell(Text(
                                              hospital['capacidad_atencion']
                                                  .toString(),
                                              style: const TextStyle(
                                                  color: Colors.black))),
                                          DataCell(Text(hospital['categoria'],
                                              style: const TextStyle(
                                                  color: Colors.black))),
                                          DataCell(Row(children: [
                                            IconButton(
                                                icon: const Icon(Icons.edit,
                                                    color: Colors.blue),
                                                onPressed: () => showEditDialog(
                                                    hospital: hospital)),
                                            IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () => deleteHospital(
                                                    hospital['id'])),
                                          ])),
                                        ]);
                                      }).toList(),
                                    ),
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
