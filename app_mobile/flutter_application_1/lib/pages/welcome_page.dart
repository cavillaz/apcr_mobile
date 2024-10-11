// lib/pages/welcome_page.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart'; // Importa la página de Login
import 'reportes_page.dart'; // Importa la página de Reportes
import 'administrar_usuarios_page.dart'; // Importa la página de Administrar Usuarios

class WelcomePage extends StatelessWidget {
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('APCR'),
        actions: [
          Icon(Icons.person),
          Text('Usuario'),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text('Menú'),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            // Elimina la opción Administrar Zonas
            /*
            ListTile(
              leading: Icon(Icons.location_city),
              title: Text('Administrar Zonas'),
              onTap: () {},
            ),
            */
            ListTile(
              leading: Icon(Icons.report),
              title: Text('Reportes'),
              onTap: () {
                // Navega a la página de Reportes
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReportesPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Administrar Usuarios'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AdministrarUsuariosPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Salir'),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs
                    .remove('token'); // Elimina el token al cerrar sesión
                // Redirige a la página de login
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/apcr_logo.png', height: 100),
            FutureBuilder<String?>(
              future: getToken(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    // Puedes manejar el token aquí si es necesario
                    return Text('Bienvenido');
                  } else {
                    return Text('No hay token disponible');
                  }
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
