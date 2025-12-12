import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:marketmove_app/models/producto.dart';
import 'package:marketmove_app/models/venta.dart';
import 'package:marketmove_app/models/gasto.dart';
import 'package:marketmove_app/services/data_service.dart';

// Cache for downloaded images to avoid re-downloading
final Map<String, Uint8List> _imageCache = {};

/// Service for exporting data to PDF and Excel formats.
/// Respects user roles and global view settings.
class ExportService {
  // ==================== EXCEL EXPORTS ====================

  /// Export products to Excel file
  static Future<Uint8List> exportProductsToExcel({
    required List<Producto> products,
    required String locale,
  }) async {
    final excel = Excel.createExcel();
    final sheetName = locale == 'es' ? 'Productos' : 'Products';
    
    // Remove default sheet and create new one
    excel.delete('Sheet1');
    final sheet = excel[sheetName];
    
    // Headers
    final headers = locale == 'es' 
        ? ['ID', 'Nombre', 'Precio', 'Stock', 'Categoría', 'Código de Barras']
        : ['ID', 'Name', 'Price', 'Stock', 'Category', 'Barcode'];
    
    _addHeaderRow(sheet, headers);
    
    // Data rows
    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      sheet.appendRow([
        TextCellValue(p.id?.toString() ?? ''),
        TextCellValue(p.nombre),
        DoubleCellValue(p.precio),
        IntCellValue(p.stock),
        TextCellValue(p.categoria ?? ''),
        TextCellValue(p.codigoBarras ?? ''),
      ]);
    }
    
    // Auto-fit columns
    _autoFitColumns(sheet, headers.length);
    
