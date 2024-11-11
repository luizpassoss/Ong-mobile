import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ongconforme/dashboard.page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginFormPage extends StatefulWidget {
  const LoginFormPage({super.key});

  @override
  _LoginFormPageState createState() => _LoginFormPageState();
}

class _LoginFormPageState extends State<LoginFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final String apiUrl = 'https://backend-ong.vercel.app/api/loginUser';
  bool isLoading = false;
  bool manterConectado = false;

  @override
  void initState() {
    super.initState();
    _verificarEstadoLogin(); // Verifica se o usuário deve ser mantido conectado
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Verifica se o usuário está conectado e mantém o estado de login
  Future<void> _verificarEstadoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    manterConectado = prefs.getBool('manterConectado') ?? false;
    final token = prefs.getString('tokenJWT');
    
    if (manterConectado && token != null) {
      _navegarParaDashboard(); // Navega direto para o Dashboard se o token existir e "Manter Conectado" estiver ativado
    }
  }

  Future<void> _validarLogin(String email, String senha) async {
    setState(() {
      isLoading = true; // Ativa o indicador de carregamento
    });

    try {
      final body = jsonEncode({
        "email": email,
        "password": senha,
      });

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['token'] != null) {
          String tokenJWT = data['token'];
          await _salvarToken(tokenJWT);
          _navegarParaDashboard();
        } else {
          _mostrarErro('Token JWT não encontrado.');
        }
      } else {
        _mostrarErro('Erro ao fazer login. Verifique suas credenciais.');
      }
    } catch (e) {
      _mostrarErro('Erro ao conectar à API.');
    } finally {
      setState(() {
        isLoading = false; // Desativa o indicador de carregamento
      });
    }
  }

  // Salva o token e a opção "Manter Conectado" em SharedPreferences
  Future<void> _salvarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tokenJWT', token);
    await prefs.setBool('manterConectado', manterConectado); // Salva o estado do checkbox
  }

  void _mostrarErro(String mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navegarParaDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardPage()),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      await _validarLogin(
        emailController.text,
        passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(255, 255, 255, 1),
      body: Column(
        children: [
          // Seção da Imagem de Fundo
          Expanded(
            flex: 2,
            child: SizedBox(
              width: double.infinity,
              child: Image.asset(
                'assets/images/fotodaong2.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Seção do Formulário de Login
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo e Switch para tema
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/ongconformelogo.png', // Caminho da imagem
                            height: 60, // Altura da logo
                          ),
                          Switch(
                            value: true,
                            onChanged: (val) {
                              // Lógica para troca de tema ou outra função
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      Text(
                        'Bem vindo!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Faça login para entrar.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Campo de Email
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira seu email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),

                      // Campo de Senha
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira sua senha';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),

                      // Checkbox "Manter conectado"
                      Row(
                        children: [
                          Checkbox(
                            value: manterConectado,
                            onChanged: (val) {
                              setState(() {
                                manterConectado = val!;
                              });
                            },
                          ),
                          Text('Manter conectado'),
                        ],
                      ),
                      SizedBox(height: 15),

                      // Botão de Login com o indicador de carregamento
                      isLoading
                          ? Center(child: CircularProgressIndicator()) // Indicador de carregamento
                          : ElevatedButton(
                              onPressed: _submitForm, // Submete o formulário
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text('Entrar', style: TextStyle(color: Colors.white)),
                            ),
                      SizedBox(height: 15),

                      // Footer
                      Center(
                        child: Text(
                          '© 2024 Ong Conforme',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
