import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.page.dart';
import 'doacoes.page.dart';
import 'dashboard.page.dart';
import 'dart:ui';
 
 
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
 
  Future<void> _logout(BuildContext context) async {
    // Limpa o estado de login armazenado em SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tokenJWT');
    await prefs.remove('manterConectado');
 
    // Redireciona para a tela de login
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
        // Ícone de usuário que exibe opções
        PopupMenuButton<String>(
          icon: Icon(Icons.account_circle),
          onSelected: (value) {
            if (value == 'Logout') {
              _logout(context); // Chama o método de logout
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'Logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Logout'),
                ],
              ),
            ),
          ],
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
  List<Family> _families = []; // Lista original de famílias
  List<Family> _filteredFamilies = []; // Lista de famílias filtradas
  final bool _isFiltersExpanded = false;
  String _searchQuery = ''; // Variável para armazenar o texto da pesquisa
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
          _filteredFamilies = List.from(_families); // Inicializa a lista filtrada com todas as famílias
        });
      } else {
        throw Exception('Erro ao buscar famílias');
      }
    } catch (e) {
      print('Erro ao buscar famílias: $e');
    }
  }
 
 
 // Função para adicionar uma nova família com endereço
Future<void> _adicionarFamiliaComEndereco({
  required String respName,
  required String respSobrenome,
  required String respCpf,
  required String respTelefone,
  required String respEmail,
  required String familyDesc,
  required Map<String, String> endereco, // Endereço
  required List<Map<String, dynamic>> membros, // Membros da família
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('tokenJWT');
  print('Token: $token'); // Verificando se o token é válido
 
  try {
    // 1. Adicionar Endereço
    final enderecoResponse = await http.post(
      Uri.parse('https://backend-ong.vercel.app/api/addAddress'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(endereco),
    );
 
    print('Resposta de Adicionar Endereço: ${enderecoResponse.statusCode}'); // Print para verificar a resposta
    if (enderecoResponse.statusCode == 200) {  // Verificando se o status é 200
      final enderecoData = jsonDecode(enderecoResponse.body);
      final int enderecoId = enderecoData['id']; // Obter o ID do endereço
      print('ID do Endereço: $enderecoId'); // Verificando o ID do endereço
 
      // 2. Adicionar Família com o ID do endereço
      final familiaResponse = await http.post(
        Uri.parse('https://backend-ong.vercel.app/api/addFamilia'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'respName': respName,
          'respSobrenome': respSobrenome,
          'respCpf': respCpf,
          'respEmail': respEmail,
          'respTelefone': respTelefone,
          'familyDesc': familyDesc,
          'endereco_id': enderecoId, // Inclui o ID do endereço aqui
        }),
      );
 
      print('Resposta de Adicionar Família: ${familiaResponse.statusCode}'); // Print para verificar a resposta
      if (familiaResponse.statusCode == 201) {
        final familiaData = jsonDecode(familiaResponse.body);
        final int familiaId = familiaData['id']; // Obter o ID da família
        print('ID da Família: $familiaId'); // Verificando o ID da família
 
        // 3. Adicionar Membros à Família
        if (membros.isNotEmpty) {
          final membrosResponse = await http.post(
            Uri.parse('https://backend-ong.vercel.app/api/addMemberToFamilia'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'familyId': familiaId,
              'newMembers': membros,
            }),
          );
 
          print('Resposta de Adicionar Membros: ${membrosResponse.statusCode}'); // Print para verificar a resposta
          if (membrosResponse.statusCode == 201) {
            print('Membros adicionados com sucesso.');
          } else {
            print('Erro ao adicionar membros: ${membrosResponse.body}');
          }
        }
        _buscarFamilias(); // Atualiza a lista de famílias
      } else {
        print('Erro ao adicionar família: ${familiaResponse.body}');
      }
    } else {
      print('Erro ao adicionar endereço: ${enderecoResponse.body}');
    }
  } catch (e) {
    print('Erro ao adicionar família com endereço: $e');
  }
}
 
 
 
 Future<void> _excluirFamilia(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('tokenJWT');
print(id);
  try {
    final response = await http.delete(
      Uri.parse('https://backend-ong.vercel.app/api/deleteFamilyById?id=$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
 
 
    if (response.statusCode == 200) {
      print('Família excluída com sucesso.');
      _buscarFamilias(); // Atualiza a lista de famílias
    } else {
      print('Erro ao excluir família: ${response.statusCode}');
      print('Resposta do servidor: ${response.body}');
      throw Exception('Erro ao excluir família');
    }
  } catch (e) {
    print('Erro ao excluir família: $e');
  }
}
 
 void _confirmDelete(BuildContext context, int familyId) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Excluir Família'),
      content: Text('Tem certeza que deseja excluir esta família?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
          style: ElevatedButton.styleFrom(foregroundColor: Colors.black),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            print('Excluindo família com ID: $familyId');
            _excluirFamilia(familyId.toString());
          },
          child: Text('Excluir'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
        ),
      ],
    ),
  );
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
    backgroundColor: Colors.white, // Card branco
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Bordas arredondadas no card
    ),
    title: Text(
      'Cadastrar Família',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color.fromARGB(255, 5, 5, 5), // Cor azul para o título
      ),
    ),
    content: Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nome do Responsável
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Nome do Responsável',
                labelStyle: TextStyle(color: const Color.fromARGB(255, 119, 119, 119), fontWeight: FontWeight.w500), // Cor da label
                fillColor: Colors.grey[200], // Cor de fundo cinza
                filled: true, // Aplica a cor de fundo
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 2), // Borda azul no foco
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 0), // Borda padrão cinza
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Informe o nome' : null,
              onSaved: (value) => name = value!,
            ),
            SizedBox(height: 12),
            // Sobrenome do Responsável
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Sobrenome',
                labelStyle: TextStyle(color: const Color.fromARGB(255, 119, 119, 119), fontWeight: FontWeight.w500),
                fillColor: Colors.grey[200],
                filled: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 0),
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Informe o sobrenome' : null,
              onSaved: (value) => sobrenome = value!,
            ),
            SizedBox(height: 12),
            // CPF do Responsável
            TextFormField(
              decoration: InputDecoration(
                labelText: 'CPF',
                labelStyle: TextStyle(color: const Color.fromARGB(255, 119, 119, 119), fontWeight: FontWeight.w500),
                fillColor: Colors.grey[200],
                filled: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 0),
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Informe o CPF' : null,
              onSaved: (value) => cpf = value!,
            ),
            SizedBox(height: 12),
            // Telefone do Responsável
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Telefone',
                labelStyle: TextStyle(color: const Color.fromARGB(255, 119, 119, 119), fontWeight: FontWeight.w500),
                fillColor: Colors.grey[200],
                filled: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 0),
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Informe o telefone' : null,
              onSaved: (value) => telefone = value!,
            ),
            SizedBox(height: 12),
            // Email do Responsável
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: const Color.fromARGB(255, 119, 119, 119), fontWeight: FontWeight.w500),
                fillColor: Colors.grey[200],
                filled: true,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 0),
                ),
              ),
              validator: (value) => value!.isEmpty ? 'Informe o email' : null,
              onSaved: (value) => email = value!,
            ),
          ],
        ),
      ),
    ),
    actions: [
      // Botão Cancelar
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Cancelar',
          style: TextStyle(
            color: const Color.fromARGB(255, 65, 65, 65), // Cor do botão cancelar
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      // Botão Cadastrar
      ElevatedButton(
        onPressed: () {
          if (formKey.currentState!.validate()) {
            formKey.currentState!.save();
 
            // Exemplo de dados do endereço e membros
            final endereco = {
              'street': 'Rua Principal',
              'number': '123',
              'neighborhood': 'Centro',
              'city': 'Joinville',
              'state': 'SC',
              'zipcode': '89200000',
              'complement': 'Apartamento 202',
            };
 
            final membros = [
              {'membro': 'João', 'genero': 'Masculino', 'idade': 30},
              {'membro': 'Maria', 'genero': 'Feminino', 'idade': 25},
            ];
 
            _adicionarFamiliaComEndereco(
              respName: name,
              respSobrenome: sobrenome,
              respCpf: cpf,
              respTelefone: telefone,
              respEmail: email,
              familyDesc: 'Família Exemplo',
              endereco: endereco,
              membros: membros,
            );
 
            Navigator.of(context).pop(); // Fecha o diálogo
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue, // Cor de fundo do botão
          foregroundColor: Colors.white, // Cor do texto no botão
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Bordas arredondadas
          ),
        ),
        child: Text('Cadastrar'),
      ),
    ],
  ),
);
}
 
