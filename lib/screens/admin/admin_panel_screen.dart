import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marketmove_app/l10n/app_localizations.dart';
import 'package:marketmove_app/models/user_app.dart';
import 'package:marketmove_app/services/users_service.dart';
import 'package:marketmove_app/services/session_service.dart';
import 'package:marketmove_app/widgets/custom_app_bar.dart';
import 'package:marketmove_app/widgets/custom_card.dart';
import 'package:marketmove_app/widgets/custom_button.dart';
import 'package:marketmove_app/widgets/custom_loader.dart';
import 'package:marketmove_app/widgets/animated_list_item.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  List<UserApp> _users = [];
  Map<String, int> _userCounts = {};
  bool _loading = true;
  String? _error;
  String? _currentUserId;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _checkAccessAndLoad();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkAccessAndLoad() async {
    final isSuperAdmin = await SessionService.isSuperAdmin();
    if (!isSuperAdmin) {
      if (mounted) context.go('/home');
      return;
    }
    _currentUserId = await SessionService.getUserId();
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        UsersService.getAllUsers(),
        UsersService.getUserCountByRole(),
      ]);

      setState(() {
        _users = results[0] as List<UserApp>;
        _userCounts = results[1] as Map<String, int>;
        _loading = false;
      });
      _animController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _changeUserRole(UserApp user) async {
    final t = AppLocalizations.of(context)!;
    
    final roles = ['user', 'admin', 'superadmin'];
    final currentIndex = roles.indexOf(user.role);
    
    final selectedRole = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(t.changeRole),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${t.selectNewRole} ${user.email}:'),
            const SizedBox(height: 16),
            ...roles.map((role) => RadioListTile<String>(
              title: Text(_getRoleDisplayName(role)),
              value: role,
              groupValue: user.role,
              onChanged: (value) => Navigator.pop(ctx, value),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
        ],
      ),
    );

    if (selectedRole != null && selectedRole != user.role) {
      final success = await UsersService.updateUserRole(user.id, selectedRole);
      if (success) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.roleUpdated)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.roleUpdateFailed)),
          );
        }
      }
    }
  }

  Future<void> _deleteUser(UserApp user) async {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.error),
            const SizedBox(width: 12),
            Text(t.delete),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.deleteUserConfirm),
            const SizedBox(height: 8),
            Text(
              user.email,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              t.deleteUserWarning,
              style: TextStyle(color: colorScheme.error, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await UsersService.deleteUser(user.id);
      if (success) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.userDeleted)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.userDeleteFailed)),
          );
        }
      }
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'superadmin':
        return 'Super Admin';
      case 'admin':
        return 'Admin';
      default:
        return 'User';
    }
  }

  Color _getRoleColor(String role, ColorScheme colorScheme) {
    switch (role) {
      case 'superadmin':
        return Colors.purple;
      case 'admin':
        return colorScheme.primary;
      default:
        return Colors.green;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'superadmin':
        return Icons.shield;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: CustomAppBar(
          title: t.adminPanel,
          onBackPressed: () => context.go('/home'),
        ),
        body: CustomLoader(message: t.loading),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: CustomAppBar(
          title: t.adminPanel,
          onBackPressed: () => context.go('/home'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              CustomButton(
                text: t.retry,
                onPressed: _loadData,
                icon: Icons.refresh,
                fullWidth: false,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Admin Panel',
        onBackPressed: () => context.go('/home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards
                  _buildStatsSection(t, colorScheme),
                  const SizedBox(height: 24),

                  // Users List
                  Text(
                    t.usersManagement,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isCurrentUser = user.id == _currentUserId;
                      
                      return AnimatedListItem(
                        index: index,
                        child: CustomCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(user.role, colorScheme).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getRoleIcon(user.role),
                                  color: _getRoleColor(user.role, colorScheme),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            user.email,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isCurrentUser)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              t.you,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user.role, colorScheme).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getRoleDisplayName(user.role),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getRoleColor(user.role, colorScheme),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isCurrentUser) ...[
                                IconButton(
                                  icon: Icon(Icons.edit, color: colorScheme.primary),
                                  onPressed: () => _changeUserRole(user),
                                  tooltip: t.changeRole,
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: colorScheme.error),
                                  onPressed: () => _deleteUser(user),
                                  tooltip: t.delete,
                                ),
                              ],
                            ],
                          ),
                        ),
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

  Widget _buildStatsSection(AppLocalizations t, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: AnimatedListItem(
            index: 0,
            child: _buildStatCard(
              t.totalUsers,
              _users.length.toString(),
              Icons.people,
              colorScheme.primary,
              colorScheme,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedListItem(
            index: 1,
            child: _buildStatCard(
              t.admins,
              ((_userCounts['admin'] ?? 0) + (_userCounts['superadmin'] ?? 0)).toString(),
              Icons.admin_panel_settings,
              Colors.purple,
              colorScheme,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedListItem(
            index: 2,
            child: _buildStatCard(
              t.users,
              (_userCounts['user'] ?? 0).toString(),
              Icons.person,
              Colors.green,
              colorScheme,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ColorScheme colorScheme) {
    return CustomCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
