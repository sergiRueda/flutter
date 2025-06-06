import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart'; // Importa tu configuración con la baseUrl

class PersonalTable extends StatefulWidget {
  const PersonalTable({super.key});

  @override
  _PersonalTableState createState() => _PersonalTableState();
}

class _PersonalTableState extends State<PersonalTable> {
  final String apiUrl = '${Config.baseUrl}/personal';

  List<dynamic> personal = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchPersonal();
  }

  Future<void> fetchPersonal() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          personal = data;
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener los datos del personal');
      }
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> deletePersonal(int id) async {
    final response = await http.delete(Uri.parse('$apiUrl/$id'));
    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personal eliminado')),
      );
      fetchPersonal();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar')),
      );
    }
  }

  void showEditDialog(Map<String, dynamic> person) {
    TextEditingController nameController =
        TextEditingController(text: person["nombre"]);
    TextEditingController emailController =
        TextEditingController(text: person["email"]);

    String rawRole = person["rol"] ?? "Sin rol";
    String selectedRole =
        rawRole.contains("RolesEnum.") ? rawRole.split(".")[1] : rawRole;

    List<String> roles = [
      "ADMINISTRADOR",
      "CONDUCTOR",
      "ENFERMERO",
      "PARAMÉDICO"
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Personal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              DropdownButton<String>(
                value:
                    roles.contains(selectedRole) ? selectedRole : roles.first,
                items: roles.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                updatePersonal(person["id"], nameController.text,
                    emailController.text, selectedRole);
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
      },
    );
  }

  Future<void> updatePersonal(
      int id, String name, String email, String role) async {
    final response = await http.put(
      Uri.parse('$apiUrl/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"nombre": name, "email": email, "rol": role}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personal actualizado')),
      );
      fetchPersonal();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar')),
      );
    }
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
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: const Text("Agregar Personal",
                style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 20),
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.all(const Color(0xFF1976D2)),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        columns: const [
                          DataColumn(label: Text("ID")),
                          DataColumn(label: Text("Nombre")),
                          DataColumn(label: Text("Email")),
                          DataColumn(label: Text("Rol")),
                          DataColumn(label: Text("Acciones")),
                        ],
                        rows: personal.map((person) {
                          return DataRow(
                            cells: [
                              DataCell(Text(
                                person["id"].toString(),
                                style: const TextStyle(color: Colors.black),
                              )),
                              DataCell(Text(
                                person["nombre"],
                                style: const TextStyle(color: Colors.black),
                              )),
                              DataCell(Text(
                                person["email"],
                                style: const TextStyle(color: Colors.black),
                              )),
                              DataCell(Text(
                                (person["rol"] ?? "Sin rol")
                                    .toString()
                                    .split('.')
                                    .last,
                                style: const TextStyle(color: Colors.black),
                              )),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => showEditDialog(person),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        deletePersonal(person["id"]),
                                  ),
                                ],
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
      ],
    );
  }
}
