import 'package:flutter/material.dart';

import 'login.page.dart';
import 'familias.page.dart';
import 'doacoes.page.dart';
import 'dashboard.page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ong Conforme',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginFormPage(),
        '/dashboard': (context) => DashboardPage(),
        '/doacoes': (context) => DoacoesPage(),
        '/familias': (context) => FamiliesPage(),
      },
    );
  }
}

