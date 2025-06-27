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

      // Tentar diferentes métodos de login
      bool loginSuccess = false;
      
      // Método 1: Login direto via POST
      loginSuccess = await _tryDirectLogin();
      
      // Método 2: Se falhar, tentar via API
      if (!loginSuccess) {
        loginSuccess = await _tryApiLogin();
      }
      
      // Método 3: Se ainda falhar, abrir no navegador
      if (!loginSuccess) {
        setState(() {
          _statusMessage = 'Abrindo no navegador para login manual...';
        });
        await _openWhitebookInBrowser();
      }
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro: $e. Abrindo no navegador...';
      });
      await _openWhitebookInBrowser();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _tryDirectLogin() async {
    try {
      // Primeiro, acessar a página de login para obter cookies e tokens
      final loginPageResponse = await http.get(
        Uri.parse('https://whitebook.pebmed.com.br/login/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        },
      );

      if (loginPageResponse.statusCode == 200) {
        // Extrair cookies da resposta
        final cookies = loginPageResponse.headers['set-cookie'];
        
        // Tentar fazer login POST
        final loginResponse = await http.post(
          Uri.parse('https://whitebook.pebmed.com.br/login/'),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
            'Content-Type': 'application/x-www-form-urlencoded',
            'Origin': 'https://whitebook.pebmed.com.br',
            'Referer': 'https://whitebook.pebmed.com.br/login/',
            'Cookie': cookies ?? '',
          },
          body: {
            'email': _emailController.text,
            'password': _passwordController.text,
            'remember': 'true',
          },
        );

        if (loginResponse.statusCode == 200 || loginResponse.statusCode == 302) {
          setState(() {
            _statusMessage = 'Login realizado com sucesso! Redirecionando...';
          });
          
          // Tentar acessar a página principal após login
          await _accessMainPage(cookies);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _tryApiLogin() async {
    try {
      // Tentar login via API endpoint
      final response = await http.post(
        Uri.parse('https://whitebook.pebmed.com.br/api/auth/login'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Origin': 'https://whitebook.pebmed.com.br',
          'Referer': 'https://whitebook.pebmed.com.br/login/',
        },
        body: {
          'email': _emailController.text,
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = 'Login via API realizado com sucesso!';
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _accessMainPage(String? cookies) async {
    try {
      final response = await http.get(
        Uri.parse('https://whitebook.pebmed.com.br/home/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
          'Cookie': cookies ?? '',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = 'Acesso à página principal realizado!';
        });
        
        // Extrair informações da página principal
        await _extractMainPageInfo(response.body);
      } else {
        setState(() {
          _statusMessage = 'Erro ao acessar página principal: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao acessar página principal: $e';
      });
    }
  }

  Future<void> _extractMainPageInfo(String htmlContent) async {
    try {
      final document = html.parse(htmlContent);
      
      // Extrair informações da página principal
      final title = document.querySelector('title')?.text ?? 'Título não encontrado';
      final mainContent = document.querySelector('main')?.text ?? 'Conteúdo principal não encontrado';
      
      // Extrair links importantes
      final links = document.querySelectorAll('a[href]');
      final importantLinks = links
          .where((link) => link.attributes['href']!.contains('whitebook'))
          .map((link) => '${link.text}: ${link.attributes['href']}')
          .take(10)
          .toList();

      setState(() {
        _statusMessage = 'Informações extraídas da página principal!';
      });

      // Mostrar informações em um dialog
      _showMainPageInfo(title, mainContent, importantLinks);
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao extrair informações: $e';
      });
    }
  }

  void _showMainPageInfo(String title, String content, List<String> links) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações da Página Principal'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Título: $title'),
              const SizedBox(height: 16),
              const Text('Links Importantes:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...links.map((link) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(link, style: const TextStyle(fontSize: 12)),
              )),
              const SizedBox(height: 16),
              const Text('Conteúdo Principal:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                content.length > 200 ? '${content.substring(0, 200)}...' : content,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openWhitebookInBrowser();
            },
            child: const Text('Abrir no Navegador'),
          ),
        ],
      ),
    );
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

  Future<void> _extractLoginPageInfo() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Extraindo informações da página de login...';
    });

    try {
      final response = await http.get(
        Uri.parse('https://whitebook.pebmed.com.br/login/'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
          'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
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

        // Extrair formulários
        final forms = document.querySelectorAll('form');
        final formInfo = forms.map((form) {
          final action = form.attributes['action'] ?? 'Sem action';
          final method = form.attributes['method'] ?? 'GET';
          final inputs = form.querySelectorAll('input');
          final inputInfo = inputs.map((input) {
            final type = input.attributes['type'] ?? 'text';
            final name = input.attributes['name'] ?? 'Sem nome';
            return '$type: $name';
          }).toList();
          return 'Form ($method -> $action): ${inputInfo.join(', ')}';
        }).toList();

        setState(() {
          _statusMessage = 'Informações extraídas com sucesso!';
        });

        // Mostrar detalhes em um dialog
        _showLoginPageInfo(title, metaInfo, formInfo);
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

  void _showLoginPageInfo(String title, List<String> metaInfo, List<String> formInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações da Página de Login'),
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
              const SizedBox(height: 16),
              const Text('Formulários:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...formInfo.map((form) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(form, style: const TextStyle(fontSize: 12)),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openWhitebookInBrowser();
            },
            child: const Text('Abrir no Navegador'),
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
                        onPressed: _extractLoginPageInfo,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Extrair Informações da Página de Login'),
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
