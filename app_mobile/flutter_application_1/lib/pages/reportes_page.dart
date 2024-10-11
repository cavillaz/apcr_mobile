import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ReportesPage extends StatefulWidget {
  @override
  _ReportesPageState createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  List parqueaderos = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchParqueaderos();
  }

  // Método para obtener el token y hacer la solicitud al endpoint parqueadero
  Future<void> fetchParqueaderos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token'); // Obtén el token guardado

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse(
              'http://debianwebapi:8080/api/parqueadero'), // Reemplaza con tu endpoint
          headers: {
            'Authorization': 'Bearer $token', // Añade el token en los headers
          },
        );

        if (response.statusCode == 200) {
          var jsonData = json.decode(response.body);
          setState(() {
            parqueaderos = jsonData['parqueadero']
                .where((parqueadero) => parqueadero['estado'] == 'Ocupado')
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            hasError = true;
            isLoading = false;
          });
          print('Error en la respuesta del servidor: ${response.statusCode}');
        }
      } catch (e) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        print('Error al hacer la solicitud: $e');
      }
    } else {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      print('Token no disponible');
    }
  }

  // Método para abrir un diálogo modal y editar los campos
  void openEditDialog(Map<String, dynamic> parqueadero) {
    final TextEditingController vehiculoController =
        TextEditingController(text: parqueadero['tipo_vehiculo']);
    final TextEditingController estadoController =
        TextEditingController(text: parqueadero['estado']);
    final TextEditingController placaVehiculoController =
        TextEditingController(text: parqueadero['placa_vehiculo']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar Parqueadero'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: vehiculoController,
                decoration: InputDecoration(labelText: 'Vehículo'),
              ),
              TextFormField(
                controller: estadoController,
                decoration: InputDecoration(labelText: 'Estado'),
              ),
              TextFormField(
                controller: placaVehiculoController,
                decoration: InputDecoration(labelText: 'Placa Vehículo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Guardar'),
              onPressed: () {
                // Llamar a la función para actualizar los datos
                updateParqueadero(
                  parqueadero['id_parqueadero'],
                  parqueadero['identificacion'],
                  parqueadero['id_ubicacion'],
                  vehiculoController.text,
                  estadoController.text,
                  placaVehiculoController.text,
                );
                Navigator.of(context)
                    .pop(); // Cerrar el modal después de guardar
              },
            ),
          ],
        );
      },
    );
  }

  // Método para actualizar los datos del parqueadero
  Future<void> updateParqueadero(
    String idParqueadero,
    String identificacion,
    String idUbicacion,
    String vehiculo,
    String estado,
    String placaVehiculo,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token'); // Obtener el token de sesión

    if (token != null) {
      final response = await http.post(
        Uri.parse(
            'http://debianwebapi:8080/api/parqueadero'), // Endpoint de actualización
        headers: {
          'Authorization': 'Bearer $token', // Enviar el token
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_parqueadero': idParqueadero,
          'identificacion': identificacion,
          'id_ubicacion': idUbicacion,
          'tipo_vehiculo': vehiculo,
          'estado': estado,
          'placa_vehiculo': placaVehiculo,
        }),
      );

      if (response.statusCode == 200) {
        // Si la actualización es exitosa, recargar la lista de parqueaderos
        fetchParqueaderos();
      } else {
        // Mostrar error si no fue posible actualizar
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('No se pudo actualizar el parqueadero.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reporte de Parqueaderos'),
      ),
      body: isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // Muestra un indicador de carga mientras los datos se obtienen
          : hasError
              ? Center(
                  child: Text(
                      'Error al cargar los datos')) // Muestra mensaje de error si hay problema
              : parqueaderos.isEmpty
                  ? Center(child: Text('No hay parqueaderos ocupados'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const <DataColumn>[
                          DataColumn(label: Text('# Parqueadero')),
                          DataColumn(label: Text('Identificación')),
                          DataColumn(label: Text('Vehículo')),
                          DataColumn(label: Text('Estado')),
                          DataColumn(label: Text('Placa Vehículo')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: parqueaderos
                            .map((parqueadero) => DataRow(cells: [
                                  DataCell(Text(
                                      parqueadero['id_parqueadero'] ?? '')),
                                  DataCell(Text(
                                      parqueadero['identificacion'] ?? '')),
                                  DataCell(
                                      Text(parqueadero['tipo_vehiculo'] ?? '')),
                                  DataCell(Text(parqueadero['estado'] ?? '')),
                                  DataCell(Text(
                                      parqueadero['placa_vehiculo'] ?? '')),
                                  DataCell(
                                    IconButton(
                                      icon: Icon(Icons.edit,
                                          color: Colors.yellow),
                                      onPressed: () {
                                        // Abrir el diálogo para editar los datos
                                        openEditDialog(parqueadero);
                                      },
                                    ),
                                  ),
                                ]))
                            .toList(),
                      ),
                    ),
    );
  }
}
