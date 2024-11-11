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


class Historico {
  final int id;
  final String data;
  final int qntd;
  final String tipoMov;
  final String doadorName;

  Historico({
    required this.id,
    required this.data,
    required this.qntd,
    required this.tipoMov,
    required this.doadorName,
  });

  factory Historico.fromJson(Map<String, dynamic> json) {
    return Historico(
      id: json['id'],
      data: json['data'],
      qntd: json['qntd'],
      tipoMov: json['tipoMov'],
      doadorName: json['doadorName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'qntd': qntd,
      'tipoMov': tipoMov,
      'doadorName': doadorName,
    };
  }
}

class HistoricoDoacoesPage extends StatefulWidget {
  final Doacao doacao; // Objeto `Doacao` que contém dados da doação

  const HistoricoDoacoesPage({Key? key, required this.doacao})
      : super(key: key);

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

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          historicoList = data.map((item) => Historico.fromJson(item)).toList();
          arrecadacaoAtual =
              historicoList.fold(0, (sum, item) => sum + item.qntd);
        });
      } else {
        throw Exception('Erro ao buscar o histórico');
      }
    } catch (e) {
      print('Erro ao buscar o histórico: $e');
    }
  }

  // Função para atualizar a meta no backend
  Future<void> _atualizarMeta() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenJWT');
    final novaMeta = int.tryParse(metaController.text) ?? metaTotal;

    try {
      final response = await http.patch(
        Uri.parse(
            'https://backend-ong.vercel.app/api/updateMetaInDoacao/${widget.doacao.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"meta": novaMeta}),
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

  // Função para adicionar novo histórico
  Future<void> _adicionarHistorico(Historico historico) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenJWT');

    try {
      final response = await http.post(
        Uri.parse('https://backend-ong.vercel.app/api/addHistorico'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(historico.toJson()),
      );

      if (response.statusCode == 201) {
        _fetchHistorico(); // Recarrega o histórico
      } else {
        throw Exception('Erro ao adicionar histórico');
      }
    } catch (e) {
      print('Erro ao adicionar histórico: $e');
    }
  }

  // Função para remover histórico
  Future<void> _removerHistorico(int historicoId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenJWT');

    try {
      final response = await http.delete(
        Uri.parse(
            'https://backend-ong.vercel.app/api/deleteSingleHistorico/$historicoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _fetchHistorico(); // Recarrega o histórico
      } else {
        throw Exception('Erro ao remover histórico');
      }
    } catch (e) {
      print('Erro ao remover histórico: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double porcentagemArrecadada = (arrecadacaoAtual / metaTotal) * 100;

    return Scaffold(
      backgroundColor: Color.fromRGBO(245, 245, 249, 1),
      appBar: CustomAppBar(title: ''),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dados da Doação',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.doacao.itemName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Categoria: ${widget.doacao.categoria}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.inventory, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Quantidade: ${widget.doacao.quantidade}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaDoacaoSection(double porcentagemArrecadada) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meta da Doação',
              style: TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Arrecadação Atual',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${arrecadacaoAtual.toInt()} / ${metaTotal.toInt()}',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${porcentagemArrecadada.toStringAsFixed(1)}% da meta total',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Gráfico Circular de Meta
            Center(
              child: SizedBox(
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
                            value: porcentagemArrecadada,
                            color: Colors.blue,
                            radius: 18,
                            title: '',
                          ),
                          PieChartSectionData(
                            value: 100 - porcentagemArrecadada,
                            color: Colors.grey.shade200,
                            radius: 18,
                            title: '',
                          ),
                        ],
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${porcentagemArrecadada.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
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
            ),
            const SizedBox(height: 16),

            // Configurar Meta
            Text(
              'Configurar Meta',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: metaController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nova Meta',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue),
                  onPressed: _atualizarMeta,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dataMetaController,
              decoration: InputDecoration(
                labelText: 'Data Meta',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricoMovimentacoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: historicoList
          .map((historico) => ListTile(
                title: Text(historico.tipoMov),
                subtitle: Text(
                    'Doador: ${historico.doadorName} - Quantidade: ${historico.qntd}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removerHistorico(historico.id),
                ),
              ))
          .toList(),
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


