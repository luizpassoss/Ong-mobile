import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import 'login.page.dart';
import 'familias.page.dart';
import 'doacoes.page.dart';

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

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double arrecadacaoTotal = 0.0;
  double metaTotal = 5000.0; // Meta total para ser obtida dinamicamente
  List<Map<String, String>> atividadesRecentes = [];
  bool isLoading = true;
  bool verMais = false; // Variável para controlar a exibição expandida

  @override
  void initState() {
    super.initState();
    _carregarDadosDashboard();
  }

  Future<void> _carregarDadosDashboard() async {
    await _obterArrecadacaoTotal();
    await _obterAtividadesRecentes();
    setState(() {
      isLoading = false;
    });
  }

  // Função para obter a arrecadação total e a meta
  Future<void> _obterArrecadacaoTotal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenJWT');

    try {
      final response = await http.get(
        Uri.parse('https://backend-ong.vercel.app/api/getMetaFixa'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          arrecadacaoTotal = data['arrecadacaoAtual'] ?? 0.0;
          metaTotal = data['meta'] ?? metaTotal;
        });
      } else {
        print('Erro ao obter meta fixa: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao conectar à API de meta fixa: $e');
    }
  }

  // Função para obter atividades recentes
  Future<void> _obterAtividadesRecentes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenJWT');

    try {
      final response = await http.get(
        Uri.parse('https://backend-ong.vercel.app/api/getHistorico'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          atividadesRecentes = data
              .map((item) {
                return {
                  "date": (item['data'] ?? 'Data desconhecida').toString(),
                  "activity":
                      '${item['doadorName']} doou ${item['qntd']} ${item['itemName'] ?? ''}'
                };
              })
              .toList()
              .cast<
                  Map<String,
                      String>>(); // Converte para List<Map<String, String>>
        });
      } else {
        print('Erro ao obter histórico de atividades: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao conectar à API de atividades recentes: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tokenJWT');
    await prefs.remove('manterConectado');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginFormPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(245, 245, 249, 1),
      appBar: CustomAppBar(title: ''),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
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
    double porcentagemArrecadada = (arrecadacaoTotal / metaTotal) * 100;

    return Card(
      elevation: 0.5,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
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
                    children: [
                      Text(
                        'R\$${arrecadacaoTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(42, 48, 66, 1.0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${porcentagemArrecadada.toStringAsFixed(1)}% da meta',
                        style: TextStyle(
                          color: porcentagemArrecadada >= 100
                              ? Colors.green
                              : Colors.red,
                          fontSize: 14,
                        ),
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
                                    value: porcentagemArrecadada,
                                    color: const Color(0xFF51B0FE),
                                    radius: 18,
                                    title: '',
                                  ),
                                  PieChartSectionData(
                                    value: 100 - porcentagemArrecadada,
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
                              children: [
                                Text(
                                  '${porcentagemArrecadada.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 14,
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
    // Definir o número de atividades a serem exibidas inicialmente
    int limiteInicial = 3;
    List<Map<String, String>> atividadesExibidas = verMais
        ? atividadesRecentes
        : atividadesRecentes.take(limiteInicial).toList();

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
          elevation: 0.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Lista de atividades
                ...atividadesExibidas.map((atividade) => _buildRecentActivity(
                    atividade["date"]!, atividade["activity"]!)),

                // Botão "Veja Mais"
                if (atividadesRecentes.length > limiteInicial)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        verMais = !verMais;
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue, // Cor de fundo
                      foregroundColor:
                          Colors.white, // Cor do texto (substitui `primary`)
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(8), // Bordas arredondadas
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: 6, horizontal: 14), // Padding
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Ver Mais',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward, color: Colors.white),
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
              // Ícone de círculo com borda
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

          // Data e seta
          Row(
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(42, 48, 66, 1.0),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, color: Colors.grey, size: 14),
            ],
          ),

          const SizedBox(width: 8),

          // Texto da atividade
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


