class WhitebookContent {
  final int? id;
  final String title;
  final String content;
  final String category;
  final String url;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final String? tags;

  WhitebookContent({
    this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.url,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'url': url,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isFavorite': isFavorite ? 1 : 0,
      'tags': tags,
    };
  }

  factory WhitebookContent.fromMap(Map<String, dynamic> map) {
    return WhitebookContent(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      category: map['category'],
      url: map['url'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      isFavorite: map['isFavorite'] == 1,
      tags: map['tags'],
    );
  }

  WhitebookContent copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    String? url,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    String? tags,
  }) {
    return WhitebookContent(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      url: url ?? this.url,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
    );
  }
} 