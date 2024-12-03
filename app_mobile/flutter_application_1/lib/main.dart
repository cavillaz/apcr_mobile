import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/login_page.dart';
import 'pages/welcome_page.dart';
import 'pages/parqueaderos_page.dart'; // Importa la página de parqueaderos

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'APCR App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Configuración de rutas
      routes: {
        '/': (context) => const AuthCheck(),
        '/welcome': (context) => WelcomePage(),
        '/parqueaderos': (context) => ParqueaderosPage(), // Nueva ruta
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  String? token;

  @override
  void initState() {
    super.initState();
    checkAuth();
  }

  Future<void> checkAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
    });
  }

  @override
  Widget build(BuildContext context) {
    return token == null
        ? LoginPage()
        : WelcomePage(); // Redirige al dashboard si hay un token
  }
}
