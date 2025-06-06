import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart'; // Importa tu configuración con la baseUrl

class AmbulanciasTable extends StatefulWidget {
  const AmbulanciasTable({super.key});

  @override
  _AmbulanciasTableState createState() => _AmbulanciasTableState();
}

class _AmbulanciasTableState extends State<AmbulanciasTable> {
  final String apiUrl = '${Config.baseUrl}/ambulancias';

  List ambulancias = [];
  List<Map<String, dynamic>> hospitales = [];
  bool isLoading = true;

  final List<String> categorias = ['BASICA', 'MEDICALIZADA', 'UTIM'];

  late ScrollController _horizController;
  late ScrollController _vertController;

  @override
  void initState() {
    super.initState();
    _horizController = ScrollController();
    _vertController = ScrollController();
    fetchAmbulancias();
    fetchHospitales();
  }

  @override
  void dispose() {
    _horizController.dispose();
    _vertController.dispose();
    super.dispose();
  }

  Future<void> fetchAmbulancias() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          ambulancias = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Error al cargar ambulancias");
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchHospitales() async {
    try {
      final response =
         await http.get(Uri.parse('${Config.baseUrl}/hospitales'));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          hospitales = data.cast<Map<String, dynamic>>();
        });
      } else {
        throw Exception('Error al cargar hospitales');
      }
    } catch (e) {
      print('Error al obtener hospitales: $e');
    }
  }

  Future<void> createAmbulancia(Map data) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      fetchAmbulancias();
    }
  }

  Future<void> updateAmbulancia(int id, Map data) async {
    final response = await http.put(
      Uri.parse('$apiUrl/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      fetchAmbulancias();
    }
  }

  Future<void> deleteAmbulancia(int id) async {
    final response = await http.delete(Uri.parse('$apiUrl/$id'));
    if (response.statusCode == 204) {
      fetchAmbulancias();
    }
  }

  void showForm({Map? ambulancia}) {
    final TextEditingController placaCtrl =
        TextEditingController(text: ambulancia?['placa'] ?? '');

    String categoriaSeleccionada = ambulancia != null
        ? categorias.firstWhere(
            (cat) =>
                cat.toUpperCase() ==
                ambulancia['categoria_ambulancia'].toString().toUpperCase(),
            orElse: () => categorias[0],
          )
        : categorias[0];

    int? hospitalIdSeleccionado = ambulancia?['hospital_id'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              ambulancia == null ? 'Agregar Ambulancia' : 'Editar Ambulancia'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: placaCtrl,
                  decoration: const InputDecoration(labelText: 'Placa'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: categoriaSeleccionada,
                  items: categorias.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        categoriaSeleccionada = value;
                      });
                    }
                  },
                  decoration:
                      const InputDecoration(labelText: 'Categoría Ambulancia'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: hospitalIdSeleccionado,
                  items: hospitales.map<DropdownMenuItem<int>>((h) {
                    final id = h['id'] is int
                        ? h['id'] as int
                        : int.tryParse(h['id'].toString()) ?? 0;
                    final nombre = h['nombre']?.toString() ?? 'Desconocido';
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(nombre),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      hospitalIdSeleccionado = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Hospital'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () {
                final data = {
                  "placa": placaCtrl.text,
                  "categoria_ambulancia": categoriaSeleccionada,
                  "hospital_id": hospitalIdSeleccionado ?? 0,
                };
                if (ambulancia == null) {
                  createAmbulancia(data);
                } else {
                  updateAmbulancia(ambulancia['id'], data);
                }
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colCount =
        ambulancias.isNotEmpty ? ambulancias.first.keys.length + 1 : 1;
    final minWidth = colCount * 150.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Ambulancias'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showForm(),
        backgroundColor: const Color(0xFF00C853),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
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
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Placa',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Categoría',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Hospital',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                              DataColumn(
                                  label: Text('Acciones',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold))),
                            ],
                            rows: ambulancias.map((amb) {
                              return DataRow(cells: [
                                DataCell(Text(amb['id'].toString(),
                                    style:
                                        const TextStyle(color: Colors.black))),
                                DataCell(Text(amb['placa'] ?? '',
                                    style:
                                        const TextStyle(color: Colors.black))),
                                DataCell(Text(amb['categoria_ambulancia'] ?? '',
                                    style:
                                        const TextStyle(color: Colors.black))),
                                DataCell(Text(
                                    amb['hospital']?['nombre'] ?? 'Desconocido',
                                    style:
                                        const TextStyle(color: Colors.black))),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          showForm(ambulancia: amb),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          deleteAmbulancia(amb['id']),
                                    ),
                                  ],
                                )),
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
    );
  }
}
