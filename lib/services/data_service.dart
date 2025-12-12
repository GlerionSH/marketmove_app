import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marketmove_app/models/producto.dart';
import 'package:marketmove_app/models/venta.dart';
import 'package:marketmove_app/models/gasto.dart';
import 'package:marketmove_app/services/session_service.dart';

class DataService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Helper method to get uid and check if should use global view
  /// Returns (uid, useGlobal) - throws if uid is null and not global view
  /// 
  /// LÓGICA DE ROLES:
  /// - USER → solo ve sus propios datos (useGlobal = false)
  /// - ADMIN → solo ve sus propios datos (useGlobal = false)  
  /// - SUPERADMIN → puede elegir entre ver todo o solo lo suyo
  static Future<(String?, bool)> _getQueryContext() async {
    final uid = await SessionService.getUserId();
    final role = await SessionService.getRole();
    
    // Usar shouldUseGlobalView() que ya verifica si es superadmin Y si tiene el toggle activado
    final useGlobal = await SessionService.shouldUseGlobalView();
    
    print("═══════════════════════════════════════════════════════════");
    print("DataService._getQueryContext()");
    print("  → user_id: $uid");
    print("  → role: $role");
    print("  → useGlobal: $useGlobal");
    print("═══════════════════════════════════════════════════════════");
    
    // Si NO usamos vista global y uid es null, es un ERROR crítico
    if (!useGlobal && uid == null) {
      print("❌ ERROR CRÍTICO: uid es NULL y no estamos en vista global");
      print("❌ Esto significa que SessionService.saveSession() no guardó el user_id");
      throw Exception("ERROR: uid is null → SessionService.saveSession no funciona correctamente");
    }
    
    return (uid, useGlobal);
  }
  
  /// Helper para obtener el user_id para INSERTs (siempre requerido)
  static Future<String> _getUserIdForInsert() async {
    final uid = await SessionService.getUserId();
    
    print("═══════════════════════════════════════════════════════════");
    print("DataService._getUserIdForInsert()");
    print("  → user_id: $uid");
    print("═══════════════════════════════════════════════════════════");
    
    if (uid == null) {
      print("❌ ERROR CRÍTICO: No se puede insertar sin user_id");
      throw Exception("ERROR: uid is null → No se puede crear registro sin user_id");
    }
    
    return uid;
  }

  // ==================== PRODUCTOS ====================

  /// Get productos - superadmin con vista global ve todos; otros solo los suyos
  static Future<List<Producto>> getProductos({bool globalView = false}) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getProductos()                              │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> response;
    if (useGlobal) {
      print("│ Query: SELECT * FROM productos ORDER BY id DESC");
      print("│ (Sin filtro por user_id - vista global)");
      response = await _client
          .from('productos')
          .select()
          .order('id', ascending: false);
    } else {
      print("│ Query: SELECT * FROM productos WHERE user_id = '$uid' ORDER BY id DESC");
      response = await _client
          .from('productos')
          .select()
          .eq('user_id', uid!)
          .order('id', ascending: false);
    }
    
    print("│ Resultado: ${response.length} productos encontrados");
    print("└─────────────────────────────────────────────────────────┘");
    return (response).map((e) => Producto.fromJson(e)).toList();
  }

  static Future<Producto?> getProducto(int id) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getProducto(id: $id)");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    Map<String, dynamic>? response;
    if (useGlobal) {
      print("│ Query: SELECT * FROM productos WHERE id = $id");
      response = await _client
          .from('productos')
          .select()
          .eq('id', id)
          .maybeSingle();
    } else {
      print("│ Query: SELECT * FROM productos WHERE id = $id AND user_id = '$uid'");
      response = await _client
          .from('productos')
          .select()
          .eq('id', id)
          .eq('user_id', uid!)
          .maybeSingle();
    }
    
    print("│ Resultado: ${response != null ? 'Encontrado' : 'No encontrado'}");
    print("└─────────────────────────────────────────────────────────┘");
    
    if (response == null) return null;
    return Producto.fromJson(response);
  }

  static Future<Producto?> createProducto(Producto producto) async {
    final uid = await _getUserIdForInsert();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.createProducto()                            │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id para INSERT: $uid");

    final data = producto.toJson();
    data['user_id'] = uid;  // ⚠️ CRÍTICO: Siempre incluir user_id
    data.remove('id');
    
    print("│ Query: INSERT INTO productos (nombre, precio, stock, categoria, codigo_barras, user_id)");
    print("│ Datos: ${data.toString()}");

    final response = await _client
        .from('productos')
        .insert(data)
        .select()
        .maybeSingle();

    if (response == null) {
      print("│ ❌ ERROR: No se pudo crear el producto");
      print("└─────────────────────────────────────────────────────────┘");
      return null;
    }

    print("│ ✅ Producto creado con id: ${response['id']}");
    print("└─────────────────────────────────────────────────────────┘");
    return Producto.fromJson(response);
  }

  static Future<Producto?> updateProducto(Producto producto) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.updateProducto(id: ${producto.id})");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    if (producto.id == null) {
      print("│ ❌ ERROR: producto.id es null");
      print("└─────────────────────────────────────────────────────────┘");
      return null;
    }
    
    final data = producto.toJson();
    data.remove('id');
    data.remove('user_id');

    Map<String, dynamic>? response;
    if (useGlobal) {
      print("│ Query: UPDATE productos SET ... WHERE id = ${producto.id}");
      response = await _client
          .from('productos')
          .update(data)
          .eq('id', producto.id!)
          .select()
          .maybeSingle();
    } else {
      print("│ Query: UPDATE productos SET ... WHERE id = ${producto.id} AND user_id = '$uid'");
      response = await _client
          .from('productos')
          .update(data)
          .eq('id', producto.id!)
          .eq('user_id', uid!)
          .select()
          .maybeSingle();
    }
    
    if (response == null) {
      print("│ ❌ ERROR: No se encontró el producto para actualizar");
      print("└─────────────────────────────────────────────────────────┘");
      return null;
    }
    
    print("│ ✅ Producto actualizado");
    print("└─────────────────────────────────────────────────────────┘");
    return Producto.fromJson(response);
  }

  static Future<bool> deleteProducto(int id) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.deleteProducto(id: $id)");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");

    if (useGlobal) {
      print("│ Query: DELETE FROM productos WHERE id = $id");
      await _client
          .from('productos')
          .delete()
          .eq('id', id);
    } else {
      print("│ Query: DELETE FROM productos WHERE id = $id AND user_id = '$uid'");
      await _client
          .from('productos')
          .delete()
          .eq('id', id)
          .eq('user_id', uid!);
    }

    print("│ ✅ Producto eliminado");
    print("└─────────────────────────────────────────────────────────┘");
    return true;
  }

  // ==================== VENTAS ====================

  /// Get ventas - superadmin con vista global ve todas; otros solo las suyas
  static Future<List<Venta>> getVentas({bool globalView = false}) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getVentas()                                 │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> response;
    if (useGlobal) {
      print("│ Query: SELECT * FROM ventas ORDER BY id DESC");
      print("│ (Sin filtro por user_id - vista global)");
      response = await _client
          .from('ventas')
          .select()
          .order('id', ascending: false);
    } else {
      print("│ Query: SELECT * FROM ventas WHERE user_id = '$uid' ORDER BY id DESC");
      response = await _client
          .from('ventas')
          .select()
          .eq('user_id', uid!)
          .order('id', ascending: false);
    }
    
    print("│ Resultado: ${response.length} ventas encontradas");
    print("└─────────────────────────────────────────────────────────┘");
    return (response).map((e) => Venta.fromJson(e)).toList();
  }

  static Future<Venta?> getVenta(int id) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getVenta(id: $id)");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    Map<String, dynamic>? response;
    if (useGlobal) {
      print("│ Query: SELECT * FROM ventas WHERE id = $id");
      response = await _client
          .from('ventas')
          .select()
          .eq('id', id)
          .maybeSingle();
    } else {
      print("│ Query: SELECT * FROM ventas WHERE id = $id AND user_id = '$uid'");
      response = await _client
          .from('ventas')
          .select()
          .eq('id', id)
          .eq('user_id', uid!)
          .maybeSingle();
    }
    
    print("│ Resultado: ${response != null ? 'Encontrada' : 'No encontrada'}");
    print("└─────────────────────────────────────────────────────────┘");
    
    if (response == null) return null;
    return Venta.fromJson(response);
  }

  static Future<Venta?> createVenta(Venta venta) async {
    final uid = await _getUserIdForInsert();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.createVenta()                               │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id para INSERT: $uid");

    final data = venta.toJson();
    data['user_id'] = uid;  // ⚠️ CRÍTICO: Siempre incluir user_id
    data.remove('id');
    
    print("│ Query: INSERT INTO ventas (importe, fecha, producto_id, cantidad, metodo_pago, comentarios, user_id)");
    print("│ Datos: ${data.toString()}");

    final response = await _client
        .from('ventas')
        .insert(data)
        .select()
        .maybeSingle();

    if (response == null) {
      print("│ ❌ ERROR: No se pudo crear la venta");
      print("└─────────────────────────────────────────────────────────┘");
      return null;
    }

    print("│ ✅ Venta creada con id: ${response['id']}");
    print("└─────────────────────────────────────────────────────────┘");
    return Venta.fromJson(response);
  }

  static Future<Venta?> updateVenta(Venta venta) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.updateVenta(id: ${venta.id})");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    if (venta.id == null) {
      print("│ ❌ ERROR: venta.id es null");
      print("└─────────────────────────────────────────────────────────┘");
      return null;
    }
    
    final data = venta.toJson();
    data.remove('id');
    data.remove('user_id');

    Map<String, dynamic>? response;
    if (useGlobal) {
      print("│ Query: UPDATE ventas SET ... WHERE id = ${venta.id}");
      response = await _client
          .from('ventas')
          .update(data)
          .eq('id', venta.id!)
          .select()
          .maybeSingle();
    } else {
      print("│ Query: UPDATE ventas SET ... WHERE id = ${venta.id} AND user_id = '$uid'");
      response = await _client
          .from('ventas')
          .update(data)
          .eq('id', venta.id!)
          .eq('user_id', uid!)
          .select()
          .maybeSingle();
    }
    
    if (response == null) {
      print("│ ❌ ERROR: No se encontró la venta para actualizar");
      print("└─────────────────────────────────────────────────────────┘");
      return null;
    }
    
    print("│ ✅ Venta actualizada");
    print("└─────────────────────────────────────────────────────────┘");
    return Venta.fromJson(response);
  }

  static Future<bool> deleteVenta(int id) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.deleteVenta(id: $id)");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");

    if (useGlobal) {
      print("│ Query: DELETE FROM ventas WHERE id = $id");
      await _client
          .from('ventas')
          .delete()
          .eq('id', id);
    } else {
      print("│ Query: DELETE FROM ventas WHERE id = $id AND user_id = '$uid'");
      await _client
          .from('ventas')
          .delete()
          .eq('id', id)
          .eq('user_id', uid!);
    }

    print("│ ✅ Venta eliminada");
    print("└─────────────────────────────────────────────────────────┘");
    return true;
  }

  // ==================== GASTOS ====================

  /// Get gastos - superadmin con vista global ve todos; otros solo los suyos
  static Future<List<Gasto>> getGastos({bool globalView = false}) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getGastos()                                 │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> response;
    if (useGlobal) {
      print("│ Query: SELECT * FROM gastos ORDER BY id DESC");
      print("│ (Sin filtro por user_id - vista global)");
      response = await _client
          .from('gastos')
          .select()
          .order('id', ascending: false);
    } else {
      print("│ Query: SELECT * FROM gastos WHERE user_id = '$uid' ORDER BY id DESC");
      response = await _client
          .from('gastos')
          .select()
          .eq('user_id', uid!)
          .order('id', ascending: false);
    }
    
    print("│ Resultado: ${response.length} gastos encontrados");
    print("└─────────────────────────────────────────────────────────┘");
    return (response).map((e) => Gasto.fromJson(e)).toList();
  }

  static Future<Gasto?> getGasto(int id) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getGasto(id: $id)");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    Map<String, dynamic>? response;
    if (useGlobal) {
      print("│ Query: SELECT * FROM gastos WHERE id = $id");
      response = await _client
          .from('gastos')
          .select()
          .eq('id', id)
          .maybeSingle();
    } else {
      print("│ Query: SELECT * FROM gastos WHERE id = $id AND user_id = '$uid'");
      response = await _client
          .from('gastos')
          .select()
          .eq('id', id)
          .eq('user_id', uid!)
          .maybeSingle();
    }
    
    print("│ Resultado: ${response != null ? 'Encontrado' : 'No encontrado'}");
    print("└─────────────────────────────────────────────────────────┘");
    
    if (response == null) return null;
    return Gasto.fromJson(response);
  }

  static Future<Gasto?> createGasto(Gasto gasto) async {
    final uid = await _getUserIdForInsert();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.createGasto()                               │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id para INSERT: $uid");

    final data = gasto.toJson();
    data['user_id'] = uid;  // ⚠️ CRÍTICO: Siempre incluir user_id
    data.remove('id');
    
    print("│ Query: INSERT INTO gastos (importe, fecha, categoria, metodo_pago, comentarios, imagen_url, user_id)");
    print("│ Datos: ${data.toString()}");

    final response = await _client
        .from('gastos')
        .insert(data)
        .select()
        .maybeSingle();

    if (response == null) {
      print("│ ❌ ERROR: No se pudo crear el gasto");
      print("└─────────────────────────────────────────────────────────┘");
      return null;
    }

    print("│ ✅ Gasto creado con id: ${response['id']}");
    print("└─────────────────────────────────────────────────────────┘");
    return Gasto.fromJson(response);
  }

  static Future<Gasto?> updateGasto(Gasto gasto) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.updateGasto(id: ${gasto.id})");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    if (gasto.id == null) {
      print("│ ❌ ERROR: gasto.id es null");
      print("└─────────────────────────────────────────────────────────┘");
      return null;
    }
    
    final data = gasto.toJson();
    data.remove('id');
    data.remove('user_id');

    Map<String, dynamic>? response;
    if (useGlobal) {
      print("│ Query: UPDATE gastos SET ... WHERE id = ${gasto.id}");
      response = await _client
          .from('gastos')
          .update(data)
          .eq('id', gasto.id!)
          .select()
          .maybeSingle();
    } else {
      print("│ Query: UPDATE gastos SET ... WHERE id = ${gasto.id} AND user_id = '$uid'");
      response = await _client
          .from('gastos')
          .update(data)
          .eq('id', gasto.id!)
          .eq('user_id', uid!)
          .select()
          .maybeSingle();
    }
    
    if (response == null) {
      print("│ ❌ ERROR: No se encontró el gasto para actualizar");
      print("└─────────────────────────────────────────────────────────┘");
      return null;
    }
    
    print("│ ✅ Gasto actualizado");
    print("└─────────────────────────────────────────────────────────┘");
    return Gasto.fromJson(response);
  }

  static Future<bool> deleteGasto(int id) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.deleteGasto(id: $id)");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");

    if (useGlobal) {
      print("│ Query: DELETE FROM gastos WHERE id = $id");
      await _client
          .from('gastos')
          .delete()
          .eq('id', id);
    } else {
      print("│ Query: DELETE FROM gastos WHERE id = $id AND user_id = '$uid'");
      await _client
          .from('gastos')
          .delete()
          .eq('id', id)
          .eq('user_id', uid!);
    }

    print("│ ✅ Gasto eliminado");
    print("└─────────────────────────────────────────────────────────┘");
    return true;
  }

  // ==================== ESTADÍSTICAS ====================

  /// Get total ventas - superadmin con vista global ve todas; otros solo las suyas
  static Future<double> getTotalVentas({bool globalView = false}) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getTotalVentas()                            │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> response;
    try {
      if (useGlobal) {
        print("│ Query: SELECT importe FROM ventas (GLOBAL)");
        response = await _client.from('ventas').select('importe');
      } else {
        print("│ Query: SELECT importe FROM ventas WHERE user_id = '$uid'");
        response = await _client.from('ventas').select('importe').eq('user_id', uid!);
      }
      print("│ Response length: ${response.length}");
      print("│ Response data: $response");
    } catch (e) {
      print("│ ❌ ERROR en query: $e");
      response = [];
    }

    double total = 0.0;
    for (var row in response) {
      total += (row['importe'] as num?)?.toDouble() ?? 0.0;
    }
    
    print("│ Resultado: Total ventas = $total");
    print("└─────────────────────────────────────────────────────────┘");
    return total;
  }

  /// Get total gastos - superadmin con vista global ve todos; otros solo los suyos
  static Future<double> getTotalGastos({bool globalView = false}) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getTotalGastos()                            │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> response;
    try {
      if (useGlobal) {
        print("│ Query: SELECT importe FROM gastos (GLOBAL)");
        response = await _client.from('gastos').select('importe');
      } else {
        print("│ Query: SELECT importe FROM gastos WHERE user_id = '$uid'");
        response = await _client.from('gastos').select('importe').eq('user_id', uid!);
      }
      print("│ Response length: ${response.length}");
      print("│ Response data: $response");
    } catch (e) {
      print("│ ❌ ERROR en query: $e");
      response = [];
    }

    double total = 0.0;
    for (var row in response) {
      total += (row['importe'] as num?)?.toDouble() ?? 0.0;
    }
    
    print("│ Resultado: Total gastos = $total");
    print("└─────────────────────────────────────────────────────────┘");
    return total;
  }

  /// Get total productos - superadmin con vista global ve todos; otros solo los suyos
  static Future<int> getTotalProductos({bool globalView = false}) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getTotalProductos()                         │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> response;
    if (useGlobal) {
      print("│ Query: SELECT id FROM productos");
      response = await _client.from('productos').select('id');
    } else {
      print("│ Query: SELECT id FROM productos WHERE user_id = '$uid'");
      response = await _client.from('productos').select('id').eq('user_id', uid!);
    }

    print("│ Resultado: ${response.length} productos");
    print("└─────────────────────────────────────────────────────────┘");
    return response.length;
  }

  /// Get ventas por mes - superadmin con vista global ve todas; otros solo las suyas
  static Future<Map<String, double>> getVentasPorMes({bool globalView = false}) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getVentasPorMes()                           │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> response;
    if (useGlobal) {
      print("│ Query: SELECT importe, fecha FROM ventas");
      response = await _client.from('ventas').select('importe, fecha');
    } else {
      print("│ Query: SELECT importe, fecha FROM ventas WHERE user_id = '$uid'");
      response = await _client.from('ventas').select('importe, fecha').eq('user_id', uid!);
    }

    Map<String, double> ventasPorMes = {};
    for (var row in response) {
      if (row['fecha'] != null) {
        final fecha = DateTime.parse(row['fecha']);
        final key = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
        ventasPorMes[key] = (ventasPorMes[key] ?? 0) + ((row['importe'] as num?)?.toDouble() ?? 0);
      }
    }
    
    print("│ Resultado: ${ventasPorMes.length} meses con datos");
    print("└─────────────────────────────────────────────────────────┘");
    return ventasPorMes;
  }

  /// Get gastos por mes - superadmin con vista global ve todos; otros solo los suyos
  static Future<Map<String, double>> getGastosPorMes({bool globalView = false}) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getGastosPorMes()                           │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> response;
    if (useGlobal) {
      print("│ Query: SELECT importe, fecha FROM gastos");
      response = await _client.from('gastos').select('importe, fecha');
    } else {
      print("│ Query: SELECT importe, fecha FROM gastos WHERE user_id = '$uid'");
      response = await _client.from('gastos').select('importe, fecha').eq('user_id', uid!);
    }

    Map<String, double> gastosPorMes = {};
    for (var row in response) {
      if (row['fecha'] != null) {
        final fecha = DateTime.parse(row['fecha']);
        final key = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
        gastosPorMes[key] = (gastosPorMes[key] ?? 0) + ((row['importe'] as num?)?.toDouble() ?? 0);
      }
    }
    
    print("│ Resultado: ${gastosPorMes.length} meses con datos");
    print("└─────────────────────────────────────────────────────────┘");
    return gastosPorMes;
  }

  // ==================== DASHBOARD STATISTICS ====================

  /// Get total transactions count (ventas + gastos)
  static Future<int> getTotalTransactions() async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getTotalTransactions()                      │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> ventasResponse;
    List<dynamic> gastosResponse;
    
    if (useGlobal) {
      ventasResponse = await _client.from('ventas').select('id');
      gastosResponse = await _client.from('gastos').select('id');
    } else {
      ventasResponse = await _client.from('ventas').select('id').eq('user_id', uid!);
      gastosResponse = await _client.from('gastos').select('id').eq('user_id', uid!);
    }
    
    final total = ventasResponse.length + gastosResponse.length;
    print("│ Resultado: $total transacciones (${ventasResponse.length} ventas + ${gastosResponse.length} gastos)");
    print("└─────────────────────────────────────────────────────────┘");
    return total;
  }

  /// Get profit by month (ventas - gastos)
  static Future<Map<String, double>> getProfitByMonth() async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getProfitByMonth()                          │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> ventasResponse;
    List<dynamic> gastosResponse;
    
    if (useGlobal) {
      ventasResponse = await _client.from('ventas').select('importe, fecha');
      gastosResponse = await _client.from('gastos').select('importe, fecha');
    } else {
      ventasResponse = await _client.from('ventas').select('importe, fecha').eq('user_id', uid!);
      gastosResponse = await _client.from('gastos').select('importe, fecha').eq('user_id', uid!);
    }

    Map<String, double> ventasPorMes = {};
    Map<String, double> gastosPorMes = {};
    
    for (var row in ventasResponse) {
      if (row['fecha'] != null) {
        final fecha = DateTime.parse(row['fecha']);
        final key = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
        ventasPorMes[key] = (ventasPorMes[key] ?? 0) + ((row['importe'] as num?)?.toDouble() ?? 0);
      }
    }
    
    for (var row in gastosResponse) {
      if (row['fecha'] != null) {
        final fecha = DateTime.parse(row['fecha']);
        final key = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
        gastosPorMes[key] = (gastosPorMes[key] ?? 0) + ((row['importe'] as num?)?.toDouble() ?? 0);
      }
    }
    
    // Combine all months and calculate profit
    final allMonths = {...ventasPorMes.keys, ...gastosPorMes.keys};
    Map<String, double> profitPorMes = {};
    for (var month in allMonths) {
      profitPorMes[month] = (ventasPorMes[month] ?? 0) - (gastosPorMes[month] ?? 0);
    }
    
    print("│ Resultado: ${profitPorMes.length} meses con datos");
    print("└─────────────────────────────────────────────────────────┘");
    return profitPorMes;
  }

  /// Get top selling products with quantities
  static Future<List<Map<String, dynamic>>> getTopProducts({int limit = 5}) async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getTopProducts(limit: $limit)");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> ventasResponse;
    
    if (useGlobal) {
      ventasResponse = await _client.from('ventas').select('producto_id, cantidad, importe');
    } else {
      ventasResponse = await _client.from('ventas').select('producto_id, cantidad, importe').eq('user_id', uid!);
    }
    
    // Aggregate by product
    Map<int, Map<String, dynamic>> productStats = {};
    for (var row in ventasResponse) {
      final productId = row['producto_id'] as int?;
      if (productId != null) {
        if (!productStats.containsKey(productId)) {
          productStats[productId] = {
            'producto_id': productId,
            'cantidad_total': 0,
            'importe_total': 0.0,
          };
        }
        productStats[productId]!['cantidad_total'] += (row['cantidad'] as num?)?.toInt() ?? 1;
        productStats[productId]!['importe_total'] += (row['importe'] as num?)?.toDouble() ?? 0.0;
      }
    }
    
    // Get product names
    List<dynamic> productosResponse;
    if (useGlobal) {
      productosResponse = await _client.from('productos').select('id, nombre');
    } else {
      productosResponse = await _client.from('productos').select('id, nombre').eq('user_id', uid!);
    }
    
    Map<int, String> productNames = {};
    for (var p in productosResponse) {
      productNames[p['id'] as int] = p['nombre'] as String? ?? 'Unknown';
    }
    
    // Build result list with names
    List<Map<String, dynamic>> result = productStats.values.map((stats) {
      return {
        'producto_id': stats['producto_id'],
        'nombre': productNames[stats['producto_id']] ?? 'Unknown',
        'cantidad_total': stats['cantidad_total'],
        'importe_total': stats['importe_total'],
      };
    }).toList();
    
    // Sort by cantidad_total descending and limit
    result.sort((a, b) => (b['cantidad_total'] as int).compareTo(a['cantidad_total'] as int));
    if (result.length > limit) {
      result = result.sublist(0, limit);
    }
    
    print("│ Resultado: ${result.length} productos top");
    print("└─────────────────────────────────────────────────────────┘");
    return result;
  }

  /// Get payment method statistics
  static Future<Map<String, double>> getPaymentMethodStats() async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getPaymentMethodStats()                     │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> ventasResponse;
    
    if (useGlobal) {
      ventasResponse = await _client.from('ventas').select('metodo_pago, importe');
    } else {
      ventasResponse = await _client.from('ventas').select('metodo_pago, importe').eq('user_id', uid!);
    }
    
    Map<String, double> stats = {};
    for (var row in ventasResponse) {
      final method = row['metodo_pago'] as String? ?? 'other';
      stats[method] = (stats[method] ?? 0) + ((row['importe'] as num?)?.toDouble() ?? 0);
    }
    
    print("│ Resultado: ${stats.length} métodos de pago");
    print("└─────────────────────────────────────────────────────────┘");
    return stats;
  }

  /// Get stock evolution (average stock per month based on product creation/updates)
  static Future<Map<String, double>> getStockEvolution() async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getStockEvolution()                         │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> productosResponse;
    
    if (useGlobal) {
      productosResponse = await _client.from('productos').select('stock, created_at');
    } else {
      productosResponse = await _client.from('productos').select('stock, created_at').eq('user_id', uid!);
    }
    
    // Group stock by month of creation
    Map<String, List<int>> stockByMonth = {};
    for (var row in productosResponse) {
      String key;
      if (row['created_at'] != null) {
        final fecha = DateTime.parse(row['created_at']);
        key = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
      } else {
        // Use current month if no created_at
        final now = DateTime.now();
        key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      }
      
      if (!stockByMonth.containsKey(key)) {
        stockByMonth[key] = [];
      }
      stockByMonth[key]!.add((row['stock'] as num?)?.toInt() ?? 0);
    }
    
    // Calculate average stock per month
    Map<String, double> avgStock = {};
    for (var entry in stockByMonth.entries) {
      final sum = entry.value.reduce((a, b) => a + b);
      avgStock[entry.key] = sum / entry.value.length;
    }
    
    print("│ Resultado: ${avgStock.length} meses con datos de stock");
    print("└─────────────────────────────────────────────────────────┘");
    return avgStock;
  }

  /// Get current total stock
  static Future<int> getTotalStock() async {
    final (uid, useGlobal) = await _getQueryContext();
    
    print("┌─────────────────────────────────────────────────────────┐");
    print("│ DataService.getTotalStock()                             │");
    print("├─────────────────────────────────────────────────────────┤");
    print("│ user_id: $uid");
    print("│ useGlobal: $useGlobal");
    
    List<dynamic> response;
    
    if (useGlobal) {
      response = await _client.from('productos').select('stock');
    } else {
      response = await _client.from('productos').select('stock').eq('user_id', uid!);
    }
    
    int total = 0;
    for (var row in response) {
      total += (row['stock'] as num?)?.toInt() ?? 0;
    }
    
    print("│ Resultado: Stock total = $total");
    print("└─────────────────────────────────────────────────────────┘");
    return total;
  }
}
