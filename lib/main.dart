import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WhitebookApp());
}

class WhitebookApp extends StatelessWidget {
  const WhitebookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MC Book - Whitebook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('email') ?? 'bhdaroz@gmail.com';
      _passwordController.text = prefs.getString('password') ?? 'Facafaca1012@';
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', _emailController.text);
    await prefs.setString('password', _passwordController.text);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Fazendo login...';
    });

    try {
      // Salvar credenciais
      await _saveCredentials();

      // Tentar acessar a página de login
      final response = await http.get(
        Uri.parse('https://whitebook.pebmed.com.br/login/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = 'Página acessada com sucesso!';
        });
        
        // Abrir a página no navegador
        await _openWhitebookInBrowser();
      } else {
        setState(() {
          _statusMessage = 'Erro ao acessar a página: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openWhitebookInBrowser() async {
    final url = Uri.parse('https://whitebook.pebmed.com.br/login/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      setState(() {
        _statusMessage = 'Não foi possível abrir o navegador';
      });
    }
  }

  Future<void> _extractPageInfo() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Extraindo informações...';
    });

    try {
      final response = await http.get(
        Uri.parse('https://whitebook.pebmed.com.br/login/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final document = html.parse(response.body);
        
        // Extrair título da página
        final title = document.querySelector('title')?.text ?? 'Título não encontrado';
        
        // Extrair meta tags
        final metaTags = document.querySelectorAll('meta');
        final metaInfo = metaTags.map((tag) {
          final name = tag.attributes['name'] ?? tag.attributes['property'] ?? '';
          final content = tag.attributes['content'] ?? '';
          return '$name: $content';
        }).where((info) => info.isNotEmpty).toList();

        setState(() {
          _statusMessage = 'Informações extraídas:\nTítulo: $title\nMeta tags: ${metaInfo.length} encontradas';
        });

        // Mostrar detalhes em um dialog
        _showExtractedInfo(title, metaInfo);
      } else {
        setState(() {
          _statusMessage = 'Erro ao extrair informações: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro na extração: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showExtractedInfo(String title, List<String> metaInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações Extraídas'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Título: $title'),
              const SizedBox(height: 16),
              const Text('Meta Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...metaInfo.map((info) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(info, style: const TextStyle(fontSize: 12)),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MC Book - Whitebook'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.medical_services,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Whitebook PEBMED',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua senha';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Fazer Login'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _extractPageInfo,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Extrair Informações da Página'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              if (_statusMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