    return Uint8List.fromList(excel.encode()!);
  }

  /// Export sales to Excel file
  static Future<Uint8List> exportSalesToExcel({
    required List<Venta> sales,
    required String locale,
  }) async {
    final excel = Excel.createExcel();
    final sheetName = locale == 'es' ? 'Ventas' : 'Sales';
    
    excel.delete('Sheet1');
    final sheet = excel[sheetName];
    
    final headers = locale == 'es'
        ? ['ID', 'Importe', 'Fecha', 'Producto ID', 'Cantidad', 'Método de Pago', 'Comentarios']
        : ['ID', 'Amount', 'Date', 'Product ID', 'Quantity', 'Payment Method', 'Comments'];
    
    _addHeaderRow(sheet, headers);
    
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    for (int i = 0; i < sales.length; i++) {
      final s = sales[i];
      sheet.appendRow([
        TextCellValue(s.id?.toString() ?? ''),
        DoubleCellValue(s.importe),
        TextCellValue(s.fecha != null ? dateFormat.format(s.fecha!) : ''),
        TextCellValue(s.productoId?.toString() ?? ''),
        IntCellValue(s.cantidad ?? 1),
        TextCellValue(s.metodoPago ?? ''),
        TextCellValue(s.comentarios ?? ''),
      ]);
    }
    
    _autoFitColumns(sheet, headers.length);
    
    return Uint8List.fromList(excel.encode()!);
  }

  /// Export expenses to Excel file
  static Future<Uint8List> exportExpensesToExcel({
    required List<Gasto> expenses,
    required String locale,
  }) async {
    final excel = Excel.createExcel();
    final sheetName = locale == 'es' ? 'Gastos' : 'Expenses';
    
    excel.delete('Sheet1');
    final sheet = excel[sheetName];
    
    final headers = locale == 'es'
        ? ['ID', 'Importe', 'Fecha', 'Categoría', 'Método de Pago', 'Comentarios']
        : ['ID', 'Amount', 'Date', 'Category', 'Payment Method', 'Comments'];
    
    _addHeaderRow(sheet, headers);
    
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    for (int i = 0; i < expenses.length; i++) {
      final g = expenses[i];
      sheet.appendRow([
        TextCellValue(g.id?.toString() ?? ''),
        DoubleCellValue(g.importe),
        TextCellValue(g.fecha != null ? dateFormat.format(g.fecha!) : ''),
        TextCellValue(g.categoria ?? ''),
        TextCellValue(g.metodoPago ?? ''),
        TextCellValue(g.comentarios ?? ''),
      ]);
    }
    
    _autoFitColumns(sheet, headers.length);
    
    return Uint8List.fromList(excel.encode()!);
  }

  /// Export full report to Excel (all data in separate sheets)
  static Future<Uint8List> exportFullReportToExcel({
    required List<Producto> products,
    required List<Venta> sales,
    required List<Gasto> expenses,
    required double totalSales,
    required double totalExpenses,
    required double totalProfit,
    required int totalTransactions,
    required String locale,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    // Summary Sheet
    final summaryName = locale == 'es' ? 'Resumen' : 'Summary';
    final summarySheet = excel[summaryName];
    
    final summaryHeaders = locale == 'es' ? ['Métrica', 'Valor'] : ['Metric', 'Value'];
    _addHeaderRow(summarySheet, summaryHeaders);
    
    final summaryData = locale == 'es' ? [
      ['Total Productos', products.length.toString()],
      ['Total Ventas', '\$${totalSales.toStringAsFixed(2)}'],
      ['Total Gastos', '\$${totalExpenses.toStringAsFixed(2)}'],
      ['Beneficio', '\$${totalProfit.toStringAsFixed(2)}'],
      ['Total Transacciones', totalTransactions.toString()],
      ['Fecha del Informe', dateFormat.format(DateTime.now())],
    ] : [
      ['Total Products', products.length.toString()],
      ['Total Sales', '\$${totalSales.toStringAsFixed(2)}'],
      ['Total Expenses', '\$${totalExpenses.toStringAsFixed(2)}'],
      ['Profit', '\$${totalProfit.toStringAsFixed(2)}'],
      ['Total Transactions', totalTransactions.toString()],
      ['Report Date', dateFormat.format(DateTime.now())],
    ];
    
    for (var row in summaryData) {
      summarySheet.appendRow([TextCellValue(row[0]), TextCellValue(row[1])]);
    }
    _autoFitColumns(summarySheet, 2);
    
    // Products Sheet
    final productsName = locale == 'es' ? 'Productos' : 'Products';
    final productsSheet = excel[productsName];
    
    final productHeaders = locale == 'es'
        ? ['ID', 'Nombre', 'Precio', 'Stock', 'Categoría', 'Código de Barras']
        : ['ID', 'Name', 'Price', 'Stock', 'Category', 'Barcode'];
    _addHeaderRow(productsSheet, productHeaders);
    
    for (var p in products) {
      productsSheet.appendRow([
        TextCellValue(p.id?.toString() ?? ''),
        TextCellValue(p.nombre),
        DoubleCellValue(p.precio),
        IntCellValue(p.stock),
        TextCellValue(p.categoria ?? ''),
        TextCellValue(p.codigoBarras ?? ''),
      ]);
    }
    _autoFitColumns(productsSheet, productHeaders.length);
    
    // Sales Sheet
    final salesName = locale == 'es' ? 'Ventas' : 'Sales';
    final salesSheet = excel[salesName];
    
    final salesHeaders = locale == 'es'
        ? ['ID', 'Importe', 'Fecha', 'Producto ID', 'Cantidad', 'Método de Pago', 'Comentarios']
        : ['ID', 'Amount', 'Date', 'Product ID', 'Quantity', 'Payment Method', 'Comments'];
    _addHeaderRow(salesSheet, salesHeaders);
    
    for (var s in sales) {
      salesSheet.appendRow([
        TextCellValue(s.id?.toString() ?? ''),
        DoubleCellValue(s.importe),
        TextCellValue(s.fecha != null ? dateFormat.format(s.fecha!) : ''),
        TextCellValue(s.productoId?.toString() ?? ''),
        IntCellValue(s.cantidad ?? 1),
        TextCellValue(s.metodoPago ?? ''),
        TextCellValue(s.comentarios ?? ''),
      ]);
    }
    _autoFitColumns(salesSheet, salesHeaders.length);
    
    // Expenses Sheet
    final expensesName = locale == 'es' ? 'Gastos' : 'Expenses';
    final expensesSheet = excel[expensesName];
    
    final expensesHeaders = locale == 'es'
        ? ['ID', 'Importe', 'Fecha', 'Categoría', 'Método de Pago', 'Comentarios']
        : ['ID', 'Amount', 'Date', 'Category', 'Payment Method', 'Comments'];
    _addHeaderRow(expensesSheet, expensesHeaders);
    
    for (var g in expenses) {
      expensesSheet.appendRow([
        TextCellValue(g.id?.toString() ?? ''),
        DoubleCellValue(g.importe),
        TextCellValue(g.fecha != null ? dateFormat.format(g.fecha!) : ''),
        TextCellValue(g.categoria ?? ''),
        TextCellValue(g.metodoPago ?? ''),
        TextCellValue(g.comentarios ?? ''),
      ]);
    }
    _autoFitColumns(expensesSheet, expensesHeaders.length);
    
    return Uint8List.fromList(excel.encode()!);
  }

  // ==================== PDF EXPORTS ====================

  /// Export products to PDF
  static Future<Uint8List> exportProductsToPDF({
    required List<Producto> products,
    required String locale,
    required String title,
    required String generatedByText,
    required String pageText,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final now = DateTime.now();
    
    final headers = locale == 'es'
        ? ['ID', 'Nombre', 'Precio', 'Stock', 'Categoría']
        : ['ID', 'Name', 'Price', 'Stock', 'Category'];
    
    // Split products into pages (max 25 per page)
    final itemsPerPage = 25;
    final totalPages = (products.length / itemsPerPage).ceil();
    
    for (int page = 0; page < totalPages || page == 0; page++) {
      final startIndex = page * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage > products.length) 
          ? products.length 
          : startIndex + itemsPerPage;
      final pageProducts = products.isEmpty ? <Producto>[] : products.sublist(startIndex, endIndex);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                if (page == 0) ...[
                  _buildPdfHeader(title, dateFormat.format(now), locale),
                  pw.SizedBox(height: 20),
                ],
                
                // Table
                if (pageProducts.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headers: headers,
                    data: pageProducts.map((p) => [
                      p.id?.toString() ?? '',
                      p.nombre,
                      '\$${p.precio.toStringAsFixed(2)}',
                      p.stock.toString(),
                      p.categoria ?? '',
                    ]).toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF1976D2),
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellPadding: const pw.EdgeInsets.all(6),
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                  )
                else
                  pw.Center(
                    child: pw.Text(
                      locale == 'es' ? 'No hay datos' : 'No data',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ),
                
                pw.Spacer(),
                
                // Footer
                _buildPdfFooter(generatedByText, pageText, page + 1, totalPages == 0 ? 1 : totalPages),
              ],
            );
          },
        ),
      );
    }
    
    return pdf.save();
  }

  /// Export sales to PDF
  static Future<Uint8List> exportSalesToPDF({
    required List<Venta> sales,
    required String locale,
    required String title,
    required String generatedByText,
    required String pageText,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dateOnlyFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    
    final headers = locale == 'es'
        ? ['ID', 'Importe', 'Fecha', 'Cantidad', 'Método Pago']
        : ['ID', 'Amount', 'Date', 'Quantity', 'Payment'];
    
    final itemsPerPage = 25;
    final totalPages = (sales.length / itemsPerPage).ceil();
    
    for (int page = 0; page < totalPages || page == 0; page++) {
      final startIndex = page * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage > sales.length) 
          ? sales.length 
          : startIndex + itemsPerPage;
      final pageSales = sales.isEmpty ? <Venta>[] : sales.sublist(startIndex, endIndex);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (page == 0) ...[
                  _buildPdfHeader(title, dateFormat.format(now), locale),
                  pw.SizedBox(height: 20),
                ],
                
                if (pageSales.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headers: headers,
                    data: pageSales.map((s) => [
                      s.id?.toString() ?? '',
                      '\$${s.importe.toStringAsFixed(2)}',
                      s.fecha != null ? dateOnlyFormat.format(s.fecha!) : '',
                      (s.cantidad ?? 1).toString(),
                      s.metodoPago ?? '',
                    ]).toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF1976D2),
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellPadding: const pw.EdgeInsets.all(6),
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                  )
                else
                  pw.Center(
                    child: pw.Text(
                      locale == 'es' ? 'No hay datos' : 'No data',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ),
                
                pw.Spacer(),
                _buildPdfFooter(generatedByText, pageText, page + 1, totalPages == 0 ? 1 : totalPages),
              ],
            );
          },
        ),
      );
    }
    
    return pdf.save();
  }

  /// Export expenses to PDF
  static Future<Uint8List> exportExpensesToPDF({
    required List<Gasto> expenses,
    required String locale,
    required String title,
    required String generatedByText,
    required String pageText,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dateOnlyFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    
    final headers = locale == 'es'
        ? ['ID', 'Importe', 'Fecha', 'Categoría', 'Método Pago']
        : ['ID', 'Amount', 'Date', 'Category', 'Payment'];
    
    final itemsPerPage = 25;
    final totalPages = (expenses.length / itemsPerPage).ceil();
    
    for (int page = 0; page < totalPages || page == 0; page++) {
      final startIndex = page * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage > expenses.length) 
          ? expenses.length 
          : startIndex + itemsPerPage;
      final pageExpenses = expenses.isEmpty ? <Gasto>[] : expenses.sublist(startIndex, endIndex);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (page == 0) ...[
                  _buildPdfHeader(title, dateFormat.format(now), locale),
                  pw.SizedBox(height: 20),
                ],
                
                if (pageExpenses.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headers: headers,
                    data: pageExpenses.map((g) => [
                      g.id?.toString() ?? '',
                      '\$${g.importe.toStringAsFixed(2)}',
                      g.fecha != null ? dateOnlyFormat.format(g.fecha!) : '',
                      g.categoria ?? '',
                      g.metodoPago ?? '',
                    ]).toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF1976D2),
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 10),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellPadding: const pw.EdgeInsets.all(6),
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                  )
                else
                  pw.Center(
                    child: pw.Text(
                      locale == 'es' ? 'No hay datos' : 'No data',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ),
                
                pw.Spacer(),
                _buildPdfFooter(generatedByText, pageText, page + 1, totalPages == 0 ? 1 : totalPages),
              ],
            );
          },
        ),
      );
    }
    
    return pdf.save();
  }

  /// Export full report to PDF
  static Future<Uint8List> exportFullReportToPDF({
    required List<Producto> products,
    required List<Venta> sales,
    required List<Gasto> expenses,
    required double totalSales,
    required double totalExpenses,
    required double totalProfit,
    required int totalTransactions,
    required String locale,
    required String title,
    required String summaryTitle,
    required String generatedByText,
    required String pageText,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final dateOnlyFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    
    int currentPage = 1;
    int totalPages = 1; // Cover + summary
    
    // Calculate total pages
    final itemsPerPage = 20;
    totalPages += (products.length / itemsPerPage).ceil().clamp(1, 999);
    totalPages += (sales.length / itemsPerPage).ceil().clamp(1, 999);
    totalPages += (expenses.length / itemsPerPage).ceil().clamp(1, 999);
    
    // Cover Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(30),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFF1976D2),
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'MarketMove',
                      style: pw.TextStyle(
                        fontSize: 42,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      title,
                      style: const pw.TextStyle(
                        fontSize: 24,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                dateFormat.format(now),
                style: const pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 60),
              
              // KPI Summary Box
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      summaryTitle,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildKpiBox(
                          locale == 'es' ? 'Productos' : 'Products',
                          products.length.toString(),
                          const PdfColor.fromInt(0xFF6366F1),
                        ),
                        _buildKpiBox(
                          locale == 'es' ? 'Ventas' : 'Sales',
                          '\$${totalSales.toStringAsFixed(2)}',
                          const PdfColor.fromInt(0xFF4CAF50),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 15),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      children: [
                        _buildKpiBox(
                          locale == 'es' ? 'Gastos' : 'Expenses',
                          '\$${totalExpenses.toStringAsFixed(2)}',
                          const PdfColor.fromInt(0xFFE53935),
                        ),
                        _buildKpiBox(
                          locale == 'es' ? 'Beneficio' : 'Profit',
                          '\$${totalProfit.toStringAsFixed(2)}',
                          totalProfit >= 0 
                              ? const PdfColor.fromInt(0xFF1976D2)
                              : const PdfColor.fromInt(0xFFFFA726),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.Spacer(),
              _buildPdfFooter(generatedByText, pageText, currentPage, totalPages),
            ],
          );
        },
      ),
    );
    currentPage++;
    
    // Products Pages
    final productHeaders = locale == 'es'
        ? ['ID', 'Nombre', 'Precio', 'Stock', 'Categoría']
        : ['ID', 'Name', 'Price', 'Stock', 'Category'];
    
    final productPages = (products.length / itemsPerPage).ceil();
    for (int page = 0; page < productPages || page == 0; page++) {
      final startIndex = page * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage > products.length) 
          ? products.length 
          : startIndex + itemsPerPage;
      final pageProducts = products.isEmpty ? <Producto>[] : products.sublist(startIndex, endIndex);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (page == 0)
                  pw.Text(
                    locale == 'es' ? 'Productos' : 'Products',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF1976D2),
                    ),
                  ),
                pw.SizedBox(height: 15),
                
                if (pageProducts.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headers: productHeaders,
                    data: pageProducts.map((p) => [
                      p.id?.toString() ?? '',
                      p.nombre,
                      '\$${p.precio.toStringAsFixed(2)}',
                      p.stock.toString(),
                      p.categoria ?? '',
                    ]).toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF1976D2),
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellPadding: const pw.EdgeInsets.all(5),
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                  )
                else
                  pw.Text(locale == 'es' ? 'No hay productos' : 'No products'),
                
                pw.Spacer(),
                _buildPdfFooter(generatedByText, pageText, currentPage, totalPages),
              ],
            );
          },
        ),
      );
      currentPage++;
    }
    
    // Sales Pages
    final salesHeaders = locale == 'es'
        ? ['ID', 'Importe', 'Fecha', 'Cantidad', 'Método']
        : ['ID', 'Amount', 'Date', 'Qty', 'Method'];
    
    final salesPages = (sales.length / itemsPerPage).ceil();
    for (int page = 0; page < salesPages || page == 0; page++) {
      final startIndex = page * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage > sales.length) 
          ? sales.length 
          : startIndex + itemsPerPage;
      final pageSales = sales.isEmpty ? <Venta>[] : sales.sublist(startIndex, endIndex);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (page == 0)
                  pw.Text(
                    locale == 'es' ? 'Ventas' : 'Sales',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF4CAF50),
                    ),
                  ),
                pw.SizedBox(height: 15),
                
                if (pageSales.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headers: salesHeaders,
                    data: pageSales.map((s) => [
                      s.id?.toString() ?? '',
                      '\$${s.importe.toStringAsFixed(2)}',
                      s.fecha != null ? dateOnlyFormat.format(s.fecha!) : '',
                      (s.cantidad ?? 1).toString(),
                      s.metodoPago ?? '',
                    ]).toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF4CAF50),
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellPadding: const pw.EdgeInsets.all(5),
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                  )
                else
                  pw.Text(locale == 'es' ? 'No hay ventas' : 'No sales'),
                
                pw.Spacer(),
                _buildPdfFooter(generatedByText, pageText, currentPage, totalPages),
              ],
            );
          },
        ),
      );
      currentPage++;
    }
    
    // Expenses Pages
    final expensesHeaders = locale == 'es'
        ? ['ID', 'Importe', 'Fecha', 'Categoría', 'Método']
        : ['ID', 'Amount', 'Date', 'Category', 'Method'];
    
    final expensesPages = (expenses.length / itemsPerPage).ceil();
    for (int page = 0; page < expensesPages || page == 0; page++) {
      final startIndex = page * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage > expenses.length) 
          ? expenses.length 
          : startIndex + itemsPerPage;
      final pageExpenses = expenses.isEmpty ? <Gasto>[] : expenses.sublist(startIndex, endIndex);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (page == 0)
                  pw.Text(
                    locale == 'es' ? 'Gastos' : 'Expenses',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFFE53935),
                    ),
                  ),
                pw.SizedBox(height: 15),
                
                if (pageExpenses.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    context: context,
                    headers: expensesHeaders,
                    data: pageExpenses.map((g) => [
                      g.id?.toString() ?? '',
                      '\$${g.importe.toStringAsFixed(2)}',
                      g.fecha != null ? dateOnlyFormat.format(g.fecha!) : '',
                      g.categoria ?? '',
                      g.metodoPago ?? '',
                    ]).toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFE53935),
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellPadding: const pw.EdgeInsets.all(5),
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                  )
                else
                  pw.Text(locale == 'es' ? 'No hay gastos' : 'No expenses'),
                
                pw.Spacer(),
                _buildPdfFooter(generatedByText, pageText, currentPage, totalPages),
              ],
            );
          },
        ),
      );
      currentPage++;
    }
    
    return pdf.save();
  }

  // ==================== HELPER METHODS ====================

  /// Add header row with blue background to Excel sheet
  static void _addHeaderRow(Sheet sheet, List<String> headers) {
    final headerStyle = CellStyle(
      backgroundColorHex: ExcelColor.fromHexString('#1976D2'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );
    
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
  }

  /// Auto-fit columns in Excel sheet
  static void _autoFitColumns(Sheet sheet, int columnCount) {
    for (int i = 0; i < columnCount; i++) {
      sheet.setColumnWidth(i, 18);
    }
  }

  /// Build PDF header widget
  static pw.Widget _buildPdfHeader(String title, String date, String locale) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF1976D2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MarketMove',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                title,
                style: const pw.TextStyle(
                  fontSize: 14,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Text(
            date,
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build PDF footer widget
  static pw.Widget _buildPdfFooter(String generatedByText, String pageText, int currentPage, int totalPages) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            generatedByText,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            '$pageText $currentPage / $totalPages',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build KPI box for PDF cover page
  static pw.Widget _buildKpiBox(String label, String value, PdfColor color) {
    return pw.Container(
      width: 180,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FILE SAVING ====================

  /// Save file and open/share it
  static Future<void> saveAndOpenFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      // For web, use printing package to handle download
      if (fileName.endsWith('.pdf')) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      } else {
        // For Excel on web, we'll use a different approach
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    } else {
      // For mobile/desktop
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      // Open the file
      // Note: open_file package handles opening
      // For now, we'll use printing for PDF preview
      if (fileName.endsWith('.pdf')) {
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    }
  }

  /// Preview PDF using printing package
  static Future<void> previewPdf(Uint8List bytes) async {
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  /// Share PDF using printing package
  static Future<void> sharePdf(Uint8List bytes, String filename) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  // ==================== IMAGE HELPERS ====================

  /// Download image from URL and return bytes
  /// Returns null if download fails
  static Future<Uint8List?> _downloadImage(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    // Check cache first
    if (_imageCache.containsKey(imageUrl)) {
      return _imageCache[imageUrl];
    }
    
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        _imageCache[imageUrl] = response.bodyBytes;
        return response.bodyBytes;
      }
    } catch (e) {
      print('[ExportService] Failed to download image: $e');
    }
    return null;
  }

  /// Create a PDF image widget from URL
  /// Returns a placeholder if image cannot be loaded
  static Future<pw.Widget> _buildPdfImage(String? imageUrl, {double width = 40, double height = 40}) async {
    final bytes = await _downloadImage(imageUrl);
    
    if (bytes != null) {
      try {
        final image = pw.MemoryImage(bytes);
        return pw.Container(
          width: width,
          height: height,
          child: pw.Image(image, fit: pw.BoxFit.cover),
        );
      } catch (e) {
        print('[ExportService] Failed to create PDF image: $e');
      }
    }
    
    // Return placeholder
    return pw.Container(
      width: width,
      height: height,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Center(
        child: pw.Text('📷', style: const pw.TextStyle(fontSize: 16)),
      ),
    );
  }

  /// Clear image cache
  static void clearImageCache() {
    _imageCache.clear();
  }

  // ==================== DATA LOADING HELPERS ====================

  /// Load all data for full report export
  static Future<Map<String, dynamic>> loadAllDataForExport() async {
    final results = await Future.wait([
      DataService.getProductos(),
      DataService.getVentas(),
      DataService.getGastos(),
      DataService.getTotalVentas(),
      DataService.getTotalGastos(),
      DataService.getTotalTransactions(),
    ]);

    final products = results[0] as List<Producto>;
    final sales = results[1] as List<Venta>;
    final expenses = results[2] as List<Gasto>;
    final totalSales = results[3] as double;
    final totalExpenses = results[4] as double;
    final totalTransactions = results[5] as int;
    final totalProfit = totalSales - totalExpenses;

    return {
      'products': products,
      'sales': sales,
      'expenses': expenses,
      'totalSales': totalSales,
      'totalExpenses': totalExpenses,
      'totalProfit': totalProfit,
      'totalTransactions': totalTransactions,
    };
  }
}
