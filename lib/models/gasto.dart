class Gasto {
  final int? id;
  final double importe;
  final DateTime? fecha;
  final String? categoria;
  final String? metodoPago;
  final String? comentarios;
  final String? imagenUrl;
  final String? userId;
  final DateTime? createdAt;

  Gasto({
    this.id,
    required this.importe,
    this.fecha,
    this.categoria,
    this.metodoPago,
    this.comentarios,
    this.imagenUrl,
    this.userId,
    this.createdAt,
  });

  factory Gasto.fromJson(Map<String, dynamic> json) {
    return Gasto(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      importe: (json['importe'] as num?)?.toDouble() ?? 0.0,
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
      categoria: json['categoria'],
      metodoPago: json['metodo_pago'],
      comentarios: json['comentarios'],
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
      'importe': importe,
      'fecha': fecha?.toIso8601String(),
      'categoria': categoria,
      'metodo_pago': metodoPago,
      'comentarios': comentarios,
      'imagen_url': imagenUrl,
      if (userId != null) 'user_id': userId,
    };
  }

  Gasto copyWith({
    int? id,
    double? importe,
    DateTime? fecha,
    String? categoria,
    String? metodoPago,
    String? comentarios,
    String? imagenUrl,
    String? userId,
    DateTime? createdAt,
  }) {
    return Gasto(
      id: id ?? this.id,
      importe: importe ?? this.importe,
      fecha: fecha ?? this.fecha,
      categoria: categoria ?? this.categoria,
      metodoPago: metodoPago ?? this.metodoPago,
      comentarios: comentarios ?? this.comentarios,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
