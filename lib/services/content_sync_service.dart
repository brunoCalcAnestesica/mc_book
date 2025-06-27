import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import '../models/whitebook_content.dart';
import 'offline_database.dart';

class ContentSyncService {
  final OfflineDatabase _database = OfflineDatabase();

  Future<List<WhitebookContent>> downloadSampleContent() async {
    final sampleContent = [
      WhitebookContent(
        title: 'Infarto Agudo do Miocárdio',
        content: '''
# Infarto Agudo do Miocárdio (IAM)

## Definição
O infarto agudo do miocárdio é a morte de células do músculo cardíaco devido à interrupção do fluxo sanguíneo para uma área do coração.

## Sinais e Sintomas
- Dor torácica intensa e prolongada
- Sudorese fria
- Náuseas e vômitos
- Dispneia
- Ansiedade e agitação

## Diagnóstico
- ECG: Elevação do segmento ST
- Troponina elevada
- CK-MB elevada

## Tratamento
- Aspirina 300mg
- Nitrato sublingual
- Morfina se necessário
- Reprefusão (trombolítico ou angioplastia)
        ''',
        category: 'Cardiologia',
        url: 'https://whitebook.pebmed.com.br/cardiologia/infarto-agudo-miocardio',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: 'IAM, cardiologia, emergência, dor torácica',
      ),
      WhitebookContent(
        title: 'Acidente Vascular Cerebral',
        content: '''
# Acidente Vascular Cerebral (AVC)

## Definição
Interrupção do fluxo sanguíneo para o cérebro, causando morte das células cerebrais.

## Tipos
- AVC Isquêmico (80% dos casos)
- AVC Hemorrágico (20% dos casos)

## Sinais e Sintomas
- Assimetria facial
- Fraqueza em um lado do corpo
- Dificuldade na fala
- Alteração visual
- Cefaleia súbita e intensa

## Diagnóstico
- Tomografia computadorizada
- Ressonância magnética
- Exames laboratoriais

## Tratamento
- AVC Isquêmico: tPA endovenoso
- AVC Hemorrágico: controle da pressão arterial
- Reabilitação precoce
        ''',
        category: 'Neurologia',
        url: 'https://whitebook.pebmed.com.br/neurologia/avc',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: 'AVC, neurologia, emergência, derrame',
      ),
      WhitebookContent(
        title: 'Pneumonia Comunitária',
        content: '''
# Pneumonia Comunitária

## Definição
Infecção aguda do parênquima pulmonar adquirida fora do ambiente hospitalar.

## Sinais e Sintomas
- Febre
- Tosse produtiva
- Dispneia
- Dor torácica pleurítica
- Fadiga e mal-estar

## Diagnóstico
- Radiografia de tórax
- Hemograma completo
- Hemocultura
- Cultura de escarro

## Tratamento
- Antibioticoterapia empírica
- Hidratação
- Oxigenoterapia se necessário
- Fisioterapia respiratória
        ''',
        category: 'Pneumologia',
        url: 'https://whitebook.pebmed.com.br/pneumologia/pneumonia-comunitaria',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: 'pneumonia, pneumologia, infecção, antibiótico',
      ),
      WhitebookContent(
        title: 'Diabetes Mellitus Tipo 2',
        content: '''
# Diabetes Mellitus Tipo 2

## Definição
Doença metabólica caracterizada por hiperglicemia crônica devido à resistência à insulina.

## Sinais e Sintomas
- Poliúria
- Polidipsia
- Polifagia
- Perda de peso
- Fadiga
- Visão turva

## Diagnóstico
- Glicemia de jejum ≥ 126 mg/dL
- Glicemia pós-prandial ≥ 200 mg/dL
- Hemoglobina glicada ≥ 6.5%

## Tratamento
- Dieta e exercícios
- Metformina
- Sulfonilureias
- Insulina se necessário
- Monitorização glicêmica
        ''',
        category: 'Endocrinologia',
        url: 'https://whitebook.pebmed.com.br/endocrinologia/diabetes-tipo-2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: 'diabetes, endocrinologia, glicemia, insulina',
      ),
    ];

    // Salvar no banco de dados
    for (final content in sampleContent) {
      await _database.insertContent(content);
    }

    return sampleContent;
  }

  Future<void> syncContentFromWeb() async {
    try {
      // Tentar acessar páginas do Whitebook e extrair conteúdo
      final urls = [
        'https://whitebook.pebmed.com.br/cardiologia',
        'https://whitebook.pebmed.com.br/neurologia',
        'https://whitebook.pebmed.com.br/pneumologia',
      ];

      for (final url in urls) {
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            },
          );

          if (response.statusCode == 200) {
            final document = html.parse(response.body);
            
            // Extrair títulos e conteúdo
            final titles = document.querySelectorAll('h1, h2, h3');
            final content = document.querySelectorAll('p, div');
            
            // Criar conteúdo offline
            for (final title in titles.take(5)) {
              final contentText = content.take(3).map((e) => e.text).join('\n');
              
              final whitebookContent = WhitebookContent(
                title: title.text.trim(),
                content: contentText,
                category: _extractCategoryFromUrl(url),
                url: url,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              await _database.insertContent(whitebookContent);
            }
          }
        } catch (e) {
          print('Erro ao sincronizar $url: $e');
        }
      }
    } catch (e) {
      print('Erro na sincronização: $e');
    }
  }

  String _extractCategoryFromUrl(String url) {
    if (url.contains('cardiologia')) return 'Cardiologia';
    if (url.contains('neurologia')) return 'Neurologia';
    if (url.contains('pneumologia')) return 'Pneumologia';
    if (url.contains('gastroenterologia')) return 'Gastroenterologia';
    if (url.contains('endocrinologia')) return 'Endocrinologia';
    return 'Geral';
  }

  Future<List<WhitebookContent>> searchOfflineContent(String query) async {
    return await _database.searchContent(query);
  }

  Future<List<WhitebookContent>> getOfflineContent() async {
    return await _database.getAllContent();
  }

  Future<List<WhitebookContent>> getOfflineContentByCategory(String category) async {
    return await _database.getContentByCategory(category);
  }

  Future<List<WhitebookContent>> getFavorites() async {
    return await _database.getFavorites();
  }
} 