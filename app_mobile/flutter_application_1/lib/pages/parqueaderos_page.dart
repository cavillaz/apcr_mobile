import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ParqueaderosPage extends StatefulWidget {
  const ParqueaderosPage({Key? key}) : super(key: key);

  @override
  _ParqueaderosPageState createState() => _ParqueaderosPageState();
}

class _ParqueaderosPageState extends State<ParqueaderosPage> {
  List<dynamic> parqueaderos = [];
  bool isLoading = true;
  String error = '';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController documentoController = TextEditingController();
  final TextEditingController placaController = TextEditingController();
  String tipoVehiculo = 'Carro';
  String tipoParqueadero = 'Residente';

  @override
  void initState() {
    super.initState();
    fetchParqueaderos();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchParqueaderos() async {
    const String apiUrl = 'https://api.softnerdapcr.icu/api/parqueadero';

    try {
      final token = await getToken();

      if (token == null) {
        setState(() {
          error = 'Token no encontrado. Inicia sesión nuevamente.';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          parqueaderos = (data['parqueadero'] as List)
              .where((p) =>
                  p['estado'] == 'ocupado' ||
                  p['estado'] == 'pendiente_aprobacion')
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          error =
              'Error al obtener los datos del servidor. Código: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error al conectar con el servidor: $e';
        isLoading = false;
      });
    }
  }

  Future<void> solicitarParqueadero() async {
    const String apiUrl = 'https://api.softnerdapcr.icu/api/parqueadero';
    try {
      final token = await getToken();

      if (token == null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content:
                const Text('Token no encontrado. Inicia sesión nuevamente.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Log de datos enviados al servidor
      print('Enviando datos: ${json.encode({
            'nombre_persona': nombreController.text,
            'documento_persona': documentoController.text,
            'placa_vehiculo': placaController.text,
            'tipo_vehiculo': tipoVehiculo,
            'tipo_parqueadero': tipoParqueadero,
          })}');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nombre_persona': nombreController.text,
          'documento_persona': documentoController.text,
          'placa_vehiculo': placaController.text,
          'tipo_vehiculo': tipoVehiculo,
          'tipo_parqueadero': tipoParqueadero,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Éxito'),
            content: Text(data['message']),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  fetchParqueaderos();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Manejo de errores cuando el statusCode no es 200
        print('Error al reservar parqueadero: ${response.body}');
        final errorData = json.decode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(errorData['message'] ?? 'Error desconocido'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Error al conectar con el servidor: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void showParqueaderoModal(Map<String, dynamic> parqueadero) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Detalles del Parqueadero ${parqueadero['parqueadero_id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${parqueadero['nombre_persona']}'),
            Text('Placa: ${parqueadero['placa_vehiculo']}'),
            Text('Tipo Vehículo: ${parqueadero['tipo_vehiculo']}'),
            Text('Estado: ${parqueadero['estado']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void showSolicitudModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Solicitar Parqueadero'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration:
                      const InputDecoration(labelText: 'Nombre de la persona'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el nombre.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: documentoController,
                  decoration: const InputDecoration(
                      labelText: 'Documento de la persona'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el documento.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: placaController,
                  decoration: const InputDecoration(labelText: 'Placa'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese la placa.';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: tipoVehiculo,
                  decoration:
                      const InputDecoration(labelText: 'Tipo de vehículo'),
                  items: ['Carro', 'Moto']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      tipoVehiculo = value!;
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  value: tipoParqueadero,
                  decoration:
                      const InputDecoration(labelText: 'Tipo de parqueadero'),
                  items: ['Residente', 'Visitante']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      tipoParqueadero = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).pop();
                  solicitarParqueadero();
                }
              },
              child: const Text('Reservar Parqueadero'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Parqueaderos'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // Tres cuadros por fila
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: parqueaderos.length,
                        itemBuilder: (context, index) {
                          final parqueadero = parqueaderos[index];
                          final estado = parqueadero['estado'];
                          return GestureDetector(
                            onTap: () {
                              showParqueaderoModal(parqueadero);
                            },
                            child: Card(
                              color: estado == 'ocupado'
                                  ? const Color.fromARGB(255, 240, 123, 115)
                                  : const Color.fromARGB(255, 233, 224, 146),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Parqueadero ${parqueadero['parqueadero_id']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Nombre: ${parqueadero['nombre_persona']}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      'Placa: ${parqueadero['placa_vehiculo']}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Estado: ${parqueadero['estado']}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton(
                            onPressed: showSolicitudModal,
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Solicitar Parqueadero',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
