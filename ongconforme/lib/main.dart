import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: LoginFormPage(),
    );
  }
}

class LoginFormPage extends StatefulWidget {
  @override
  _LoginFormPageState createState() => _LoginFormPageState();
}

class _LoginFormPageState extends State<LoginFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final String apiUrl = 'https://backend-ong.vercel.app/api/loginUser';
  bool isLoading = false; // Adiciona o estado isLoading

  @override
  void dispose() {
    // Certifique-se de descartar os controladores ao fechar o widget
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _validarLogin(String email, String senha) async {
    setState(() {
      isLoading = true; // Ativa o indicador de carregamento
    });

    try {
      print('Enviando requisição para API com email: $email e senha: $senha');

      final body = jsonEncode({
        "email": email,
        "password": senha,
      });

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print('Status da resposta: ${response.statusCode}');
      print('Resposta da API: ${response.body}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data['token'] != null) {
          String tokenJWT = data['token'];
          print('Token JWT recebido: $tokenJWT');
          await _salvarToken(tokenJWT);
          _mostrarToken(tokenJWT);
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

  Future<void> _salvarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tokenJWT', token);
  }

  void _mostrarToken(String token) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Token JWT'),
        content: Text(token),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
      });
    });
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
          // Seção da Imagem
          Expanded(
            flex: 2,
            child: Container(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(width: 5),
                              Text(
                                'Conforme Instituto',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: true,
                            onChanged: (val) {
                              // Função de troca de tema ou outra função
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
                            value: true,
                            onChanged: (val) {
                              // Lógica para manter o usuário conectado
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
                              child: const Text('Entrar'),
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
class Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
      child: Center(
        child: Text(
          '© 2024 Ong Conforme',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  CustomAppBar({required this.title});

  void _navigateToPage(BuildContext context, String page) {
    switch (page) {
      case 'Dashboard':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
          (route) => false,
        );
        break;
      case 'Famílias':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => FamiliesPage()),
          (route) => false,
        );
        break;
      case 'Doações':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DoacoesPage()),
          (route) => false,
        );
        break;
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pesquisar"),
          content: TextField(
            decoration: InputDecoration(
              hintText: 'Digite...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              print("Pesquisando por: $value");
            },
          ),
          actions: [
            TextButton(
              child: Text("Fechar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginFormPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Color.fromRGBO(42, 48, 66, 1.0),
      leading: PopupMenuButton<String>(
        icon: Icon(Icons.menu),
        onSelected: (String page) {
          _navigateToPage(context, page);
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'Dashboard',
            child: Row(
              children: [
                Icon(Icons.dashboard, color: Colors.blue),
                SizedBox(width: 10),
                Text('Dashboard'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'Famílias',
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.green),
                SizedBox(width: 10),
                Text('Famílias'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'Doações',
            child: Row(
              children: [
                Icon(Icons.card_giftcard, color: Colors.orange),
                SizedBox(width: 10),
                Text('Doações'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            _showSearchDialog(context);
          },
        ),
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: () {
            _logout(context);
          },
        ),
      ],
      iconTheme: IconThemeData(color: Colors.white),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}



class DashboardPage extends StatelessWidget {
  Future<void> _obterToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('tokenJWT');

    if (token != null) {
      _mostrarToken(token);
    } else {
      _mostrarErro('Nenhum token encontrado.');
    }
  }

  void _mostrarToken(String token) {
    showDialog(
      context: MyApp.navigatorKey.currentState!.overlay!.context,
      builder: (context) => AlertDialog(
        title: const Text('Token JWT'),
        content: Text(token),
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

  void _mostrarErro(String mensagem) {
    showDialog(
      context: MyApp.navigatorKey.currentState!.overlay!.context,
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tokenJWT');
    Navigator.pushReplacement(
      MyApp.navigatorKey.currentState!.overlay!.context,
      MaterialPageRoute(builder: (context) => LoginFormPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: ''),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dashboard",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // Arrecadação Total
              _buildArrecadacaoTotal(),

              const SizedBox(height: 24),

              // Recentes
              _buildRecentes(),

              const SizedBox(height: 24),
              
              // Rodapé
              Footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrecadacaoTotal() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Arrecadação Total',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(42, 48, 66, 1.0),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Última atualização: Setembro',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'R\$4042',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(42, 48, 66, 1.0),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '12% acima da meta',
                        style: TextStyle(color: Colors.green, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                startDegreeOffset: 270,
                                sectionsSpace: 0,
                                centerSpaceRadius: 40,
                                sections: [
                                  PieChartSectionData(
                                    value: 101,
                                    color: const Color(0xFF51B0FE),
                                    radius: 18,
                                    title: '',
                                  ),
                                  PieChartSectionData(
                                    value: 100 - 101,
                                    color: const Color(0xFFE6F0FA),
                                    radius: 18,
                                    title: '',
                                  ),
                                ],
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  '101.0%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Meta',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recentes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(42, 48, 66, 1.0),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildRecentActivity(
                    '22 Nov', 'Responded to need "Volunteer Activities"'),
                _buildRecentActivity(
                    '17 Nov',
                    'Everyone realizes why a new common language would be desirable...'),
                _buildRecentActivity('Hoje',
                    'Joined the group "Boardsmanship Forum"'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'View More',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(String date, String activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: date == 'Hoje' ? Colors.blue : Colors.white,
                  border: Border.all(color: Colors.blue, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
              if (date != 'Hoje')
                Container(
                  width: 2,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            date,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(42, 48, 66, 1.0),
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward, color: Colors.grey, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activity,
              style: const TextStyle(
                color: Color.fromRGBO(42, 48, 66, 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class FamiliesPage extends StatefulWidget {
  @override
  _FamiliesPageState createState() => _FamiliesPageState();
}

class _FamiliesPageState extends State<FamiliesPage> {
  List<Family> _families = []; // Lista de famílias cadastradas

  // Variáveis para filtros
  bool _isFiltersExpanded = false;
  Map<String, bool> parentescoOptions = {
    'Todos': true,
    'Responsável': false,
    'Filho': false,
    'Outro': false,
  };
  String selectedGender = 'Todos';
  RangeValues ageRange = const RangeValues(5, 95);

  // Função para adicionar uma nova família
  void _addFamily(Family family) {
    setState(() {
      _families.add(family);
    });
  }

  // Função para mostrar o diálogo de cadastro de família
  void _showAddFamilyDialog() {
    String id = '', name = '', cpf = '';
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cadastro de Família'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'ID'),
                validator: (value) => value!.isEmpty ? 'Informe o ID' : null,
                onSaved: (value) => id = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nome do Responsável'),
                validator: (value) => value!.isEmpty ? 'Informe o Nome' : null,
                onSaved: (value) => name = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'CPF do Responsável'),
                validator: (value) => value!.isEmpty ? 'Informe o CPF' : null,
                onSaved: (value) => cpf = value!,
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
                _formKey.currentState!.save();
                _addFamily(Family(id: id, name: name, cpf: cpf));
                Navigator.of(context).pop();
              }
            },
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );
  }

  void _toggleFilterExpansion() {
    setState(() {
      _isFiltersExpanded = !_isFiltersExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: (''),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabela de Famílias
              _buildFamilyList(),
              const SizedBox(height: 24),
              
              // Filtros de Pesquisa
              _buildFiltersSection(),
              
              const SizedBox(height: 20),
              Footer(), // Rodapé
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFamilyDialog,
        child: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildFamilyList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Famílias Cadastradas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Campo de pesquisa
                TextField(
                  decoration: InputDecoration(
                    labelText: "Pesquisar responsável...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    // Implementar lógica de pesquisa, se necessário
                  },
                ),
                const SizedBox(height: 16),

                // Tabela de dados
                DataTable(
                  columns: const [
                    DataColumn(label: Text("ID")),
                    DataColumn(label: Text("Nome")),
                    DataColumn(label: Text("CPF")),
                  ],
                  rows: _families.map((family) {
                    return DataRow(cells: [
                      DataCell(Text(family.id)),
                      DataCell(Text(family.name)),
                      DataCell(Text(family.cpf)),
                    ]);
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggleFilterExpansion,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                _isFiltersExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_isFiltersExpanded)
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parentesco',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...parentescoOptions.keys.map((String key) {
                    return CheckboxListTile(
                      title: Text(key),
                      value: parentescoOptions[key],
                      onChanged: (bool? value) {
                        setState(() {
                          parentescoOptions[key] = value ?? false;
                          if (key == 'Todos' && value == true) {
                            parentescoOptions.updateAll((k, v) => k == 'Todos' ? true : false);
                          } else if (key != 'Todos' && value == true) {
                            parentescoOptions['Todos'] = false;
                          }
                        });
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  const Text(
                    'Gênero',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                      DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedGender = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Idade',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RangeSlider(
                    values: ageRange,
                    min: 0,
                    max: 120,
                    divisions: 12,
                    labels: RangeLabels(
                      '${ageRange.start.round()}',
                      '${ageRange.end.round()}',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        ageRange = values;
                      });
                    },
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Classe para representar uma família
class Family {
  final String id;
  final String name;
  final String cpf;

  Family({required this.id, required this.name, required this.cpf});
}




class Doacao {
  String id;
  String categoria;
  String item;
  String dataCriacao;
  int quantidade;
  String unidadeMedida;
  String entradaSaida;

  Doacao({
    required this.id,
    required this.categoria,
    required this.item,
    required this.dataCriacao,
    required this.quantidade,
    required this.unidadeMedida,
    required this.entradaSaida,
  });
}



class DoacoesPage extends StatefulWidget {
  @override
  _DoacoesPageState createState() => _DoacoesPageState();
}

class _DoacoesPageState extends State<DoacoesPage> {
  List<Doacao> _doacoes = [];
  TextEditingController searchController = TextEditingController();

  void _adicionarDoacao(Doacao doacao) {
    setState(() {
      _doacoes.add(doacao);
    });
  }

  void _editarDoacao(int index, Doacao novaDoacao) {
    setState(() {
      _doacoes[index] = novaDoacao;
    });
  }

  void _removerDoacao(int index) {
    setState(() {
      _doacoes.removeAt(index);
    });
  }

  void _navegarParaHistorico() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoricoDoacoesPage(doacoes: _doacoes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: ''),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchAndActionBar(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.history),
              label: Text('Ver Histórico de Doações'),
              onPressed: _navegarParaHistorico,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            Divider(thickness: 1, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            _buildDonationsTable(),
            const SizedBox(height: 20),
            Footer(), // Rodapé no final
          ],
        ),
      ),
    );
  }
    // Função para mostrar o diálogo de adicionar doação
  void _mostrarDialogoAdicionarDoacao() {
    final _formKey = GlobalKey<FormState>();
    String id = '', categoria = '', item = '', dataCriacao = '';
    int quantidade = 0;
    String unidadeMedida = 'Unidade';
    String entradaSaida = 'Entrada';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Doação'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'ID'),
                    onSaved: (value) => id = value!,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Categoria'),
                    onSaved: (value) => categoria = value!,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Item'),
                    onSaved: (value) => item = value!,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Data de Criação'),
                    onSaved: (value) => dataCriacao = value!,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Quantidade'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => quantidade = int.parse(value!),
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  DropdownButtonFormField(
                    decoration: InputDecoration(labelText: 'Unidade de Medida'),
                    value: unidadeMedida,
                    items: ['Unidade', 'Kilo'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) => unidadeMedida = newValue as String,
                  ),
                  DropdownButtonFormField(
                    decoration: InputDecoration(labelText: 'Entrada/Saída'),
                    value: entradaSaida,
                    items: ['Entrada', 'Saída'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) => entradaSaida = newValue as String,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _adicionarDoacao(Doacao(
                    id: id,
                    categoria: categoria,
                    item: item,
                    dataCriacao: dataCriacao,
                    quantidade: quantidade,
                    unidadeMedida: unidadeMedida,
                    entradaSaida: entradaSaida,
                  ));
                  Navigator.pop(context);
                }
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndActionBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Pesquisar Item...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {}); // Atualize a exibição com base na pesquisa
            },
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          icon: Icon(Icons.filter_list),
          label: Text('Filtro'),
          onPressed: () {
            // Lógica para filtros adicionais
          },
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          icon: Icon(Icons.add),
          label: Text('Nova Doação'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          onPressed: _mostrarDialogoAdicionarDoacao,
        ),
      ],
    );
  }

  Widget _buildDonationsTable() {
    return Expanded(
      child: _doacoes.isEmpty
          ? Center(
              child: Text(
                'Nenhuma doação encontrada.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Categoria')),
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('Data Criação')),
                  DataColumn(label: Text('Quantidade')),
                  DataColumn(label: Text('Unidade')),
                  DataColumn(label: Text('Entrada/Saída')),
                  DataColumn(label: Text('Ações')),
                ],
                rows: _buildDonationRows(),
              ),
            ),
    );
  }

  List<DataRow> _buildDonationRows() {
    return List.generate(_doacoes.length, (index) {
      final doacao = _doacoes[index];
      return DataRow(cells: [
        DataCell(Text(doacao.id)),
        DataCell(Text(doacao.categoria)),
        DataCell(Text(doacao.item)),
        DataCell(Text(doacao.dataCriacao)),
        DataCell(Text(doacao.quantidade.toString())),
        DataCell(Text(doacao.unidadeMedida)),
        DataCell(Text(doacao.entradaSaida)),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  _mostrarDialogoEditarDoacao(index, doacao);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  _removerDoacao(index);
                },
              ),
            ],
          ),
        ),
      ]);
    });
  }

  void _mostrarDialogoEditarDoacao(int index, Doacao doacao) {
    final _formKey = GlobalKey<FormState>();
    String id = doacao.id, categoria = doacao.categoria, item = doacao.item;
    String dataCriacao = doacao.dataCriacao, entradaSaida = doacao.entradaSaida;
    int quantidade = doacao.quantidade;
    String unidadeMedida = doacao.unidadeMedida;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Doação'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: id,
                    decoration: InputDecoration(labelText: 'ID'),
                    onSaved: (value) => id = value!,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  TextFormField(
                    initialValue: categoria,
                    decoration: InputDecoration(labelText: 'Categoria'),
                    onSaved: (value) => categoria = value!,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  TextFormField(
                    initialValue: item,
                    decoration: InputDecoration(labelText: 'Item'),
                    onSaved: (value) => item = value!,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  TextFormField(
                    initialValue: dataCriacao,
                    decoration: InputDecoration(labelText: 'Data de Criação'),
                    onSaved: (value) => dataCriacao = value!,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  TextFormField(
                    initialValue: quantidade.toString(),
                    decoration: InputDecoration(labelText: 'Quantidade'),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => quantidade = int.parse(value!),
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                  DropdownButtonFormField(
                    decoration: InputDecoration(labelText: 'Unidade de Medida'),
                    value: unidadeMedida,
                    items: ['Unidade', 'Kilo'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) => unidadeMedida = newValue as String,
                  ),
                  DropdownButtonFormField(
                    decoration: InputDecoration(labelText: 'Entrada/Saída'),
                    value: entradaSaida,
                    items: ['Entrada', 'Saída'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) => entradaSaida = newValue as String,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _editarDoacao(index, Doacao(
                    id: id,
                    categoria: categoria,
                    item: item,
                    dataCriacao: dataCriacao,
                    quantidade: quantidade,
                    unidadeMedida: unidadeMedida,
                    entradaSaida: entradaSaida,
                  ));
                  Navigator.pop(context);
                }
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}


// Página de histórico de doações
class HistoricoDoacoesPage extends StatelessWidget {
  final List<Doacao> doacoes;

  HistoricoDoacoesPage({required this.doacoes});

  @override
 Widget build(BuildContext context) {
  return Scaffold(
    appBar: CustomAppBar(
      title: '',
      
    ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botão Voltar
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text('Voltar'),
            ),
            const SizedBox(height: 20),
            
            // Dados da Doação
            Text(
              'Dados da doação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arroz',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.category, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Categoria: Alimento',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.inventory, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Quantidade: 55',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Meta da Doação
            Text(
              'Meta da Doação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arrecadação Atual',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '55 / 200',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '27% da meta total',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '20, setembro de 2024',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: 0.27,
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    
                    // Campo para Configurar Meta
                    Text(
                      'Configurar Meta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Meta',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Data limite',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}