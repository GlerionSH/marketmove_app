import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marketmove_app/l10n/app_localizations.dart';
import 'package:marketmove_app/services/session_service.dart';
import 'package:marketmove_app/widgets/custom_app_bar.dart';
import 'package:marketmove_app/widgets/custom_card.dart';
import 'package:marketmove_app/widgets/animated_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userEmail;
  String? _userRole;
  bool _isAdmin = false;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await SessionService.getEmail();
    final role = await SessionService.getRole();
    final isAdmin = await SessionService.isAdmin();
    final isSuperAdmin = await SessionService.isSuperAdmin();
    setState(() {
      _userEmail = email;
      _userRole = role;
      _isAdmin = isAdmin;
      _isSuperAdmin = isSuperAdmin;
    });
  }

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'superadmin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final colorScheme = Theme.of(context).colorScheme;
    
    final menuItems = <_MenuItem>[
      _MenuItem(
        icon: Icons.inventory_2_outlined,
        title: _isAdmin ? t.globalProducts : t.products,
        subtitle: _isAdmin ? t.viewAllProducts : t.manageInventory,
        color: colorScheme.primary,
        route: '/productos',
      ),
      _MenuItem(
        icon: Icons.point_of_sale_outlined,
        title: _isAdmin ? t.globalSales : t.sales,
        subtitle: _isAdmin ? t.viewAllSales : t.registerSales,
        color: Colors.green,
        route: '/ventas',
      ),
      _MenuItem(
        icon: Icons.receipt_long_outlined,
        title: _isAdmin ? t.globalExpenses : t.expenses,
        subtitle: _isAdmin ? t.viewAllExpenses : t.controlExpenses,
        color: colorScheme.error,
        route: '/gastos',
      ),
      _MenuItem(
        icon: Icons.bar_chart_outlined,
        title: _isAdmin ? t.globalStatistics : t.statistics,
        subtitle: _isAdmin ? t.systemAnalysis : t.analyzeYourBusiness,
        color: Colors.purple,
        route: '/estadisticas',
      ),
      _MenuItem(
        icon: Icons.person_outline,
        title: t.profile,
        subtitle: t.yourAccount,
        color: Colors.orange,
        route: '/perfil',
      ),
    ];

    // Add Admin Panel for superadmin
    if (_isSuperAdmin) {
      menuItems.insert(0, _MenuItem(
        icon: Icons.admin_panel_settings,
        title: t.adminPanel,
        subtitle: t.usersManagement,
        color: Colors.deepPurple,
        route: '/admin',
      ));
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: t.appTitle,
        showBack: false,
        showLogout: true,
      ),
      drawer: _buildDrawer(context, t),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  AnimatedListItem(
                    index: 0,
                    child: CustomCard(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.store,
                              size: 40,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.welcome,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userEmail ?? '',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isSuperAdmin 
                                        ? Colors.purple.withOpacity(0.15)
                                        : _isAdmin 
                                            ? colorScheme.primary.withOpacity(0.15)
                                            : Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getRoleDisplayName(_userRole),
                                    style: TextStyle(
                                      color: _isSuperAdmin 
                                          ? Colors.purple
                                          : _isAdmin 
                                              ? colorScheme.primary
                                              : Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu Grid
                  Text(
                    t.homeSummary,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: menuItems.length,
                        itemBuilder: (context, index) {
                          final item = menuItems[index];
                          return AnimatedListItem(
                            index: index + 1,
                            child: _buildMenuCard(context, item),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, _MenuItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomCard(
      margin: EdgeInsets.zero,
      onTap: () => context.go(item.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 32,
              color: item.color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppLocalizations t) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      backgroundColor: colorScheme.surface,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: BoxDecoration(
              color: colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.store,
                    size: 40,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t.appTitle,
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_userEmail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _userEmail!,
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerItem(context, Icons.home_outlined, t.home, '/home'),
                if (_isSuperAdmin)
                  _buildDrawerItem(context, Icons.admin_panel_settings, t.adminPanel, '/admin'),
                _buildDrawerItem(context, Icons.inventory_2_outlined, t.products, '/productos'),
                _buildDrawerItem(context, Icons.point_of_sale_outlined, t.sales, '/ventas'),
                _buildDrawerItem(context, Icons.receipt_long_outlined, t.expenses, '/gastos'),
                _buildDrawerItem(context, Icons.bar_chart_outlined, t.statistics, '/estadisticas'),
                const Divider(height: 32),
                _buildDrawerItem(context, Icons.person_outline, t.profile, '/perfil'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, String route) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title, style: TextStyle(color: colorScheme.onSurface)),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      hoverColor: colorScheme.primary.withOpacity(0.1),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });
}
