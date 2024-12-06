import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login.page.dart';
import 'familias.page.dart';
import 'doacoes.page.dart';
import 'dashboard.page.dart';
import 'dart:ui';

class Historico {
  final int id;
  final String data;
  final int qntd;
  final String tipoMov;
  final String doadorName;
  final int doacaoId;  // Campo doacao_id

  Historico({
    required this.id,
    required this.data,
    required this.qntd,
    required this.tipoMov,
    required this.doadorName,
    required this.doacaoId,  // Adicionando o campo doacaoId
  });

  factory Historico.fromJson(Map<String, dynamic> json) {
    return Historico(
      id: json['id'],
      data: json['data'],
      qntd: json['qntd'],
      tipoMov: json['tipoMov'],
      doadorName: json['doadorName'],
      doacaoId: json['doacao_id'],  // Mapeando o campo doacao_id
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'qntd': qntd,
      'tipoMov': tipoMov,
      'doadorName': doadorName,
      'doacao_id': doacaoId,  // Incluindo o campo doacao_id
    };
  }
}

class HistoricoDoacoesPage extends StatefulWidget {
  final Doacao doacao; // Objeto `Doacao` que contém dados da doação

  const HistoricoDoacoesPage({super.key, required this.doacao});

  @override
  _HistoricoDoacoesPageState createState() => _HistoricoDoacoesPageState();
}

class _HistoricoDoacoesPageState extends State<HistoricoDoacoesPage> {
  final TextEditingController metaController = TextEditingController();
  final TextEditingController dataMetaController = TextEditingController();
  double arrecadacaoAtual = 0;
  double metaTotal = 200;
  List<Historico> historicoList = [];

  @override
  void initState() {
    super.initState();
    metaController.text = metaTotal.toString();
    dataMetaController.text = "20, setembro de 2024"; // Exemplo
    _fetchHistorico(); // Carrega o histórico ao inicializar
    _fetchMeta(); // Carrega a meta ao inicializar
  }

  // Função para buscar o histórico do backend
Future<void> _fetchHistorico() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('tokenJWT');

  try {
    final response = await http.post(
      Uri.parse('https://backend-ong.vercel.app/api/getHistoricoByCategoria'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"doacao_id": widget.doacao.id}),
    );

    print('Status Code: ${response.statusCode}'); // Verifique o status code
    print('Response Body: ${response.body}'); // Verifique o corpo da resposta

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        historicoList = data.map((item) => Historico.fromJson(item)).toList();
        arrecadacaoAtual = historicoList.fold(0, (sum, item) => sum + item.qntd);
      });
    } else {
      throw Exception('Erro ao buscar o histórico');
    }
  } catch (e) {
    print('Erro ao buscar o histórico: $e');
  }
}

// Função para buscar a meta fixa da doação
Future<void> _fetchMeta() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('tokenJWT');

  try {
    final response = await http.post(
      Uri.parse('https://backend-ong.vercel.app/api/getMetaFixa'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"id": widget.doacao.id}),
    );

    print('Status Code: ${response.statusCode}'); // Verifique o status code
    print('Response Body: ${response.body}'); // Verifique o corpo da resposta

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        metaTotal = data['qntdMetaAll']?.toDouble() ?? metaTotal;
      });
    } else {
      throw Exception('Erro ao buscar a meta fixa');
    }
  } catch (e) {
    print('Erro ao buscar a meta fixa: $e');
  }
}

  // Função para atualizar a meta da doação
  Future<void> _atualizarMeta() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenJWT');
    final novaMeta = int.tryParse(metaController.text) ?? metaTotal;

    try {
      final response = await http.patch(
        Uri.parse(
            'https://backend-ong.vercel.app/api/updateMetaInDoacao'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "metaQntd": novaMeta,
          "metaDate": dataMetaController.text,
          "doacao_id": widget.doacao.id,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          metaTotal = novaMeta.toDouble();
        });
      } else {
        throw Exception('Erro ao atualizar a meta');
      }
    } catch (e) {
      print('Erro ao atualizar a meta: $e');
    }
  }

  // Função para atualizar a meta fixa
  Future<void> _atualizarMetaFixa() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenJWT');
    final nome = widget.doacao.itemName;
    final novaMetaTotal = int.tryParse(metaController.text) ?? metaTotal;

    try {
      final response = await http.patch(
        Uri.parse(
            'https://backend-ong.vercel.app/api/updateMetaFixa'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "id": widget.doacao.id,
          "nome": nome,
          "qntdMetaAll": novaMetaTotal,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          metaTotal = novaMetaTotal.toDouble();
        });
      } else {
        throw Exception('Erro ao atualizar a meta fixa');
      }
    } catch (e) {
      print('Erro ao atualizar a meta fixa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double porcentagemArrecadada = (arrecadacaoAtual / metaTotal) * 100;

    return Scaffold(
      backgroundColor: Color.fromRGBO(245, 245, 249, 1),
      appBar: CustomAppBar(title: ''),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  textStyle: TextStyle(color: Colors.white),
                ),
                child: Text(
                  'Voltar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),

              // Dados da Doação
              _buildDadosDoacaoSection(),

              const SizedBox(height: 24),

              // Meta da Doação
              _buildMetaDoacaoSection(porcentagemArrecadada),

              const SizedBox(height: 24),

              // Histórico de Movimentações
              _buildHistoricoMovimentacoes(),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildDadosDoacaoSection() {
  return Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0.5,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados da Doação',
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.doacao.itemName,  // Exibindo nome do item
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.category, color: const Color.fromARGB(255, 0, 80, 145)),
              const SizedBox(width: 8),
              Text('Categoria: ${widget.doacao.categoria}'),  // Exibindo categoria
            ],
          ),
          const SizedBox(height: 8),
          // Aqui vamos remover qualquer referência a 'descricao' que não existe
          Text('Meta total: R\$ ${metaTotal.toStringAsFixed(2)}'),
        ],
      ),
    ),
  );
}


Widget _buildMetaDoacaoSection(double porcentagemArrecadada) {
  return Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0.5,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Meta de arrecadação',
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Meta total: ',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'R\$ ${metaTotal.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Arrecadado: R\$ ${arrecadacaoAtual.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: porcentagemArrecadada / 100,
            color: Colors.blue,
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(height: 8),
          Text(
            '${porcentagemArrecadada.toStringAsFixed(2)}% da meta alcançada',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    ),
  );
}

Widget _buildHistoricoMovimentacoes() {
  return Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0.5,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histórico de Movimentações',
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0),
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            itemCount: historicoList.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final historico = historicoList[index];
              return ListTile(
                title: Text(historico.doadorName),
                subtitle: Text(historico.tipoMov),
                trailing: Text('R\$ ${historico.qntd}'),
              );
            },
          ),
        ],
      ),
    ),
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
