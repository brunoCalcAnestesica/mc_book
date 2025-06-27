import 'package:flutter/material.dart';
import '../models/whitebook_content.dart';
import '../services/content_sync_service.dart';
import '../services/offline_database.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  final ContentSyncService _syncService = ContentSyncService();
  final OfflineDatabase _database = OfflineDatabase();
  
  List<WhitebookContent> _content = [];
  List<String> _categories = [];
  String _selectedCategory = 'Todos';
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final content = await _syncService.getOfflineContent();
      final categories = await _database.getCategories();
      
      setState(() {
        _content = content;
        _categories = ['Todos', ...categories];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadSampleContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _syncService.downloadSampleContent();
      await _loadContent();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conteúdo de exemplo baixado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao baixar conteúdo: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncFromWeb() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _syncService.syncContentFromWeb();
      await _loadContent();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronização concluída!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na sincronização: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<WhitebookContent> get _filteredContent {
    List<WhitebookContent> filtered = _content;

    // Filtrar por categoria
    if (_selectedCategory != 'Todos') {
      filtered = filtered.where((item) => item.category == _selectedCategory).toList();
    }

    // Filtrar por busca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) =>
        item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (item.tags?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
      ).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Whitebook Offline'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () => _showFavorites(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'download':
                  _downloadSampleContent();
                  break;
                case 'sync':
                  _syncFromWeb();
                  break;
                case 'clear':
                  _clearAllData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Baixar Conteúdo de Exemplo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync),
                    SizedBox(width: 8),
                    Text('Sincronizar da Web'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Limpar Todos os Dados'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar conteúdo...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Filtro de categorias
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de conteúdo
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContent.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredContent.length,
                        itemBuilder: (context, index) {
                          final item = _filteredContent[index];
                          return _buildContentCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.medical_services_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum conteúdo offline encontrado',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Baixe conteúdo de exemplo ou sincronize da web',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _downloadSampleContent,
            icon: const Icon(Icons.download),
            label: const Text('Baixar Conteúdo de Exemplo'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(WhitebookContent content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text(
          content.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              content.content.length > 100
                  ? '${content.content.substring(0, 100)}...'
                  : content.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(content.category),
                  backgroundColor: _getCategoryColor(content.category),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    content.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: content.isFavorite ? Colors.red : null,
                  ),
                  onPressed: () => _toggleFavorite(content),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showContentDetail(content),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Cardiologia':
        return Colors.red[100]!;
      case 'Neurologia':
        return Colors.blue[100]!;
      case 'Pneumologia':
        return Colors.green[100]!;
      case 'Gastroenterologia':
        return Colors.orange[100]!;
      case 'Endocrinologia':
        return Colors.purple[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Future<void> _toggleFavorite(WhitebookContent content) async {
    await _database.toggleFavorite(content.id!, !content.isFavorite);
    await _loadContent();
  }

  void _showContentDetail(WhitebookContent content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(content: content),
      ),
    );
  }

  Future<void> _showFavorites() async {
    final favorites = await _syncService.getFavorites();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FavoritesScreen(favorites: favorites),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Dados'),
        content: const Text('Tem certeza que deseja limpar todos os dados offline?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _database.clearAllData();
      await _loadContent();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados limpos com sucesso!')),
        );
      }
    }
  }
}

class ContentDetailScreen extends StatelessWidget {
  final WhitebookContent content;

  const ContentDetailScreen({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(content.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(content.category),
              backgroundColor: _getCategoryColor(content.category),
            ),
            const SizedBox(height: 16),
            Text(
              content.content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            if (content.tags != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Tags:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: content.tags!.split(', ').map((tag) {
                  return Chip(
                    label: Text(tag.trim()),
                    backgroundColor: Colors.grey[200],
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'URL: ${content.url}',
              style: const TextStyle(color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              'Criado em: ${content.createdAt.toString().split('.')[0]}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Cardiologia':
        return Colors.red[100]!;
      case 'Neurologia':
        return Colors.blue[100]!;
      case 'Pneumologia':
        return Colors.green[100]!;
      case 'Gastroenterologia':
        return Colors.orange[100]!;
      case 'Endocrinologia':
        return Colors.purple[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<WhitebookContent> favorites;

  const FavoritesScreen({super.key, required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: favorites.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum favorito encontrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      item.content.length > 100
                          ? '${item.content.substring(0, 100)}...'
                          : item.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContentDetailScreen(content: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
} 