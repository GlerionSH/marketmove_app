import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:marketmove_app/l10n/app_localizations.dart';
import 'package:marketmove_app/models/gasto.dart';
import 'package:marketmove_app/services/data_service.dart';
import 'package:marketmove_app/widgets/custom_app_bar.dart';
import 'package:marketmove_app/widgets/custom_card.dart';
import 'package:marketmove_app/widgets/custom_button.dart';
import 'package:marketmove_app/widgets/custom_loader.dart';

class GastoDetailScreen extends StatefulWidget {
  final String gastoId;

  const GastoDetailScreen({super.key, required this.gastoId});

  @override
  State<GastoDetailScreen> createState() => _GastoDetailScreenState();
}

class _GastoDetailScreenState extends State<GastoDetailScreen>
    with SingleTickerProviderStateMixin {
  Gasto? _gasto;
  bool _loading = true;
  String? _error;

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
    _loadGasto();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadGasto() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final id = int.tryParse(widget.gastoId);
      if (id != null) {
        final gasto = await DataService.getGasto(id);
        setState(() {
          _gasto = gasto;
          _loading = false;
        });
        _animController.forward();
      } else {
        setState(() {
          _error = 'ID inválido';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showFullImage(BuildContext context) {
    if (_gasto?.imagenUrl == null || _gasto!.imagenUrl!.isEmpty) return;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    _gasto!.imagenUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200,
                        height: 200,
                        color: colorScheme.surface,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 200,
                      height: 200,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.broken_image, size: 64, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGasto() async {
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
        content: Text(t.confirmDelete),
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
      try {
        final id = int.tryParse(widget.gastoId);
        if (id != null) {
          await DataService.deleteGasto(id);
          if (mounted) {
            context.pop();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    if (_loading) {
      return Scaffold(
        appBar: CustomAppBar(title: t.expenseDetail),
        body: CustomLoader(message: t.loading),
      );
    }

    if (_error != null || _gasto == null) {
      return Scaffold(
        appBar: CustomAppBar(title: t.expenseDetail),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  _error ?? (_gasto == null ? t.itemNotFound : t.noData),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: t.back,
                  onPressed: () => context.pop(),
                  icon: Icons.arrow_back,
                  fullWidth: false,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: t.expenseDetail,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await context.push('/gastos/${widget.gastoId}/editar');
              _loadGasto();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteGasto,
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
                children: [
                  // Expense Image (ticket/receipt)
                  if (_gasto!.imagenUrl != null && _gasto!.imagenUrl!.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showFullImage(context),
                      child: Container(
                        width: double.infinity,
                        height: 250,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _gasto!.imagenUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: colorScheme.error.withOpacity(0.1),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: colorScheme.error.withOpacity(0.1),
                              child: Icon(
                                Icons.broken_image,
                                size: 64,
                                color: colorScheme.error.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  CustomCard(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _gasto!.imagenUrl != null && _gasto!.imagenUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _gasto!.imagenUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.receipt_long,
                                      size: 48,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.receipt_long,
                                  size: 48,
                                  color: colorScheme.error,
                                ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\$${_gasto!.importe.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.error,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_gasto!.categoria != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _gasto!.categoria!,
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (_gasto!.fecha != null)
                          _buildDetailRow(
                            Icons.calendar_today,
                            t.date,
                            dateFormat.format(_gasto!.fecha!),
                            Colors.purple,
                          ),
                        if (_gasto!.metodoPago != null) ...[
                          const Divider(height: 24),
                          _buildDetailRow(
                            Icons.payment,
                            t.paymentMethod,
                            _gasto!.metodoPago!,
                            colorScheme.primary,
                          ),
                        ],
                        if (_gasto!.comentarios != null) ...[
                          const Divider(height: 24),
                          _buildDetailRow(
                            Icons.comment,
                            t.comments,
                            _gasto!.comentarios!,
                            Colors.orange,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: t.edit,
                          onPressed: () async {
                            await context.push('/gastos/${widget.gastoId}/editar');
                            _loadGasto();
                          },
                          icon: Icons.edit,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: t.delete,
                          onPressed: _deleteGasto,
                          icon: Icons.delete,
                          isOutlined: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
