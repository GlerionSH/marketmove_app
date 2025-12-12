import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:marketmove_app/l10n/app_localizations.dart';
import 'package:marketmove_app/models/producto.dart';
import 'package:marketmove_app/services/data_service.dart';
import 'package:marketmove_app/widgets/custom_app_bar.dart';
import 'package:marketmove_app/widgets/custom_card.dart';
import 'package:marketmove_app/widgets/custom_text_field.dart';
import 'package:marketmove_app/widgets/custom_button.dart';
import 'package:marketmove_app/widgets/custom_loader.dart';
import 'package:marketmove_app/widgets/image_picker_card.dart';
import 'package:marketmove_app/services/image_service.dart';
import 'dart:typed_data';

class ProductoFormScreen extends StatefulWidget {
  final String? productoId;

  const ProductoFormScreen({super.key, this.productoId});

  @override
  State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _codigoBarrasController = TextEditingController();

  bool _loading = false;
  bool _loadingData = false;
  bool _uploadingImage = false;
  Producto? _producto;
  String? _imagenUrl;
  Uint8List? _pendingImageBytes;
  String? _pendingImageName;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  bool get isEditing => widget.productoId != null;

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
      _loadProducto();
    } else {
      _animController.forward();
    }
  }

  Future<void> _loadProducto() async {
    setState(() => _loadingData = true);
    try {
      final id = int.tryParse(widget.productoId!);
      if (id != null) {
        final producto = await DataService.getProducto(id);
        if (producto != null) {
          setState(() {
            _producto = producto;
            _nombreController.text = producto.nombre;
            _precioController.text = producto.precio.toString();
            _stockController.text = producto.stock.toString();
            _categoriaController.text = producto.categoria ?? '';
            _codigoBarrasController.text = producto.codigoBarras ?? '';
            _imagenUrl = producto.imagenUrl;
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
        folder: 'productos',
        previousUrl: _producto?.imagenUrl,
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
      if (_imagenUrl == null && _producto?.imagenUrl != null && _pendingImageBytes == null) {
        await ImageService.deleteImage(_producto!.imagenUrl);
      }

      final producto = Producto(
        id: _producto?.id,
        nombre: _nombreController.text.trim(),
        precio: double.parse(_precioController.text),
        stock: int.parse(_stockController.text),
        categoria: _categoriaController.text.trim().isEmpty ? null : _categoriaController.text.trim(),
        codigoBarras: _codigoBarrasController.text.trim().isEmpty ? null : _codigoBarrasController.text.trim(),
        imagenUrl: finalImageUrl,
      );

      if (isEditing) {
        await DataService.updateProducto(producto);
      } else {
        await DataService.createProducto(producto);
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
    _nombreController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    _categoriaController.dispose();
    _codigoBarrasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (_loadingData) {
      return Scaffold(
        appBar: CustomAppBar(title: isEditing ? t.editProduct : t.newProduct),
        body: CustomLoader(message: t.loading),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: isEditing ? t.editProduct : t.newProduct,
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
                        isEditing ? t.editProduct : t.newProduct,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Image Picker
                      Center(
                        child: ImagePickerCard(
                          imageUrl: _pendingImageBytes != null ? null : _imagenUrl,
                          imageType: 'product',
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
                        controller: _nombreController,
                        labelText: t.name,
                        prefixIcon: Icons.label_outline,
                        validator: (v) => v == null || v.trim().isEmpty ? t.requiredField : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _precioController,
                        labelText: t.price,
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
                        controller: _stockController,
                        labelText: t.stock,
                        prefixIcon: Icons.inventory,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return t.requiredField;
                          final n = int.tryParse(v);
                          if (n == null || n < 0) return t.invalidValue;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _categoriaController,
                        labelText: t.category,
                        prefixIcon: Icons.category_outlined,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _codigoBarrasController,
                        labelText: t.barcode,
                        prefixIcon: Icons.qr_code,
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
