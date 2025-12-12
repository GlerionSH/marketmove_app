import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marketmove_app/services/session_service.dart';
import 'package:marketmove_app/screens/auth/login_screen.dart';
import 'package:marketmove_app/screens/auth/register_screen.dart';
import 'package:marketmove_app/screens/auth/forgot_password_screen.dart';
import 'package:marketmove_app/screens/home/home_screen.dart';
import 'package:marketmove_app/screens/productos/productos_list_screen.dart';
import 'package:marketmove_app/screens/productos/producto_form_screen.dart';
import 'package:marketmove_app/screens/productos/producto_detail_screen.dart';
import 'package:marketmove_app/screens/ventas/ventas_list_screen.dart';
import 'package:marketmove_app/screens/ventas/venta_form_screen.dart';
import 'package:marketmove_app/screens/ventas/venta_detail_screen.dart';
import 'package:marketmove_app/screens/gastos/gastos_list_screen.dart';
import 'package:marketmove_app/screens/gastos/gasto_form_screen.dart';
import 'package:marketmove_app/screens/gastos/gasto_detail_screen.dart';
import 'package:marketmove_app/screens/estadisticas/estadisticas_screen.dart';
import 'package:marketmove_app/screens/perfil/perfil_screen.dart';
import 'package:marketmove_app/screens/admin/admin_panel_screen.dart';

class AppRouter {
  static bool? _cachedLoggedIn;

  static Future<void> refreshAuthState() async {
    _cachedLoggedIn = await SessionService.isLoggedIn();
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/login',

    redirect: (context, state) async {
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      final logged = await SessionService.isLoggedIn();

      if (!logged && !isAuthRoute) {
        return '/login';
      }

      if (logged && isAuthRoute) {
        return '/home';
      }

      return null;
    },

    routes: [
      // ---------- Auth ----------
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ---------- Home ----------
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      // ---------- Productos ----------
      GoRoute(
        path: '/productos',
        builder: (context, state) => const ProductosListScreen(),
      ),
      GoRoute(
        path: '/productos/nuevo',
        builder: (context, state) => const ProductoFormScreen(),
      ),
      GoRoute(
        path: '/productos/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductoDetailScreen(productoId: id);
        },
      ),
      GoRoute(
        path: '/productos/:id/editar',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductoFormScreen(productoId: id);
        },
      ),

      // ---------- Ventas ----------
      GoRoute(
        path: '/ventas',
        builder: (context, state) => const VentasListScreen(),
      ),
      GoRoute(
        path: '/ventas/nueva',
        builder: (context, state) => const VentaFormScreen(),
      ),
      GoRoute(
        path: '/ventas/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VentaDetailScreen(ventaId: id);
        },
      ),
      GoRoute(
        path: '/ventas/:id/editar',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VentaFormScreen(ventaId: id);
        },
      ),

      // ---------- Gastos ----------
      GoRoute(
        path: '/gastos',
        builder: (context, state) => const GastosListScreen(),
      ),
      GoRoute(
        path: '/gastos/nuevo',
        builder: (context, state) => const GastoFormScreen(),
      ),
      GoRoute(
        path: '/gastos/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GastoDetailScreen(gastoId: id);
        },
      ),
      GoRoute(
        path: '/gastos/:id/editar',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GastoFormScreen(gastoId: id);
        },
      ),

      // ---------- Estadísticas ----------
      GoRoute(
        path: '/estadisticas',
        builder: (context, state) => const EstadisticasScreen(),
      ),

      // ---------- Perfil ----------
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const PerfilScreen(),
      ),

      // ---------- Admin Panel (superadmin only) ----------
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPanelScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(child: Text("Página no encontrada")),
    ),
  );
}
