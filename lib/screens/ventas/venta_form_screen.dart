import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:marketmove_app/l10n/app_localizations.dart';
import 'package:marketmove_app/models/venta.dart';
import 'package:marketmove_app/models/producto.dart';
import 'package:marketmove_app/services/data_service.dart';
import 'package:marketmove_app/widgets/custom_app_bar.dart';
import 'package:marketmove_app/widgets/custom_card.dart';
import 'package:marketmove_app/widgets/custom_text_field.dart';
import 'package:marketmove_app/widgets/custom_button.dart';
import 'package:marketmove_app/widgets/custom_loader.dart';

class VentaFormScreen extends StatefulWidget {
  final String? ventaId;

  const VentaFormScreen({super.key, this.ventaId});

  @override
  State<VentaFormScreen> createState() => _VentaFormScreenState();
}

class _VentaFormScreenState extends State<VentaFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _importeController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _comentariosController = TextEditingController();

  bool _loading = false;
  bool _loadingData = false;
  Venta? _venta;
  List<Producto> _productos = [];
  int? _selectedProductoId;
  String? _selectedMetodoPago;
  DateTime _selectedFecha = DateTime.now();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final List<String> _metodosPago = ['Efectivo', 'Tarjeta', 'Transferencia', 'Otro'];

  bool get isEditing => widget.ventaId != null;

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
    
    _loadProductos();
    if (isEditing) {
      _loadVenta();
    } else {
      _animController.forward();
    }
  }

  Future<void> _loadProductos() async {
    try {
      final productos = await DataService.getProductos();
      setState(() => _productos = productos);
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadVenta() async {
    setState(() => _loadingData = true);
    try {
      final id = int.tryParse(widget.ventaId!);
      if (id != null) {
        final venta = await DataService.getVenta(id);
        if (venta != null) {
          setState(() {
            _venta = venta;
            _importeController.text = venta.importe.toString();
            _cantidadController.text = venta.cantidad.toString();
            _comentariosController.text = venta.comentarios ?? '';
            _selectedProductoId = venta.productoId;
            _selectedMetodoPago = venta.metodoPago;
            _selectedFecha = venta.fecha ?? DateTime.now();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
    setState(() => _loadingData = false);
    _animController.forward();
  }

  Future<void> _selectFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedFecha = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final venta = Venta(
        id: _venta?.id,
        importe: double.parse(_importeController.text),
        fecha: _selectedFecha,
        productoId: _selectedProductoId,
        cantidad: int.parse(_cantidadController.text),
        metodoPago: _selectedMetodoPago,
        comentarios: _comentariosController.text.trim().isEmpty 
            ? null 
            : _comentariosController.text.trim(),
      );

      if (isEditing) {
        await DataService.updateVenta(venta);
      } else {
        await DataService.createVenta(venta);
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _animController.dispose();
    _importeController.dispose();
    _cantidadController.dispose();
    _comentariosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    if (_loadingData) {
      return Scaffold(
        appBar: CustomAppBar(title: isEditing ? t.editSale : t.newSale),
        body: CustomLoader(message: t.loading),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing ? t.editSale : t.newSale,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: CustomCard(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? t.editSale : t.newSale,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Builder(
                        builder: (context) {
                          final productIds = _productos.map((p) => p.id).toList();
                          final validProductoId = productIds.contains(_selectedProductoId) ? _selectedProductoId : null;
                          return DropdownButtonFormField<int>(
                            value: validProductoId,
                            hint: Text(t.selectOption),
                            decoration: InputDecoration(
                              labelText: t.product,
                              prefixIcon: Icon(Icons.inventory_2, color: colorScheme.primary),
                            ),
                            items: _productos.map((p) {
                              return DropdownMenuItem(
                                value: p.id,
                                child: Text(p.nombre),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedProductoId = v),
                            validator: (v) => v == null ? t.requiredField : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _importeController,
                        labelText: t.amount,
                        prefixIcon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return t.requiredField;
                          final n = double.tryParse(v);
                          if (n == null || n <= 0) return t.invalidValue;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _cantidadController,
                        labelText: t.quantity,
                        prefixIcon: Icons.numbers,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return t.requiredField;
                          final n = int.tryParse(v);
                          if (n == null || n <= 0) return t.invalidValue;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final validMetodoPago = _metodosPago.contains(_selectedMetodoPago) ? _selectedMetodoPago : null;
                          return DropdownButtonFormField<String>(
                            value: validMetodoPago,
                            hint: Text(t.selectOption),
                            decoration: InputDecoration(
                              labelText: t.paymentMethod,
                              prefixIcon: Icon(Icons.payment, color: colorScheme.primary),
                            ),
                            items: _metodosPago.map((m) {
                              return DropdownMenuItem(value: m, child: Text(m));
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedMetodoPago = v),
                            validator: (v) => v == null ? t.requiredField : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomCard(
                        margin: EdgeInsets.zero,
                        onTap: _selectFecha,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.calendar_today, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.date,
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    dateFormat.format(_selectedFecha),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.edit, color: colorScheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _comentariosController,
                        labelText: t.comments,
                        prefixIcon: Icons.comment_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: t.save,
                        onPressed: _save,
                        isLoading: _loading,
                        icon: Icons.save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
