import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marketmove_app/l10n/app_localizations.dart';
import 'package:marketmove_app/models/producto.dart';
import 'package:marketmove_app/services/data_service.dart';
import 'package:marketmove_app/services/session_service.dart';
import 'package:marketmove_app/widgets/custom_app_bar.dart';
import 'package:marketmove_app/widgets/custom_card.dart';
import 'package:marketmove_app/widgets/custom_loader.dart';
import 'package:marketmove_app/widgets/custom_button.dart';
import 'package:marketmove_app/widgets/animated_list_item.dart';
import 'package:marketmove_app/widgets/global_view_toggle.dart';
import 'package:marketmove_app/services/export_service.dart';
import 'package:marketmove_app/widgets/image_picker_card.dart';

class ProductosListScreen extends StatefulWidget {
  const ProductosListScreen({super.key});

  @override
  State<ProductosListScreen> createState() => _ProductosListScreenState();
}

class _ProductosListScreenState extends State<ProductosListScreen> {
  List<Producto> _productos = [];
  bool _loading = true;
  String? _error;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _isSuperAdmin = await SessionService.isSuperAdmin();
      // DataService now handles globalView internally via _getQueryContext()
      final productos = await DataService.getProductos();
      setState(() {
        _productos = productos;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: t.products,
        onBackPressed: () => context.go('/home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _showExportDialog(t),
            tooltip: t.export,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProductos,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/productos/nuevo');
          _loadProductos();
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(t.add),
      ),
      body: Column(
        children: [
          if (_isSuperAdmin)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GlobalViewToggle(onChanged: _loadProductos),
            ),
          Expanded(child: _buildBody(t)),
        ],
      ),
    );
  }

  void _showExportDialog(AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.export),
        content: Text(t.chooseFormat),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportToPdf(t);
            },
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            label: const Text('PDF'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportToExcel(t);
            },
            icon: const Icon(Icons.table_chart, color: Colors.green),
            label: const Text('Excel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPdf(AppLocalizations t) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.exporting)),
      );

      final locale = Localizations.localeOf(context).languageCode;
      final bytes = await ExportService.exportProductsToPDF(
        products: _productos,
        locale: locale,
        title: t.products,
        generatedByText: t.generatedBy,
        pageText: t.page,
      );

      await ExportService.sharePdf(bytes, 'productos_${DateTime.now().millisecondsSinceEpoch}.pdf');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.pdfGenerated), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.exportFailed}: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  Future<void> _exportToExcel(AppLocalizations t) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.exporting)),
      );

      final locale = Localizations.localeOf(context).languageCode;
      final bytes = await ExportService.exportProductsToExcel(
        products: _productos,
        locale: locale,
      );

      await ExportService.saveAndOpenFile(
        bytes: bytes,
        fileName: 'productos_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.excelGenerated), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.exportFailed}: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    }
  }

  Widget _buildBody(AppLocalizations t) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_loading) {
      return CustomLoader(message: t.loading);
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                t.error,
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: t.loading,
                onPressed: _loadProductos,
                icon: Icons.refresh,
                fullWidth: false,
              ),
            ],
          ),
        ),
      );
    }

    if (_productos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              t.noData,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: RefreshIndicator(
          onRefresh: _loadProductos,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _productos.length,
            itemBuilder: (context, index) {
              final producto = _productos[index];
              return AnimatedListItem(
                index: index,
                child: CustomCard(
                  onTap: () async {
                    await context.push('/productos/${producto.id}');
                    _loadProductos();
                  },
                  child: Row(
                    children: [
                      ImageThumbnail(
                        imageUrl: producto.imagenUrl,
                        size: 52,
                        placeholderIcon: Icons.inventory_2,
                        placeholderColor: colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              producto.nombre,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${t.price}: \$${producto.precio.toStringAsFixed(2)} | Stock: ${producto.stock}',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (producto.categoria != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            producto.categoria!,
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
