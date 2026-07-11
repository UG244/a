class Product {
  final int? id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stock;
  final String? photoPath;
  final int? supplierId;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  Product({
    this.id,
    required this.name,
    this.description = '',
    required this.category,
    required this.price,
    required this.stock,
    this.photoPath,
    this.supplierId,
    this.isActive = false,
    String? createdAt,
    String? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'stock': stock,
      'photoPath': photoPath,
      'supplierId': supplierId,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: (map['id'] as num?)?.toInt(),
      name: map['name'] as String? ?? '',
      description: (map['description'] as String?) ?? '',
      category: map['category'] as String? ?? 'Umum',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      photoPath: map['photoPath'] as String?,
      supplierId: (map['supplierId'] as num?)?.toInt(),
      isActive: map['isActive'] == 1 || map['isActive'] == true || map['isActive'] == 'true',
      createdAt: map['createdAt'] as String?,
      updatedAt: map['updatedAt'] as String?,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    double? price,
    int? stock,
    String? photoPath,
    int? supplierId,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      photoPath: photoPath ?? this.photoPath,
      supplierId: supplierId ?? this.supplierId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
    );
  }
}
