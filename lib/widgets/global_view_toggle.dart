import 'package:flutter/material.dart';
import 'package:marketmove_app/l10n/app_localizations.dart';
import 'package:marketmove_app/services/session_service.dart';

class GlobalViewToggle extends StatefulWidget {
  final VoidCallback? onChanged;

  const GlobalViewToggle({super.key, this.onChanged});

  @override
  State<GlobalViewToggle> createState() => _GlobalViewToggleState();
}

class _GlobalViewToggleState extends State<GlobalViewToggle> {
  bool _isSuperAdmin = false;
  bool _globalViewEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final isSuperAdmin = await SessionService.isSuperAdmin();
    final globalViewEnabled = await SessionService.getGlobalViewEnabled();
    setState(() {
      _isSuperAdmin = isSuperAdmin;
      _globalViewEnabled = globalViewEnabled;
      _loading = false;
    });
  }

  Future<void> _toggleGlobalView(bool value) async {
    await SessionService.setGlobalViewEnabled(value);
    setState(() => _globalViewEnabled = value);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (_loading || !_isSuperAdmin) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility,
            size: 18,
            color: Colors.purple,
          ),
          const SizedBox(width: 8),
          Text(
            t.superAdminMode,
            style: TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<bool>(
            value: _globalViewEnabled,
            underline: const SizedBox.shrink(),
            isDense: true,
            icon: Icon(Icons.arrow_drop_down, color: Colors.purple),
            items: [
              DropdownMenuItem(
                value: true,
                child: Text(
                  t.viewAllData,
                  style: TextStyle(fontSize: 12),
                ),
              ),
              DropdownMenuItem(
                value: false,
                child: Text(
                  t.viewOnlyMine,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _toggleGlobalView(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