Widget _buildSearchField() {
  return TextField(
    onChanged: (query) {
      setState(() {
        _searchQuery = query;
        _filteredFamilies = _families.where((family) {
          return family.respName
              .toLowerCase()
              .startsWith(query.toLowerCase());
        }).toList();
      });
    },
    decoration: InputDecoration(
      filled: true, // Ativa o fundo preenchido
      fillColor: Color.fromRGBO(240, 240, 240, 1), // Cor do fundo do campo
      labelText: 'Pesquisar por nome...',
      labelStyle: TextStyle(color: const Color.fromARGB(255, 51, 51, 51), fontWeight: FontWeight.w500, fontSize: 16), // Cor do texto do rótulo
      prefixIcon: Icon(Icons.search, color: Colors.grey[700]), // Ícone de pesquisa
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), // Bordas arredondadas
        borderSide: BorderSide.none, // Remove a borda padrão
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 20), // Padding interno
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), // Mesma borda para estado habilitado
        borderSide: BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), // Borda ao focar
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
    ),
    style: TextStyle(fontSize: 16), // Tamanho do texto de entrada
  );
}
 
 
Widget _buildFamilyList() {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.grey[200]), // Cor cinza no cabeçalho
      columns: const [
        DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text("Nome", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text("Sobrenome", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text("CPF", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text("Telefone", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
        DataColumn(label: Text("Ações", style: TextStyle(fontWeight: FontWeight.bold))), // Coluna de Ações
      ],
      rows: _filteredFamilies.map((family) {
        return DataRow(cells: [
          DataCell(Text(family.id.toString())),
          DataCell(Text(family.respName)),
          DataCell(Text(family.respSobrenome)),
          DataCell(Text(family.respCpf)),
          DataCell(Text(family.respTelefone)),
          DataCell(Text(family.respEmail)),
          DataCell(
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _confirmDelete(context, family.id); // Confirmação antes de excluir
                  },
                ),
              ],
            ),
          ),
        ]);
      }).toList(),
    ),
  );
}
 
 
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Color.fromRGBO(245, 245, 249, 1),
    appBar: CustomAppBar(title: ''),
    body: SingleChildScrollView( // Permite rolar o conteúdo
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card para conter a área de pesquisa e ações
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0.5,
              color: Colors.white, // Cor de fundo do card
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra de pesquisa e opções de filtro
                    _buildSearchField(),
                    const SizedBox(height: 20), // Espaçamento abaixo da pesquisa
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Famílias Cadastradas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4), // Espaçamento entre o título e a descrição
                            Row(
                              children: [
                                Icon(
                                  Icons.family_restroom, // Ícone de família
                                  color: Colors.blue, // Cor do ícone
                                  size: 20, // Tamanho do ícone
                                ),
                                const SizedBox(width: 8), // Espaçamento entre o ícone e o texto
                                Text(
                                  'Cadastradas: ${_filteredFamilies.length}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                       
                      ],
                    ),
                    const SizedBox(height: 16), // Espaçamento entre o título e a tabela
                    _buildFamilyList(), // Substituído Expanded para não ultrapassar o limite de tamanho
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Espaçamento entre o card e o rodapé
            Footer(),
          ],
        ),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _showAddFamilyDialog,
      backgroundColor: const Color.fromARGB(255, 12, 56, 92),
      tooltip: 'Adicionar Família',
      child: Icon(
        Icons.add,
        color: Colors.white,
      ),
    ),
  );
}
}
 
class Footer extends StatelessWidget {
  const Footer({super.key});
 
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