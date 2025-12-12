import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marketmove_app/widgets/language_switcher.dart';
import 'package:marketmove_app/widgets/theme_switcher.dart';
import 'package:marketmove_app/services/session_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool showLanguageSwitcher;
  final bool showThemeSwitcher;
  final bool showLogout;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.showLanguageSwitcher = true,
    this.showThemeSwitcher = true,
    this.showLogout = false,
    this.actions,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AppBar(
      title: Text(title),
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 2,
      shadowColor: colorScheme.shadow,
      iconTheme: IconThemeData(color: colorScheme.onSurface),
      actionsIconTheme: IconThemeData(color: colorScheme.onSurface),
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: onBackPressed ?? () => context.pop(),
            )
          : null,
      automaticallyImplyLeading: showBack,
      actions: [
        if (actions != null) ...actions!,
        if (showThemeSwitcher) const ThemeSwitcher(),
        if (showLanguageSwitcher) const LanguageSwitcher(compact: true),
        if (showLogout)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SessionService.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            tooltip: 'Logout',
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}
