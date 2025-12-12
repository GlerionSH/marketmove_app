class Venta {
  final int? id;
  final double importe;
  final DateTime? fecha;
  final int? productoId;
  final int cantidad;
  final String? metodoPago;
  final String? comentarios;
  final String? userId;
  final DateTime? createdAt;

  Venta({
    this.id,
    required this.importe,
    this.fecha,
    this.productoId,
    required this.cantidad,
    this.metodoPago,
    this.comentarios,
    this.userId,
    this.createdAt,
  });

  factory Venta.fromJson(Map<String, dynamic> json) {
    return Venta(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      importe: (json['importe'] as num?)?.toDouble() ?? 0.0,
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
      productoId: json['producto_id'] is int 
          ? json['producto_id'] 
          : int.tryParse(json['producto_id']?.toString() ?? ''),
      cantidad: json['cantidad'] ?? 0,
      metodoPago: json['metodo_pago'],
      comentarios: json['comentarios'],
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
      'producto_id': productoId,
      'cantidad': cantidad,
      'metodo_pago': metodoPago,
      'comentarios': comentarios,
      if (userId != null) 'user_id': userId,
    };
  }

  Venta copyWith({
    int? id,
    double? importe,
    DateTime? fecha,
    int? productoId,
    int? cantidad,
    String? metodoPago,
    String? comentarios,
    String? userId,
    DateTime? createdAt,
  }) {
    return Venta(
      id: id ?? this.id,
      importe: importe ?? this.importe,
      fecha: fecha ?? this.fecha,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      metodoPago: metodoPago ?? this.metodoPago,
      comentarios: comentarios ?? this.comentarios,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
