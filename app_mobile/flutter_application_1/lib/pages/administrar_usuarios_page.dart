// lib/pages/administrar_usuarios_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AdministrarUsuariosPage extends StatefulWidget {
  @override
  _AdministrarUsuariosPageState createState() =>
      _AdministrarUsuariosPageState();
}

class _AdministrarUsuariosPageState extends State<AdministrarUsuariosPage> {
  List usuarios = [];

  @override
  void initState() {
    super.initState();
    fetchUsuarios();
  }

  // Método para obtener el token y hacer la solicitud al endpoint
  Future<void> fetchUsuarios() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token'); // Obtén el token guardado

    if (token != null) {
      final response = await http.get(
        Uri.parse(
            'http://debianwebapi:8080/api/residente'), // Reemplaza con tu endpoint
        headers: {
          'Authorization': 'Bearer $token', // Añade el token en los headers
        },
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        setState(() {
          usuarios = jsonData['tb_residente']; // Asigna los datos obtenidos
        });
      } else {
        // Manejo del error
        print('Error al cargar los datos');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Administrar Usuarios'),
      ),
      body: usuarios.isEmpty
          ? Center(
              child:
                  CircularProgressIndicator()) // Muestra un indicador de carga mientras los datos se obtienen
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const <DataColumn>[
                  DataColumn(label: Text('Documento')),
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Correo')),
                  DataColumn(label: Text('Torre')),
                  DataColumn(label: Text('Apartamento')),
                  DataColumn(label: Text('Celular')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: usuarios
                    .map((usuario) => DataRow(cells: [
                          DataCell(Text(usuario['identificacion'] ?? '')),
                          DataCell(Text(usuario['nombres_usuario'] ?? '')),
                          DataCell(Text(usuario['correo'] ?? '')),
                          DataCell(Text(usuario['torre'] ?? '')),
                          DataCell(Text(usuario['apartamento'] ?? '')),
                          DataCell(Text(usuario['celular'] ?? '')),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.yellow),
                                  onPressed: () {
                                    // Lógica para editar el usuario
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    // Lógica para eliminar el usuario
                                  },
                                ),
                              ],
                            ),
                          ),
                        ]))
                    .toList(),
              ),
            ),
    );
  }
}
