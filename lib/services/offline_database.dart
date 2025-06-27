import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/whitebook_content.dart';

class OfflineDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'whitebook_offline.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE whitebook_content(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        url TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        tags TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color TEXT NOT NULL
      )
    ''');

    // Inserir categorias padrão
    await db.insert('categories', {
      'name': 'Cardiologia',
      'color': '#FF6B6B',
    });
    await db.insert('categories', {
      'name': 'Neurologia',
      'color': '#4ECDC4',
    });
    await db.insert('categories', {
      'name': 'Pneumologia',
      'color': '#45B7D1',
    });
    await db.insert('categories', {
      'name': 'Gastroenterologia',
      'color': '#96CEB4',
    });
    await db.insert('categories', {
      'name': 'Endocrinologia',
      'color': '#FFEAA7',
    });
  }

  // CRUD Operations
  Future<int> insertContent(WhitebookContent content) async {
    final db = await database;
    return await db.insert('whitebook_content', content.toMap());
  }

  Future<List<WhitebookContent>> getAllContent() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('whitebook_content');
    return List.generate(maps.length, (i) => WhitebookContent.fromMap(maps[i]));
  }

  Future<List<WhitebookContent>> getContentByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'whitebook_content',
      where: 'category = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) => WhitebookContent.fromMap(maps[i]));
  }

  Future<List<WhitebookContent>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'whitebook_content',
      where: 'isFavorite = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => WhitebookContent.fromMap(maps[i]));
  }

  Future<List<WhitebookContent>> searchContent(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'whitebook_content',
      where: 'title LIKE ? OR content LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => WhitebookContent.fromMap(maps[i]));
  }

  Future<int> updateContent(WhitebookContent content) async {
    final db = await database;
    return await db.update(
      'whitebook_content',
      content.toMap(),
      where: 'id = ?',
      whereArgs: [content.id],
    );
  }

  Future<int> deleteContent(int id) async {
    final db = await database;
    return await db.delete(
      'whitebook_content',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    final db = await database;
    await db.update(
      'whitebook_content',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => maps[i]['name'] as String);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('whitebook_content');
  }
} 