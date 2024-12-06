import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'login.page.dart';
import 'familias.page.dart';
import 'doacoes.page.dart';
import 'dashboard.page.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ong Conforme',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
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
 

 