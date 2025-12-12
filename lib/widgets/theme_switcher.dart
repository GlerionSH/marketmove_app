import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:marketmove_app/services/theme_service.dart';
import 'package:marketmove_app/l10n/app_localizations.dart';

/// Animated theme switcher widget for AppBar
class ThemeSwitcher extends StatefulWidget {
  final bool showLabel;
  final Color? iconColor;

  const ThemeSwitcher({
    super.key,
    this.showLabel = false,
    this.iconColor,
  });

  @override
  State<ThemeSwitcher> createState() => _ThemeSwitcherState();
}

class _ThemeSwitcherState extends State<ThemeSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    final themeService = context.read<ThemeService>();
    
    _controller.forward(from: 0).then((_) {
      themeService.toggleThemeMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.isDarkMode(context);
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = widget.iconColor ?? colorScheme.onSurface;

    if (widget.showLabel) {
      return TextButton.icon(
        onPressed: _toggleTheme,
        icon: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 3.14159,
                child: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: iconColor,
                ),
              ),
            );
          },
        ),
        label: Text(
          isDark ? t.lightMode : t.darkMode,
          style: TextStyle(color: iconColor),
        ),
      );
    }

    return Tooltip(
      message: isDark ? t.lightMode : t.darkMode,
      child: IconButton(
        onPressed: _toggleTheme,
        icon: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 3.14159,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isDark ? Icons.light_mode : Icons.dark_mode,
                    key: ValueKey(isDark),
                    color: iconColor,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Compact theme toggle for settings or profile screens
class ThemeToggleTile extends StatelessWidget {
  const ThemeToggleTile({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final isDark = themeService.isDarkMode(context);
    final t = AppLocalizations.of(context)!;

    return ListTile(
      leading: Icon(
        isDark ? Icons.dark_mode : Icons.light_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(t.theme),
      subtitle: Text(isDark ? t.darkMode : t.lightMode),
      trailing: Switch(
        value: isDark,
        onChanged: (_) => themeService.toggleThemeMode(),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => themeService.toggleThemeMode(),
    );
  }
}
