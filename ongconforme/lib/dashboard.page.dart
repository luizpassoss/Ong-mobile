import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'login.page.dart';
import 'familias.page.dart';
import 'doacoes.page.dart';
import 'dart:ui';

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



class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int arrecadacaoTotal = 400;
  int metaTotal = 100;
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
    final response = await http.post(
      Uri.parse('https://backend-ong.vercel.app/api/getMetaFixa'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': 34,  // Passando o ID no corpo da requisição
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data.isNotEmpty) {
        final item = data[0];

        setState(() {
          metaTotal = item['qntdMetaAll']?.toInt() ?? metaTotal;
        });
      } else {
        print('Lista de dados vazia');
      }
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
  void _editarArrecadacao(BuildContext context) {
  TextEditingController controller = TextEditingController(text: arrecadacaoTotal.toString());

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white, // Card branco
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Bordas arredondadas no card
        ),
        title: Text(
          'Editar Arrecadação',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 5, 5, 5), // Cor azul para o título
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Novo valor de arrecadação
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Novo valor',
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
                validator: (value) =>
                    value!.isEmpty ? 'Campo obrigatório' : null,
              ),
            ],
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
              setState(() {
                arrecadacaoTotal = int.tryParse(controller.text) ?? arrecadacaoTotal;
              });
              Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(245, 245, 249, 1),
      appBar: CustomAppBar(title: ''),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
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
      color: const Color.fromARGB(255, 255, 255, 255),
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
                        IconButton(
                icon: Icon(Icons.edit, color: Colors.blue, ),
                onPressed: () => _editarArrecadacao(context),
                splashColor: Colors.blue.withOpacity(0.1),
                
              ),
            
          
                      const SizedBox(height: 1),
                      Text(
                        '${porcentagemArrecadada.toStringAsFixed(1)}% da meta',
                        style: TextStyle(
                          color: porcentagemArrecadada >= 100
                              ? Colors.green
                              : Colors.red,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Meta: ${metaTotal.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(42, 48, 66, 1.0),
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

  // Defina a lista manual de meses
final List<String> meses = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
];

String formatarDataManual(String dateString) {
  // Parse a data
  DateTime date = DateTime.parse(dateString);

  // Use a lista de meses manual para substituir o mês
  String mes = meses[date.month - 1]; // Ajuste porque DateTime começa a contagem de meses a partir de 1

  // Formate a data com o mês manual
  return '${date.day} de $mes de ${date.year}';
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
                      formatarDataManual(atividade["date"] ??
                          '0000-00-00'), 
                      atividade["activity"] ?? '',
                    )),

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
