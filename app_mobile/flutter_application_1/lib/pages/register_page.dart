import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class RegisterPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final Dio dio = Dio(BaseOptions(
    baseUrl: 'https://api.softnerdapcr.icu/api/',
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 5),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  Future<void> register(BuildContext context) async {
    try {
      final response = await dio.post(
        'register',
        data: {
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
          'confirm_password': confirmPasswordController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        // Mostrar mensaje de éxito
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Éxito'),
            content: const Text('Usuario registrado exitosamente.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Cierra el diálogo
                  Navigator.of(context).pop(); // Regresa al login
                },
              ),
            ],
          ),
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final responseData = e.response!.data;
        String errorMessage = '';

        // Procesar errores específicos del servidor
        if (responseData['messages'] != null &&
            responseData['messages']['errors'] != null) {
          final errors = responseData['messages']['errors'];

          // Traducir errores al español
          if (errors['email'] != null &&
              errors['email'] ==
                  'The email field must contain a unique value.') {
            errorMessage = 'El correo electrónico ya está registrado.';
          } else {
            // Procesar otros errores
            errors.forEach((key, value) {
              errorMessage += '$value\n';
            });
          }
        } else {
          errorMessage = responseData['message'] ?? 'Error inesperado.';
        }

        showErrorDialog(context, errorMessage.trim());
      } else {
        showErrorDialog(context, 'No se pudo conectar al servidor.');
      }
    } catch (e) {
      // Manejar errores generales
      print("Error general: $e");
      showErrorDialog(context, 'Ocurrió un error inesperado.');
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: emailController,
                decoration:
                    const InputDecoration(labelText: 'Correo Electrónico'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Ingrese su correo electrónico.';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Ingrese un correo válido.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Ingrese su contraseña.';
                  } else if (value.length < 8) {
                    return 'La contraseña debe tener al menos 8 caracteres.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: 'Confirmar Contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Confirme su contraseña.';
                  } else if (value != passwordController.text) {
                    return 'Las contraseñas no coinciden.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    register(context);
                  }
                },
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
