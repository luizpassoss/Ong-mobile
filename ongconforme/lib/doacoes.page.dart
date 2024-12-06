import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ongconforme/dashboard.page.dart';
import 'package:ongconforme/historico_doacao.page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.page.dart';
import 'familias.page.dart';
import 'dart:ui';

class Doacao {
  int id;
  String categoria;
  String itemName;
  String dataCreated;
  int quantidade;
  int metaQuantidade;
  String metaDate;


  Doacao({
    required this.id,
    required this.categoria,
    required this.itemName,
    required this.dataCreated,
    required this.quantidade,
    required this.metaQuantidade,
    required this.metaDate,
  });


  factory Doacao.fromJson(Map<String, dynamic> json) {
    return Doacao(
      id: json['id'] ?? 0, // Define um valor padrão se `id` for `null`
      categoria: json['categoria'] ?? 'Desconhecido',
      itemName: json['itemName'] ?? 'Desconhecido',
      dataCreated: json['dataCreated'] ?? 'Data Desconhecida',
      quantidade: json['qntd'] ?? 0,
      metaQuantidade: json['metaQntd'] ?? 0,
      metaDate: json['metaDate'] ?? 'Data Meta Desconhecida',
    );
  }


  Map<String, dynamic> toJson() => {
        'categoria': categoria,
        'itemName': itemName,
        'dataCreated': dataCreated,
        'qntd': quantidade,
        'metaQntd': metaQuantidade,
        'metaDate': metaDate,
      };
}


class DoacoesPage extends StatefulWidget {
  const DoacoesPage({super.key});


  @override
  _DoacoesPageState createState() => _DoacoesPageState();
}


class _DoacoesPageState extends State<DoacoesPage> {
  List<Doacao> _doacoes = [];
  List<Doacao> _doacoesFiltradas = []; // Lista de doações filtradas
  String _termoPesquisa = ''; // Termo de pesquisa
  String? _categoriaSelecionada; // Categoria selecionada para o filtro


  @override
  void initState() {
    super.initState();
    buscarDoacoes(); // Carrega as doações ao iniciar a página
  }


  void _filtrarDoacoes() {
    setState(() {
      _doacoesFiltradas = _doacoes.where((doacao) {
        final matchCategoria = _categoriaSelecionada == null ||
            doacao.categoria == _categoriaSelecionada;
        final matchPesquisa = _termoPesquisa.isEmpty ||
            doacao.itemName
                .toLowerCase()
                .contains(_termoPesquisa.toLowerCase());
        return matchCategoria && matchPesquisa;
      }).toList();
    });
  }


  void _filtrarPorTermoPesquisa(String termo) {
    setState(() {
      _termoPesquisa = termo;
      _doacoesFiltradas = _doacoes.where((doacao) {
        return doacao.itemName.toLowerCase().contains(termo.toLowerCase());
      }).toList();
    });
  }


// Função para buscar todas as doações
  Future<void> buscarDoacoes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenJWT');


    try {
      final response = await http.get(
        Uri.parse('https://backend-ong.vercel.app/api/getDoacao'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _doacoes = data.map((json) => Doacao.fromJson(json)).toList();
          _doacoesFiltradas = _doacoes; // Inicializa a lista filtrada
        });
      } else {
        throw Exception('Erro ao buscar doações');
      }
    } catch (e) {
      print('Erro ao buscar doações: $e');
    }
  }


  // Função para buscar uma doação específica
  Future<Doacao?> buscarDoacaoPorId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenJWT');


    try {
      final response = await http.get(
        Uri.parse('https://backend-ong.vercel.app/api/getSingleDoacao/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode == 200) {
        return Doacao.fromJson(jsonDecode(response.body));
      } else {
        print('Erro ao buscar a doação');
        return null;
      }
    } catch (e) {
      print('Erro ao buscar a doação: $e');
      return null;
    }
  }


  Future<void> adicionarDoacao(Doacao doacao) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('tokenJWT');


  try {
    final response = await http.post(
      Uri.parse('https://backend-ong.vercel.app/api/addDoacao'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
       body: jsonEncode(doacao.toJson()),
 
    );
    print('Corpo da requisição: ${jsonEncode(doacao.toJson())}');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');


    if (response.statusCode == 201) {
      buscarDoacoes();
    } else {
      throw Exception('Erro ao adicionar doação: ${response.body}');
    }
  } catch (e) {
    print('Erro ao adicionar doação: $e');
  }
}








 // Função para editar uma doação existente
