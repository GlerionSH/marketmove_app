import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:marketmove_app/providers/locale_provider.dart';

class LanguageSwitcher extends StatelessWidget {
  final bool compact;

  const LanguageSwitcher({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isSpanish = localeProvider.locale.languageCode == 'es';
    final colorScheme = Theme.of(context).colorScheme;

    if (compact) {
      return IconButton(
        icon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isSpanish ? 'EN' : 'ES',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onPressed: () {
          localeProvider.setLocale(
            isSpanish ? const Locale('en') : const Locale('es'),
          );
        },
        tooltip: isSpanish ? 'Switch to English' : 'Cambiar a Español',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            localeProvider.setLocale(
              isSpanish ? const Locale('en') : const Locale('es'),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isSpanish ? 'English' : 'Español',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
