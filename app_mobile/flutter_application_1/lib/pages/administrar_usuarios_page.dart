import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AdministrarUsuariosPage extends StatefulWidget {
  const AdministrarUsuariosPage({Key? key}) : super(key: key);

  @override
  State<AdministrarUsuariosPage> createState() =>
      _AdministrarUsuariosPageState();
}

class _AdministrarUsuariosPageState extends State<AdministrarUsuariosPage> {
  List<dynamic> usuarios = [];
  bool isLoading = true;
  String error = '';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController claveController = TextEditingController();
  final TextEditingController nombreCompletoController =
      TextEditingController();
  final TextEditingController documentoController = TextEditingController();
  final TextEditingController celularController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsuarios();
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchUsuarios() async {
    const String apiUrl = 'https://api.softnerdapcr.icu/api/residente';

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

      print('Estado de la respuesta: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);

        setState(() {
          usuarios = data['tb_usuarios'] ?? [];
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          error = 'Recurso no encontrado. Código: 404';
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

  Future<void> agregarUsuario() async {
    const String apiUrl = 'https://api.softnerdapcr.icu/api/residente-insert';

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

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'correo': correoController.text.trim(),
          'clave': claveController.text,
          'nombre_completo': nombreCompletoController.text.trim(),
          'numero_documento': documentoController.text.trim(),
          'numero_celular': celularController.text.trim(),
        }),
      );

      print('Estado de la respuesta: ${response.statusCode}');
      print('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 201) {
        // Actualiza la lista de usuarios
        await fetchUsuarios();

        // Cierra el modal antes de mostrar el mensaje de éxito
        Navigator.of(context).pop();

        // Muestra el mensaje de éxito
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Éxito'),
            content: const Text('Usuario registrado exitosamente.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final data = json.decode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(data['message'] ?? 'Error desconocido'),
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

  void mostrarFormularioEditarUsuario(
      int idUsuario, Map<String, dynamic> usuario) {
    correoController.text = usuario['correo'];
    claveController.clear(); // No mostrar la clave por seguridad
    nombreCompletoController.text = usuario['nombre_completo'];
    documentoController.text = usuario['numero_documento'];
    celularController.text = usuario['numero_celular'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Usuario'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: correoController,
                  decoration: const InputDecoration(labelText: 'Correo'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el correo.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: claveController,
                  decoration: const InputDecoration(labelText: 'Nueva Clave'),
                  obscureText: true,
                ),
                TextFormField(
                  controller: nombreCompletoController,
                  decoration:
                      const InputDecoration(labelText: 'Nombre Completo'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el nombre completo.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: documentoController,
                  decoration:
                      const InputDecoration(labelText: 'Número de Documento'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el número de documento.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: celularController,
                  decoration:
                      const InputDecoration(labelText: 'Número de Celular'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el número de celular.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  editarUsuario(idUsuario);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> eliminarUsuario(int id) async {
    final String apiUrl = 'https://api.softnerdapcr.icu/api/residente/$id';

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

      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        fetchUsuarios(); // Refrescar la lista después de eliminar
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Éxito'),
            content: const Text('Usuario eliminado correctamente.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final data = json.decode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(data['message'] ?? 'Error desconocido'),
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

  Future<void> editarUsuario(int idUsuario) async {
    final String apiUrl =
        'https://api.softnerdapcr.icu/api/residente/$idUsuario';

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

      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'correo': correoController.text.trim(),
          'clave':
              claveController.text.isNotEmpty ? claveController.text : null,
          'nombre_completo': nombreCompletoController.text.trim(),
          'numero_documento': documentoController.text.trim(),
          'numero_celular': celularController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        fetchUsuarios();
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Éxito'),
            content: const Text('Usuario actualizado exitosamente.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        final data = json.decode(response.body);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(data['message'] ?? 'Error desconocido'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Usuarios'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Administración de Usuarios',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              correoController.clear();
                              claveController.clear();
                              nombreCompletoController.clear();
                              documentoController.clear();
                              celularController.clear();

                              // Mostrar formulario de agregar usuario
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Agregar Usuario'),
                                    content: Form(
                                      key: _formKey,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextFormField(
                                            controller: correoController,
                                            decoration: const InputDecoration(
                                                labelText: 'Correo'),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Por favor ingrese el correo.';
                                              }
                                              return null;
                                            },
                                          ),
                                          TextFormField(
                                            controller: claveController,
                                            decoration: const InputDecoration(
                                                labelText: 'Clave'),
                                            obscureText: true,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Por favor ingrese la clave.';
                                              }
                                              return null;
                                            },
                                          ),
                                          TextFormField(
                                            controller:
                                                nombreCompletoController,
                                            decoration: const InputDecoration(
                                                labelText: 'Nombre Completo'),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Por favor ingrese el nombre completo.';
                                              }
                                              return null;
                                            },
                                          ),
                                          TextFormField(
                                            controller: documentoController,
                                            decoration: const InputDecoration(
                                                labelText:
                                                    'Número de Documento'),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Por favor ingrese el número de documento.';
                                              }
                                              return null;
                                            },
                                          ),
                                          TextFormField(
                                            controller: celularController,
                                            decoration: const InputDecoration(
                                                labelText: 'Número de Celular'),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Por favor ingrese el número de celular.';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            agregarUsuario(); // Llamada al método de inserción
                                          }
                                        },
                                        child: const Text('Guardar'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Agregar Usuario'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Correo')),
                            DataColumn(label: Text('Número de Documento')),
                            DataColumn(label: Text('Nombre Completo')),
                            DataColumn(label: Text('Rol')),
                            DataColumn(label: Text('Acciones')),
                          ],
                          rows: usuarios.map((usuario) {
                            return DataRow(cells: [
                              DataCell(Text(usuario['correo'])),
                              DataCell(Text(usuario['numero_documento'])),
                              DataCell(Text(usuario['nombre_completo'])),
                              DataCell(Text(usuario['rol'])),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.orange),
                                    onPressed: () {
                                      mostrarFormularioEditarUsuario(
                                          int.parse(usuario['id']), usuario);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Confirmación'),
                                          content: const Text(
                                              '¿Estás seguro de que deseas eliminar este usuario?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop(); // Cerrar el diálogo
                                                eliminarUsuario(int.parse(usuario[
                                                    'id'])); // Llamar a la función
                                              },
                                              child: const Text('Eliminar'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
