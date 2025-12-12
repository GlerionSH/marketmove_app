class Producto {
  final int? id;
  final String nombre;
  final double precio;
  final int stock;
  final String? categoria;
  final String? codigoBarras;
  final String? imagenUrl;
  final String? userId;
  final DateTime? createdAt;

  Producto({
    this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
    this.categoria,
    this.codigoBarras,
    this.imagenUrl,
    this.userId,
    this.createdAt,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      nombre: json['nombre'] ?? '',
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] ?? 0,
      categoria: json['categoria'],
      codigoBarras: json['codigo_barras'],
      imagenUrl: json['imagen_url'],
      userId: json['user_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'precio': precio,
      'stock': stock,
      'categoria': categoria,
      'codigo_barras': codigoBarras,
      'imagen_url': imagenUrl,
      if (userId != null) 'user_id': userId,
    };
  }

  Producto copyWith({
    int? id,
    String? nombre,
    double? precio,
    int? stock,
    String? categoria,
    String? codigoBarras,
    String? imagenUrl,
    String? userId,
    DateTime? createdAt,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      precio: precio ?? this.precio,
      stock: stock ?? this.stock,
      categoria: categoria ?? this.categoria,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
