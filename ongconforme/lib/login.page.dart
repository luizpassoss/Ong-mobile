import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ongconforme/dashboard.page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
 
 
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
 
Future<void> _logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('tokenJWT'); // Remove o token
  await prefs.remove('manterConectado'); // Reseta a configuração de manter conectado
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginFormPage()), // Redireciona para a tela de login
  );
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
    resizeToAvoidBottomInset: true, // Permite que o teclado empurre o conteúdo adequadamente
    body: Stack(
      children: [
        // Imagem de fundo
        SizedBox.expand(
          child: Image.asset(
            'assets/images/fotodaong2.png',
            fit: BoxFit.cover,
          ),
        ),
        // Efeito de desfoque na imagem de fundo
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
        ),
        // Formulário de login centralizado
        Center(
          child: SingleChildScrollView( // Evita overflow quando o teclado aparece
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo e título
                    Center(
                      child: Image.asset(
                        'assets/images/ongconformelogo.png',
                        height: 40,
                      ),
                    ),
                    SizedBox(height: 15),
                    Center(
                      child: Text(
                        'Bem-vindo!',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Center(
                      child: Text(
                        'Faça login para entrar.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
 
                    // Campo de Email
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email, size: 18),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(fontSize: 14),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira seu email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
 
                    // Campo de Senha
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock, size: 18),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      style: TextStyle(fontSize: 14),
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
                          activeColor: Colors.blue,
                        ),
                        Text(
                          'Manter conectado',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
 
                    // Botão de Login
                    AnimatedScale(
                      duration: Duration(milliseconds: 200),
                      scale: isLoading ? 0.95 : 1.0,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size(double.infinity, 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5, // Indicador menor
                                  color: Colors.white, // Cor branca
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                      ),
                    ),
                    SizedBox(height: 10),
 
                    // Footer
                    Center(
                      child: Text(
                        '© 2024 Ong Conforme',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
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