Future<void> editarDoacao(int index, Doacao doacao) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('tokenJWT');


  try {
    // Cria um mapa com os dados necessários
    final Map<String, dynamic> dadosEditar = {
      'id': doacao.id,            // Inclui o ID no corpo da requisição
      'categoria': doacao.categoria,
      'itemName': doacao.itemName,
    };


    final response = await http.put(
      Uri.parse('https://backend-ong.vercel.app/api/updateDoacao'), // Endpoint sem o ID
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dadosEditar), // Envia os dados no corpo da requisição
    );


    if (response.statusCode == 200) {
      setState(() {
        _doacoes[index] = doacao; // Atualiza a lista localmente
      });
    } else {
      // Exibe status e corpo da resposta para diagnóstico detalhado
      debugPrint(
          'Erro ao editar doação: ${response.statusCode} - ${response.body}');
      throw Exception('Erro ao editar doação');
    }
  } catch (e) {
    print('Erro ao editar doação: $e');
  }
}




  // Função para atualizar a meta de uma doação
  Future<void> atualizarMeta(String id, int novaMeta) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenJWT');


    try {
      final response = await http.patch(
        Uri.parse('https://backend-ong.vercel.app/api/updateMetaInDoacao/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'meta': novaMeta}),
      );


      if (response.statusCode == 200) {
        buscarDoacoes();
      } else {
        throw Exception('Erro ao atualizar meta');
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao atualizar meta: $e');
    }
  }


  // Função para remover uma doação
Future<void> removerDoacao(int index) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('tokenJWT');
  final doacao = _doacoes[index];


  try {
    final response = await http.delete(
      Uri.parse('https://backend-ong.vercel.app/api/deleteDoacao'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': doacao.id,  // Passando o ID da doação no corpo da requisição
      }),
    );


    if (response.statusCode == 200) {
      setState(() {
        _doacoes.removeAt(index);
      });
    } else {
      throw Exception('Erro ao remover doação');
    }
  } catch (e) {
    // ignore: avoid_print
    print('Erro ao remover doação: $e');
  }
}



