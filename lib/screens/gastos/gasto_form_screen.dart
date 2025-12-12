import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:marketmove_app/l10n/app_localizations.dart';
import 'package:marketmove_app/models/gasto.dart';
import 'package:marketmove_app/services/data_service.dart';
import 'package:marketmove_app/widgets/custom_app_bar.dart';
import 'package:marketmove_app/widgets/custom_card.dart';
import 'package:marketmove_app/widgets/custom_text_field.dart';
import 'package:marketmove_app/widgets/custom_button.dart';
import 'package:marketmove_app/widgets/custom_loader.dart';
import 'package:marketmove_app/widgets/image_picker_card.dart';
import 'package:marketmove_app/services/image_service.dart';
import 'dart:typed_data';

class GastoFormScreen extends StatefulWidget {
  final String? gastoId;

  const GastoFormScreen({super.key, this.gastoId});

  @override
  State<GastoFormScreen> createState() => _GastoFormScreenState();
}

class _GastoFormScreenState extends State<GastoFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _importeController = TextEditingController();
  final _comentariosController = TextEditingController();

  bool _loading = false;
  bool _loadingData = false;
  bool _uploadingImage = false;
  Gasto? _gasto;
  String? _selectedCategoria;
  String? _selectedMetodoPago;
  DateTime _selectedFecha = DateTime.now();
  String? _imagenUrl;
  Uint8List? _pendingImageBytes;
  String? _pendingImageName;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  final List<String> _categorias = ['Alquiler', 'Servicios', 'Suministros', 'Transporte', 'Marketing', 'Otro'];
  final List<String> _metodosPago = ['Efectivo', 'Tarjeta', 'Transferencia', 'Otro'];

  bool get isEditing => widget.gastoId != null;

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
    
    if (isEditing) {
      _loadGasto();
    } else {
      _animController.forward();
    }
  }

  Future<void> _loadGasto() async {
    setState(() => _loadingData = true);
    try {
      final id = int.tryParse(widget.gastoId!);
      if (id != null) {
        final gasto = await DataService.getGasto(id);
        if (gasto != null) {
          setState(() {
            _gasto = gasto;
            _importeController.text = gasto.importe.toString();
            _comentariosController.text = gasto.comentarios ?? '';
            _selectedCategoria = gasto.categoria;
            _selectedMetodoPago = gasto.metodoPago;
            _selectedFecha = gasto.fecha ?? DateTime.now();
            _imagenUrl = gasto.imagenUrl;
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

  Future<void> _onImagePicked(Uint8List bytes, String fileName) async {
    setState(() {
      _pendingImageBytes = bytes;
      _pendingImageName = fileName;
    });
  }

  Future<void> _onImageDeleted() async {
    setState(() {
      _pendingImageBytes = null;
      _pendingImageName = null;
      _imagenUrl = null;
    });
  }

  Future<String?> _uploadImageIfNeeded() async {
    if (_pendingImageBytes != null && _pendingImageName != null) {
      setState(() => _uploadingImage = true);
      final url = await ImageService.uploadAndReplace(
        fileBytes: _pendingImageBytes!,
        fileName: _pendingImageName!,
        folder: 'gastos',
        previousUrl: _gasto?.imagenUrl,
      );
      setState(() => _uploadingImage = false);
      return url;
    }
    return _imagenUrl;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // Upload image if pending
      final finalImageUrl = await _uploadImageIfNeeded();

      // If image was deleted, also delete from storage
      if (_imagenUrl == null && _gasto?.imagenUrl != null && _pendingImageBytes == null) {
        await ImageService.deleteImage(_gasto!.imagenUrl);
      }

      final gasto = Gasto(
        id: _gasto?.id,
        importe: double.parse(_importeController.text),
        fecha: _selectedFecha,
        categoria: _selectedCategoria,
        metodoPago: _selectedMetodoPago,
        comentarios: _comentariosController.text.trim().isEmpty 
            ? null 
            : _comentariosController.text.trim(),
        imagenUrl: finalImageUrl,
      );

      if (isEditing) {
        await DataService.updateGasto(gasto);
      } else {
        await DataService.createGasto(gasto);
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
        appBar: CustomAppBar(title: isEditing ? t.editExpense : t.newExpense),
        body: CustomLoader(message: t.loading),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing ? t.editExpense : t.newExpense,
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
                        isEditing ? t.editExpense : t.newExpense,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Image Picker for ticket/receipt
                      Center(
                        child: ImagePickerCard(
                          imageUrl: _pendingImageBytes != null ? null : _imagenUrl,
                          imageType: 'expense',
                          onImagePicked: _onImagePicked,
                          onImageDeleted: _onImageDeleted,
                          isLoading: _uploadingImage,
                          size: 150,
                        ),
                      ),
                      if (_pendingImageBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Center(
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _pendingImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
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
                      Builder(
                        builder: (context) {
                          final validCategoria = _categorias.contains(_selectedCategoria) ? _selectedCategoria : null;
                          return DropdownButtonFormField<String>(
                            value: validCategoria,
                            hint: Text(t.selectOption),
                            decoration: InputDecoration(
                              labelText: t.category,
                              prefixIcon: Icon(Icons.category, color: colorScheme.primary),
                            ),
                            items: _categorias.map((c) {
                              return DropdownMenuItem(value: c, child: Text(c));
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedCategoria = v),
                            validator: (v) => v == null ? t.requiredField : null,
                          );
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
