import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.page.dart';
import 'doacoes.page.dart';
import 'dashboard.page.dart';

// Classe para representar uma família
class Family {
  final int id;
  final String respName;
  final String respSobrenome;
  final String respCpf;
  final String respTelefone;
  final String respEmail;
  final String familyDesc;
  final int enderecoId;

  Family({
    required this.id,
    required this.respName,
    required this.respSobrenome,
    required this.respCpf,
    required this.respTelefone,
    required this.respEmail,
    required this.familyDesc,
    required this.enderecoId,
  });

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'] ?? '0') ?? 0,
      respName: json['resp_name'] ?? '',
      respSobrenome: json['resp_sobrenome'] ?? '',
      respCpf: json['resp_cpf'] ?? '',
      respTelefone: json['resp_telefone'] ?? '',
      respEmail: json['resp_email'] ?? '',
      familyDesc: json['familyDesc'] ?? '',
      enderecoId: json['endereco_id'] is int
          ? json['endereco_id']
          : int.tryParse(json['endereco_id'] ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'resp_name': respName,
        'resp_sobrenome': respSobrenome,
        'resp_cpf': respCpf,
        'resp_telefone': respTelefone,
        'resp_email': respEmail,
        'familyDesc': familyDesc,
        'endereco_id': enderecoId,
      };
}


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, required this.title});

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


class FamiliesPage extends StatefulWidget {
  const FamiliesPage({super.key});

  @override
  _FamiliesPageState createState() => _FamiliesPageState();
}

class _FamiliesPageState extends State<FamiliesPage> {
  List<Family> _families = []; // Lista de famílias cadastradas
  final bool _isFiltersExpanded = false;
  Map<String, bool> parentescoOptions = {
    'Todos': true,
    'Responsável': false,
    'Filho': false,
    'Outro': false,
  };
  String selectedGender = 'Todos';
  RangeValues ageRange = const RangeValues(5, 95);

  @override
  void initState() {
    super.initState();
    _buscarFamilias();
  }

  // Função para buscar famílias do backend
  Future<void> _buscarFamilias() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenJWT');

    try {
      final response = await http.get(
        Uri.parse('https://backend-ong.vercel.app/api/getFamilias'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _families = data.map((json) => Family.fromJson(json)).toList();
        });
      } else {
        throw Exception('Erro ao buscar famílias');
      }
    } catch (e) {
      print('Erro ao buscar famílias: $e');
    }
  }

  Future<void> _adicionarFamilia(Family family) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenJWT');

    try {
      final response = await http.post(
        Uri.parse('https://backend-ong.vercel.app/api/addFamilia'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(family.toJson()),
      );

      if (response.statusCode == 201) {
        _buscarFamilias(); // Atualiza a lista de famílias
      } else {
        // Exibir detalhes do erro de resposta
        print(
            'Erro ao adicionar família: ${response.statusCode} - ${response.body}');
        throw Exception('Erro ao adicionar família');
      }
    } catch (e) {
      print('Erro ao adicionar família: $e');
    }
  }

  // Função para excluir uma família por ID
  Future<void> _excluirFamilia(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenJWT');

    try {
      final response = await http.delete(
        Uri.parse('https://backend-ong.vercel.app/api/deleteFamilyById/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _buscarFamilias(); // Atualiza a lista de famílias
      } else {
        throw Exception('Erro ao excluir família');
      }
    } catch (e) {
      print('Erro ao excluir família: $e');
    }
  }

  // Função para abrir o diálogo de adicionar família
  void _showAddFamilyDialog() {
    String name = '';
    String sobrenome = '';
    String cpf = '';
    String telefone = '';
    String email = '';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cadastrar Família'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Nome do Responsável'),
                  validator: (value) =>
                      value!.isEmpty ? 'Informe o nome' : null,
                  onSaved: (value) => name = value!,
                ),
                TextFormField(
                  decoration:
                      InputDecoration(labelText: 'Sobrenome do Responsável'),
                  validator: (value) =>
                      value!.isEmpty ? 'Informe o sobrenome' : null,
                  onSaved: (value) => sobrenome = value!,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'CPF do Responsável'),
                  validator: (value) => value!.isEmpty ? 'Informe o CPF' : null,
                  onSaved: (value) => cpf = value!,
                ),
                TextFormField(
                  decoration:
                      InputDecoration(labelText: 'Telefone do Responsável'),
                  validator: (value) =>
                      value!.isEmpty ? 'Informe o telefone' : null,
                  onSaved: (value) => telefone = value!,
                ),
                TextFormField(
                  decoration:
                      InputDecoration(labelText: 'Email do Responsável'),
                  validator: (value) =>
                      value!.isEmpty ? 'Informe o email' : null,
                  onSaved: (value) => email = value!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                _adicionarFamilia(Family(
                  id: 0, // Defina como 0 ou outro valor padrão de sua escolha
                  respName: name,
                  respSobrenome: sobrenome,
                  respCpf: cpf,
                  respTelefone: telefone,
                  respEmail: email,
                  familyDesc: '',
                  enderecoId: 0,
                ));
              }
            },
            child: Text('Cadastrar'),
          ),
        ],
      ),
    );
  }

  // Widget para a tabela de famílias
  Widget _buildFamilyList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("ID")),
          DataColumn(label: Text("Nome")),
          DataColumn(label: Text("Sobrenome")),
          DataColumn(label: Text("CPF")),
          DataColumn(label: Text("Telefone")),
          DataColumn(label: Text("Email")),
        ],
        rows: _families.map((family) {
          return DataRow(cells: [
            DataCell(Text(family.id.toString())),
            DataCell(Text(family.respName)),
            DataCell(Text(family.respSobrenome)),
            DataCell(Text(family.respCpf)),
            DataCell(Text(family.respTelefone)),
            DataCell(Text(family.respEmail)),
          ]);
        }).toList(),
      ),
    );
  }

  // Widget para a seção de filtros
  Widget _buildFiltersSection() {
    return ExpansionTile(
      title: Text(
        'Filtros',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parentesco', style: TextStyle(fontWeight: FontWeight.bold)),
            CheckboxListTile(
              title: Text('Todos'),
              value: parentescoOptions['Todos'],
              onChanged: (value) {
                setState(() {
                  parentescoOptions['Todos'] = value!;
                });
              },
            ),
            CheckboxListTile(
              title: Text('Responsável'),
              value: parentescoOptions['Responsável'],
              onChanged: (value) {
                setState(() {
                  parentescoOptions['Responsável'] = value!;
                });
              },
            ),
            CheckboxListTile(
              title: Text('Filho'),
              value: parentescoOptions['Filho'],
              onChanged: (value) {
                setState(() {
                  parentescoOptions['Filho'] = value!;
                });
              },
            ),
            CheckboxListTile(
              title: Text('Outro'),
              value: parentescoOptions['Outro'],
              onChanged: (value) {
                setState(() {
                  parentescoOptions['Outro'] = value!;
                });
              },
            ),
            Text('Gênero', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedGender,
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
            Text('Idade', style: TextStyle(fontWeight: FontWeight.bold)),
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
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(245, 245, 249, 1),
      appBar: CustomAppBar(title: ''),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Famílias Cadastradas',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Cadastradas: ${_families.length}',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFamilyList(),
            const SizedBox(height: 20),
            _buildFiltersSection(),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '© 2024 Ong Conforme',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFamilyDialog,
        backgroundColor: Colors.blue,
        tooltip: 'Adicionar Família',
        child: Icon(Icons.add),
      ),
    );
  }
}