void _mostrarDialogoEditarDoacao(int index, Doacao doacao) {
  final formKey = GlobalKey<FormState>();
  int id = doacao.id;
  String categoria = doacao.categoria;
  String itemName = doacao.itemName;
  String dataCreated = doacao.dataCreated;
  int quantidade = doacao.quantidade;
  int metaQuantidade = doacao.metaQuantidade;
  String metaDate = doacao.metaDate;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white, // Card branco
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Bordas arredondadas no card
        ),
        title: Text(
          'Editar Doação',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 5, 5, 5), // Cor do título
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ID
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    initialValue: id.toString(),
                    decoration: InputDecoration(
                      labelText: 'ID',
                      labelStyle: TextStyle(color: const Color.fromARGB(255, 16, 70, 114), fontWeight: FontWeight.w600),
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
                    
                    onSaved: (value) => id = int.parse(value!),
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                ),
                // Categoria
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    initialValue: categoria,
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      labelStyle: TextStyle(color: const Color.fromARGB(255, 16, 70, 114), fontWeight: FontWeight.w600),
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
                    onSaved: (value) => categoria = value!,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                ),
                // Item
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    initialValue: itemName,
                    decoration: InputDecoration(
                      labelText: 'Item',
                     labelStyle: TextStyle(color: const Color.fromARGB(255, 16, 70, 114), fontWeight: FontWeight.w600),
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
                    onSaved: (value) => itemName = value!,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                ),
                // Data de Criação
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    initialValue: dataCreated,
                    decoration: InputDecoration(
                      labelText: 'Data de Criação',
                      labelStyle: TextStyle(color: const Color.fromARGB(255, 16, 70, 114), fontWeight: FontWeight.w600),
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
                    onSaved: (value) => dataCreated = value!,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                ),
                // Quantidade
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    initialValue: quantidade.toString(),
                    decoration: InputDecoration(
                      labelText: 'Quantidade',
                      labelStyle: TextStyle(color: const Color.fromARGB(255, 16, 70, 114), fontWeight: FontWeight.w600),
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
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      if (value != null && value.isNotEmpty) {
                        quantidade = int.parse(value);
                      } else {
                        quantidade = 0;
                      }
                    },
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                ),
                // Meta Quantidade
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    initialValue: metaQuantidade.toString(),
                    decoration: InputDecoration(
                      labelText: 'Meta Quantidade',
                    labelStyle: TextStyle(color: const Color.fromARGB(255, 16, 70, 114), fontWeight: FontWeight.w600),
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
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      if (value != null && value.isNotEmpty) {
                        metaQuantidade = int.parse(value);
                      } else {
                        metaQuantidade = 0;
                      }
                    },
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                ),
                // Data Meta
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: TextFormField(
                    initialValue: metaDate,
                    decoration: InputDecoration(
                      labelText: 'Data Meta',
                      labelStyle: TextStyle(color: const Color.fromARGB(255, 16, 70, 114), fontWeight: FontWeight.w600),
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
                    onSaved: (value) => metaDate = value!,
                    validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: const Color.fromARGB(255, 65, 65, 65),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final novaDoacao = Doacao(
                  id: id,
                  categoria: categoria,
                  itemName: itemName,
                  dataCreated: dataCreated,
                  quantidade: quantidade,
                  metaQuantidade: metaQuantidade,
                  metaDate: metaDate,
                );
                // Atualize o item na lista (isto depende de como você gerencia os dados)
                Navigator.pop(context);
              }
            },
            child: Text('Salvar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Cor do botão
              foregroundColor: Colors.white, // Cor do texto
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      );
    },
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(245, 245, 249, 1),
      appBar: CustomAppBar(title: ''),
      body: SingleChildScrollView(
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
                      _buildSearchAndActionBar(),
                      const SizedBox(height: 20),
                      _buildDonationsTable(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Footer(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAdicionarDoacao,
        backgroundColor: const Color.fromARGB(255, 12, 56, 92),
        tooltip: 'Adicionar Doação',
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }


  Widget _buildDonationsTable() {
    return _doacoes.isEmpty
        ? Center(
            child: Text(
              'Nenhuma doação encontrada.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          )
        : Column(
            children: [
              // Container que permite rolagem horizontal
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      return Colors.grey.shade200; // Cor do cabeçalho
                    },
                  ),
                  columns: [
                    DataColumn(
                      label: Text(
                        'ID',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Categoria',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Item',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Data Criação',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Quantidade',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Meta Quantidade',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Data Meta',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Ações',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                  rows: _buildDonationRows(),
                ),
              ),
              // Divider indicativo abaixo da tabela
              const SizedBox(height: 8),
              Divider(
                thickness: 3,
                color: Colors.grey.shade300,
              ),
            ],
          );
  }


  List<DataRow> _buildDonationRows() {
    return List.generate(_doacoesFiltradas.length, (index) {
      final doacao = _doacoesFiltradas[index];
      return DataRow(cells: [
        DataCell(Text(doacao.id.toString())),
        DataCell(Text(doacao.categoria)),
        DataCell(Text(doacao.itemName)),
        DataCell(Text(doacao.dataCreated)),
        DataCell(Text(doacao.quantidade.toString())),
        DataCell(Text(doacao.metaQuantidade.toString())),
        DataCell(Text(doacao.metaDate)),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.green,
                ),
                onPressed: () {
                  _mostrarDialogoEditarDoacao(index, doacao);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: () {
                  removerDoacao(index);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.history,
                  color: const Color.fromARGB(255, 21, 91, 149),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HistoricoDoacoesPage(doacao: doacao),
                    ),
                  );
                },
                tooltip: 'Ver Histórico',
              ),
            ],
          ),
        ),
      ]);
    });
  }


