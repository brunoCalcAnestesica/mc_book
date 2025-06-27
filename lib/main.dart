import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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
      _statusMessage = 'Preparando acesso...';
    });

    try {
      // Salvar credenciais
      await _saveCredentials();

      // Abrir diretamente no navegador com credenciais
      await _openWhitebookWithCredentials();
      
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro: $e. Tentando abrir no navegador...';
      });
      await _openWhitebookInBrowser();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openWhitebookWithCredentials() async {
    try {
      // Tentar abrir a página principal primeiro
      final mainUrl = Uri.parse('https://whitebook.pebmed.com.br/home/');
      bool launched = false;
      
      try {
        launched = await launchUrl(mainUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        print('Erro ao abrir página principal: $e');
      }
      
      if (launched) {
        setState(() {
          _statusMessage = 'Página principal aberta!';
        });
      } else {
        // Se não conseguir, abrir página de login
        await _openWhitebookInBrowser();
      }
    } catch (e) {
      await _openWhitebookInBrowser();
    }
  }

  Future<void> _openWhitebookInBrowser() async {
    try {
      final url = Uri.parse('https://whitebook.pebmed.com.br/login/');
      
      // Tentar diferentes modos de abertura
      bool launched = false;
      
      // Método 1: Modo externo
      try {
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        print('Erro no modo externo: $e');
      }
      
      // Método 2: Se falhar, tentar modo in-app
      if (!launched) {
        try {
          launched = await launchUrl(url, mode: LaunchMode.inAppWebView);
        } catch (e) {
          print('Erro no modo in-app: $e');
        }
      }
      
      // Método 3: Se ainda falhar, tentar modo padrão
      if (!launched) {
        try {
          launched = await launchUrl(url);
        } catch (e) {
          print('Erro no modo padrão: $e');
        }
      }
      
      if (launched) {
        setState(() {
          _statusMessage = 'Navegador aberto com sucesso!';
        });
      } else {
        setState(() {
          _statusMessage = 'Não foi possível abrir o navegador. Tente copiar o link manualmente.';
        });
        // Copiar URL para área de transferência
        await Clipboard.setData(ClipboardData(text: url.toString()));
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao abrir navegador: $e';
      });
    }
  }

  Future<void> _copyCredentials() async {
    final credentials = 'Email: ${_emailController.text}\nSenha: ${_passwordController.text}';
    await Clipboard.setData(ClipboardData(text: credentials));
    setState(() {
      _statusMessage = 'Credenciais copiadas para a área de transferência!';
    });
    
    // Limpar mensagem após 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  Future<void> _copyEmail() async {
    await Clipboard.setData(ClipboardData(text: _emailController.text));
    setState(() {
      _statusMessage = 'Email copiado!';
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  Future<void> _copyPassword() async {
    await Clipboard.setData(ClipboardData(text: _passwordController.text));
    setState(() {
      _statusMessage = 'Senha copiada!';
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  Future<void> _copyWhitebookLink() async {
    const url = 'https://whitebook.pebmed.com.br/login/';
    await Clipboard.setData(ClipboardData(text: url));
    setState(() {
      _statusMessage = 'Link do Whitebook copiado!';
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  Future<void> _mapWhitebookPage() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Mapeando estrutura da página...';
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
        
        // Mapear estrutura da página
        final pageMap = _createPageMap(document);
        
        setState(() {
          _statusMessage = 'Mapeamento concluído!';
        });

        // Mostrar mapa em um dialog
        _showPageMap(pageMap);
      } else {
        setState(() {
          _statusMessage = 'Erro ao mapear página: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro no mapeamento: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _createPageMap(html.Document document) {
    final map = <String, dynamic>{};
    
    // Informações básicas
    map['title'] = document.querySelector('title')?.text ?? 'Sem título';
    map['language'] = document.querySelector('html')?.attributes['lang'] ?? 'Não especificado';
    
    // Meta tags
    final metaTags = document.querySelectorAll('meta');
    map['meta_tags'] = metaTags.map((tag) {
      return {
        'name': tag.attributes['name'] ?? tag.attributes['property'] ?? 'Sem nome',
        'content': tag.attributes['content'] ?? 'Sem conteúdo',
      };
    }).toList();
    
    // Links
    final links = document.querySelectorAll('a[href]');
    map['links'] = links.map((link) {
      return {
        'text': link.text.trim(),
        'href': link.attributes['href'] ?? '',
        'target': link.attributes['target'] ?? '',
      };
    }).where((link) => link['text'].isNotEmpty).toList();
    
    // Formulários
    final forms = document.querySelectorAll('form');
    map['forms'] = forms.map((form) {
      final inputs = form.querySelectorAll('input');
      final buttons = form.querySelectorAll('button');
      
      return {
        'action': form.attributes['action'] ?? 'Sem action',
        'method': form.attributes['method'] ?? 'GET',
        'inputs': inputs.map((input) {
          return {
            'type': input.attributes['type'] ?? 'text',
            'name': input.attributes['name'] ?? 'Sem nome',
            'id': input.attributes['id'] ?? 'Sem id',
            'placeholder': input.attributes['placeholder'] ?? '',
            'required': input.attributes['required'] != null,
          };
        }).toList(),
        'buttons': buttons.map((button) {
          return {
            'text': button.text.trim(),
            'type': button.attributes['type'] ?? 'button',
          };
        }).toList(),
      };
    }).toList();
    
    // Scripts
    final scripts = document.querySelectorAll('script');
    map['scripts'] = scripts.map((script) {
      return {
        'src': script.attributes['src'] ?? 'Inline script',
        'type': script.attributes['type'] ?? 'text/javascript',
      };
    }).toList();
    
    // Estilos
    final styles = document.querySelectorAll('link[rel="stylesheet"]');
    map['stylesheets'] = styles.map((style) {
      return style.attributes['href'] ?? 'Sem href';
    }).toList();
    
    // Estrutura de seções
    final sections = document.querySelectorAll('section, div, main, header, footer, nav');
    map['sections'] = sections.take(20).map((section) {
      return {
        'tag': section.localName ?? 'div',
        'id': section.attributes['id'] ?? 'Sem id',
        'class': section.attributes['class'] ?? 'Sem classe',
        'text_preview': section.text.length > 50 
            ? '${section.text.substring(0, 50)}...' 
            : section.text,
      };
    }).toList();
    
    // Imagens
    final images = document.querySelectorAll('img');
    map['images'] = images.map((img) {
      return {
        'src': img.attributes['src'] ?? 'Sem src',
        'alt': img.attributes['alt'] ?? 'Sem alt',
        'title': img.attributes['title'] ?? 'Sem title',
      };
    }).toList();
    
    return map;
  }

  void _showPageMap(Map<String, dynamic> pageMap) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mapa da Página do Whitebook'),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapSection('Título', pageMap['title']),
                _buildMapSection('Idioma', pageMap['language']),
                _buildMapSection('Meta Tags', pageMap['meta_tags'], isList: true),
                _buildMapSection('Links', pageMap['links'], isList: true),
                _buildMapSection('Formulários', pageMap['forms'], isList: true),
                _buildMapSection('Scripts', pageMap['scripts'], isList: true),
                _buildMapSection('CSS', pageMap['stylesheets'], isList: true),
                _buildMapSection('Seções', pageMap['sections'], isList: true),
                _buildMapSection('Imagens', pageMap['images'], isList: true),
              ],
            ),
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
              _copyPageMapToClipboard(pageMap);
            },
            child: const Text('Copiar Mapa'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(String title, dynamic data, {bool isList = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (isList && data is List)
          ...data.take(10).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              item.toString(),
              style: const TextStyle(fontSize: 12),
            ),
          ))
        else
          Text(
            data.toString(),
            style: const TextStyle(fontSize: 12),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _copyPageMapToClipboard(Map<String, dynamic> pageMap) async {
    final mapText = _formatPageMapForClipboard(pageMap);
    await Clipboard.setData(ClipboardData(text: mapText));
    setState(() {
      _statusMessage = 'Mapa da página copiado!';
    });
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  String _formatPageMapForClipboard(Map<String, dynamic> pageMap) {
    final buffer = StringBuffer();
    buffer.writeln('=== MAPA DA PÁGINA WHITEBOOK ===');
    buffer.writeln('Título: ${pageMap['title']}');
    buffer.writeln('Idioma: ${pageMap['language']}');
    buffer.writeln();
    
    buffer.writeln('=== META TAGS ===');
    for (final meta in pageMap['meta_tags']) {
      buffer.writeln('${meta['name']}: ${meta['content']}');
    }
    buffer.writeln();
    
    buffer.writeln('=== FORMULÁRIOS ===');
    for (final form in pageMap['forms']) {
      buffer.writeln('Form (${form['method']} -> ${form['action']})');
      for (final input in form['inputs']) {
        buffer.writeln('  - ${input['type']}: ${input['name']} (${input['id']})');
      }
    }
    buffer.writeln();
    
    buffer.writeln('=== LINKS IMPORTANTES ===');
    for (final link in pageMap['links']) {
      if (link['href'].contains('whitebook') || link['text'].isNotEmpty) {
        buffer.writeln('${link['text']}: ${link['href']}');
      }
    }
    
    return buffer.toString();
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyEmail,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copiar Email'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyPassword,
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copiar Senha'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _copyCredentials,
                  icon: const Icon(Icons.copy_all),
                  label: const Text('Copiar Todas as Credenciais'),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.login),
                        label: const Text('Acessar Whitebook'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openWhitebookInBrowser,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.open_in_browser),
                        label: const Text('Abrir no Navegador'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _mapWhitebookPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.map),
                        label: const Text('Mapear Página'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _copyWhitebookLink,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.link),
                        label: const Text('Copiar Link do Whitebook'),
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
