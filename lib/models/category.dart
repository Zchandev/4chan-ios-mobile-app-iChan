class Category {
  const Category(this.name, this.boards);

  factory Category.fromMap(Map<String, dynamic> json) {
    return Category(
      json['name'] as String,
      json,
    );
  }

  final String name;
  final Map<String, dynamic> boards;
}

// Category => Board