void _mostrarOpcoesFiltro() {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    backgroundColor: Colors.white, // Cor de fundo do BottomSheet
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.white, // Cor de fundo branca para o card
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Bordas arredondadas no card
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opções de Filtro',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),


                // Dropdown para Categoria
                DropdownButtonFormField<String>(
                  value: _categoriaSelecionada,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(255, 100, 100, 100),
                      fontWeight: FontWeight.w500,
                    ), // Cor da label
                    filled: true,
                    fillColor: Colors.grey[200], // Cor de fundo suave
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Bordas arredondadas
                      borderSide: BorderSide(
                        color: _categoriaSelecionada == null
                            ? const Color.fromARGB(255, 200, 200, 200)
                            : Colors.blue, // Borda azul quando selecionado
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Bordas arredondadas
                      borderSide: BorderSide(color: Colors.blue, width: 2), // Borda azul quando o campo estiver em foco
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Bordas arredondadas
                      borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 0), // Borda cinza quando desabilitado
                    ),
                  ),
                  dropdownColor: Colors.white, // Cor de fundo do menu dropdown para branco
                  items: <String>[
                    'Todos',
                    'alimento',
                    'monetario',
                    'mobilia',
                    'outros',
                    'roupa'
                  ].map((String categoria) {
                    return DropdownMenuItem<String>(
                      value: categoria,
                      child: Text(categoria),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _categoriaSelecionada =
                          newValue == 'Todos' ? null : newValue;
                    });
                  },
                ),
                SizedBox(height: 16),


                // Botão de Aplicar Filtro
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _filtrarDoacoes();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Cor do botão
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Bordas arredondadas
                      ),
                    ),
                    child: Text(
                      'Aplicar Filtro',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}






  Widget _buildSearchAndActionBar() {
    return Row(
      children: [
        // Campo de pesquisa com ícone
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Pesquisar Item...',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            ),
            onChanged: _filtrarPorTermoPesquisa,
          ),
        ),
        const SizedBox(width: 8),


        // Botão de Filtro
        ElevatedButton.icon(
          onPressed: _mostrarOpcoesFiltro,
          icon: Icon(Icons.filter_list,
              color: const Color.fromARGB(255, 255, 255, 255)),
          label: Text(
            'Filtro',
            style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }


  void _mostrarDialogoAdicionarDoacao() {
    final formKey = GlobalKey<FormState>();
    String categoria = '', itemName = '', dataCreated = '', metaDate = '';
    int quantidade = 0, metaQuantidade = 0;


   showDialog(
  context: context,
  builder: (BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white, // Card branco
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Bordas arredondadas no card
      ),
      title: Text(
        'Adicionar Doação',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 5, 5, 5), // Cor azul para o título
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Categoria
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  labelStyle: TextStyle(color: const Color.fromARGB(255, 119, 119, 119), fontWeight: FontWeight.w500), // Cor da label
                  fillColor: Colors.grey[200], // Cor de fundo cinza
                  filled: true, // Aplica a cor de fundo
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2), // Borda azul no foco
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 0), // Borda padrão cinza
                  ),
                ),
                onSaved: (value) => categoria = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              SizedBox(height: 12),
              // Item
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Item',
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
                onSaved: (value) => itemName = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              SizedBox(height: 12),
              // Data de Criação
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Data de Criação',
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
                onSaved: (value) => dataCreated = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              SizedBox(height: 12),
              // Quantidade
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Quantidade',
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
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  if (value != null && value.isNotEmpty) {
                    quantidade = int.parse(value);
                  } else {
                    quantidade = 0;
                  }
                },
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              SizedBox(height: 12),
              // Meta Quantidade
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Meta Quantidade',
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
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  if (value != null && value.isNotEmpty) {
                    metaQuantidade = int.parse(value);
                  } else {
                    metaQuantidade = 0;
                  }
                },
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              SizedBox(height: 12),
              // Data Meta
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Data Meta',
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
                onSaved: (value) => metaDate = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Botão Cancelar
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: const Color.fromARGB(255, 65, 65, 65), // Cor do botão cancelar
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Botão Salvar
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              formKey.currentState!.save();
              adicionarDoacao(Doacao(
                id: _doacoes.length + 1,
                categoria: categoria,
                itemName: itemName,
                dataCreated: dataCreated,
                quantidade: quantidade,
                metaQuantidade: metaQuantidade,
                metaDate: metaDate,
              ));
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Cor de fundo do botão
            foregroundColor: Colors.white, // Cor do texto no botão
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Bordas arredondadas
            ),
          ),
          child: Text('Salvar'),
        ),
      ],
    );
  },
);
  }
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



