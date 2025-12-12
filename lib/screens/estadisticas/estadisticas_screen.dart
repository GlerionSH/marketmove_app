import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:marketmove_app/l10n/app_localizations.dart';
import 'package:marketmove_app/services/data_service.dart';
import 'package:marketmove_app/services/session_service.dart';
import 'package:marketmove_app/widgets/custom_app_bar.dart';
import 'package:marketmove_app/widgets/custom_card.dart';
import 'package:marketmove_app/widgets/custom_loader.dart';
import 'package:marketmove_app/widgets/animated_list_item.dart';
import 'package:marketmove_app/widgets/global_view_toggle.dart';
import 'package:marketmove_app/services/export_service.dart';
import 'package:marketmove_app/models/producto.dart';
import 'package:marketmove_app/models/venta.dart';
import 'package:marketmove_app/models/gasto.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> with TickerProviderStateMixin {
  bool _loading = true;
  bool _isSuperAdmin = false;
  
  // KPI Data
  double _totalVentas = 0;
  double _totalGastos = 0;
  int _totalProductos = 0;
  int _totalTransactions = 0;
  
  // Chart Data
  Map<String, double> _ventasPorMes = {};
  Map<String, double> _gastosPorMes = {};
  Map<String, double> _profitPorMes = {};
  List<Map<String, dynamic>> _topProducts = [];
  Map<String, double> _paymentMethodStats = {};
  Map<String, double> _stockEvolution = {};

  // Animation controllers
  late AnimationController _kpiAnimationController;
  late Animation<double> _kpiAnimation;

  @override
  void initState() {
    super.initState();
    _kpiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _kpiAnimation = CurvedAnimation(
      parent: _kpiAnimationController,
      curve: Curves.easeOutCubic,
    );
    _loadData();
  }

  @override
  void dispose() {
    _kpiAnimationController.dispose();
    super.dispose();
  }

  void _showExportDialog(AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.exportFullReport),
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
      final data = await ExportService.loadAllDataForExport();

      final bytes = await ExportService.exportFullReportToPDF(
        products: data['products'] as List<Producto>,
        sales: data['sales'] as List<Venta>,
        expenses: data['expenses'] as List<Gasto>,
        totalSales: data['totalSales'] as double,
        totalExpenses: data['totalExpenses'] as double,
        totalProfit: data['totalProfit'] as double,
        totalTransactions: data['totalTransactions'] as int,
        locale: locale,
        title: t.fullReport,
        summaryTitle: t.summaryReport,
        generatedByText: t.generatedBy,
        pageText: t.page,
      );

      await ExportService.sharePdf(bytes, 'informe_completo_${DateTime.now().millisecondsSinceEpoch}.pdf');

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
      final data = await ExportService.loadAllDataForExport();

      final bytes = await ExportService.exportFullReportToExcel(
        products: data['products'] as List<Producto>,
        sales: data['sales'] as List<Venta>,
        expenses: data['expenses'] as List<Gasto>,
        totalSales: data['totalSales'] as double,
        totalExpenses: data['totalExpenses'] as double,
        totalProfit: data['totalProfit'] as double,
        totalTransactions: data['totalTransactions'] as int,
        locale: locale,
      );

      await ExportService.saveAndOpenFile(
        bytes: bytes,
        fileName: 'informe_completo_${DateTime.now().millisecondsSinceEpoch}.xlsx',
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

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      _isSuperAdmin = await SessionService.isSuperAdmin();
      
      final results = await Future.wait([
        DataService.getTotalVentas(),
        DataService.getTotalGastos(),
        DataService.getTotalProductos(),
        DataService.getTotalTransactions(),
        DataService.getVentasPorMes(),
        DataService.getGastosPorMes(),
        DataService.getProfitByMonth(),
        DataService.getTopProducts(limit: 5),
        DataService.getPaymentMethodStats(),
        DataService.getStockEvolution(),
      ]);

      setState(() {
        _totalVentas = results[0] as double;
        _totalGastos = results[1] as double;
        _totalProductos = results[2] as int;
        _totalTransactions = results[3] as int;
        _ventasPorMes = results[4] as Map<String, double>;
        _gastosPorMes = results[5] as Map<String, double>;
        _profitPorMes = results[6] as Map<String, double>;
        _topProducts = results[7] as List<Map<String, dynamic>>;
        _paymentMethodStats = results[8] as Map<String, double>;
        _stockEvolution = results[9] as Map<String, double>;
        _loading = false;
      });
      
      _kpiAnimationController.forward(from: 0);
    } catch (e) {
      print("❌ ERROR en _loadData: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final beneficio = _totalVentas - _totalGastos;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: CustomAppBar(
        title: t.dashboard,
        onBackPressed: () => context.go('/home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _showExportDialog(t),
            tooltip: t.exportFullReport,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: t.retry,
          ),
        ],
      ),
      body: _loading
          ? CustomLoader(message: t.loading)
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SuperAdmin Toggle
                        if (_isSuperAdmin)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: GlobalViewToggle(onChanged: _loadData),
                          ),
                        
                        // KPI Cards Section
                        _buildKPISection(t, beneficio, isWideScreen),
                        
                        const SizedBox(height: 24),
                        
                        // Charts Section
                        _buildChartsSection(t, isWideScreen),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildKPISection(AppLocalizations t, double beneficio, bool isWideScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final kpis = [
      _KPIData(
        title: t.totalProducts,
        value: _totalProductos.toDouble(),
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF6366F1),
        prefix: '',
        suffix: '',
        isInteger: true,
      ),
      _KPIData(
        title: t.totalSales,
        value: _totalVentas,
        icon: Icons.trending_up_rounded,
        color: Colors.green,
        prefix: '\$',
        suffix: '',
      ),
      _KPIData(
        title: t.totalExpenses,
        value: _totalGastos,
        icon: Icons.trending_down_rounded,
        color: colorScheme.error,
        prefix: '\$',
        suffix: '',
      ),
      _KPIData(
        title: t.totalProfit,
        value: beneficio,
        icon: beneficio >= 0 ? Icons.account_balance_wallet_outlined : Icons.money_off_outlined,
        color: beneficio >= 0 ? colorScheme.primary : Colors.orange,
        prefix: '\$',
        suffix: '',
      ),
      _KPIData(
        title: t.totalTransactions,
        value: _totalTransactions.toDouble(),
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF8B5CF6),
        prefix: '',
        suffix: '',
        isInteger: true,
      ),
    ];

    if (isWideScreen) {
      return Row(
        children: kpis.asMap().entries.map((entry) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: entry.key == 0 ? 0 : 8,
                right: entry.key == kpis.length - 1 ? 0 : 8,
              ),
              child: AnimatedListItem(
                index: entry.key,
                child: _buildKPICard(entry.value),
              ),
            ),
          );
        }).toList(),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kpis.asMap().entries.map((entry) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          child: AnimatedListItem(
            index: entry.key,
            child: _buildKPICard(entry.value),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKPICard(_KPIData kpi) {
    return AnimatedBuilder(
      animation: _kpiAnimation,
      builder: (context, child) {
        final animatedValue = kpi.value * _kpiAnimation.value;
        final displayValue = kpi.isInteger 
            ? animatedValue.toInt().toString()
            : animatedValue.toStringAsFixed(2);
        
        return CustomCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kpi.color.withOpacity(0.2),
                          kpi.color.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(kpi.icon, color: kpi.color, size: 22),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kpi.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          kpi.value >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                          color: kpi.color,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${(kpi.value.abs() / (kpi.value.abs() + 1) * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: kpi.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${kpi.prefix}$displayValue${kpi.suffix}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kpi.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                kpi.title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartsSection(AppLocalizations t, bool isWideScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final charts = [
      _ChartData(
        title: t.monthlySales,
        subtitle: t.salesTrend,
        icon: Icons.show_chart_rounded,
        color: Colors.green,
        child: _buildLineChart(_ventasPorMes, Colors.green),
      ),
      _ChartData(
        title: t.monthlyExpenses,
        subtitle: t.expensesTrend,
        icon: Icons.trending_down_rounded,
        color: colorScheme.error,
        child: _buildLineChart(_gastosPorMes, colorScheme.error),
      ),
      _ChartData(
        title: t.monthlyProfit,
        subtitle: t.profitTrend,
        icon: Icons.account_balance_outlined,
        color: colorScheme.primary,
        child: _buildProfitChart(_profitPorMes),
      ),
      _ChartData(
        title: t.topProducts,
        subtitle: t.salesByProduct,
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF6366F1),
        child: _buildBarChart(_topProducts, t),
      ),
      _ChartData(
        title: t.paymentMethods,
        subtitle: t.paymentDistribution,
        icon: Icons.pie_chart_rounded,
        color: const Color(0xFF8B5CF6),
        child: _buildPieChart(_paymentMethodStats, t),
      ),
      _ChartData(
        title: t.stockEvolution,
        subtitle: t.avgStock,
        icon: Icons.inventory_outlined,
        color: Colors.orange,
        child: _buildLineChart(_stockEvolution, Colors.orange),
      ),
    ];

    if (isWideScreen) {
      return Column(
        children: [
          for (int i = 0; i < charts.length; i += 2)
            Padding(
              padding: EdgeInsets.only(bottom: i + 2 < charts.length ? 16 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AnimatedListItem(
                      index: 5 + i,
                      child: _buildChartCard(charts[i]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: i + 1 < charts.length
                        ? AnimatedListItem(
                            index: 6 + i,
                            child: _buildChartCard(charts[i + 1]),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Column(
      children: charts.asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: entry.key < charts.length - 1 ? 16 : 0),
          child: AnimatedListItem(
            index: 5 + entry.key,
            child: _buildChartCard(entry.value),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChartCard(_ChartData chart) {
    return CustomCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      chart.color.withOpacity(0.2),
                      chart.color.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(chart.icon, color: chart.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chart.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      chart.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          chart.child,
        ],
      ),
    );
  }

  Widget _buildLineChart(Map<String, double> data, Color color) {
    if (data.isEmpty) {
      return _buildEmptyChart();
    }

    final sortedKeys = data.keys.toList()..sort();
    final spots = <FlSpot>[];
    double maxY = 0;
    
    for (int i = 0; i < sortedKeys.length; i++) {
      final value = data[sortedKeys[i]]!;
      spots.add(FlSpot(i.toDouble(), value));
      if (value > maxY) maxY = value;
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < sortedKeys.length) {
                    final month = sortedKeys[idx].length >= 7 
                        ? sortedKeys[idx].substring(5) 
                        : sortedKeys[idx];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        month,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.inverseSurface,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '\$${spot.y.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: Theme.of(context).colorScheme.surface,
                    strokeWidth: 2.5,
                    strokeColor: color,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.3),
                    color.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildProfitChart(Map<String, double> data) {
    if (data.isEmpty) {
      return _buildEmptyChart();
    }

    final sortedKeys = data.keys.toList()..sort();
    final spots = <FlSpot>[];
    double maxY = 0;
    double minY = 0;
    
    for (int i = 0; i < sortedKeys.length; i++) {
      final value = data[sortedKeys[i]]!;
      spots.add(FlSpot(i.toDouble(), value));
      if (value > maxY) maxY = value;
      if (value < minY) minY = value;
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: value == 0 
                    ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                strokeWidth: value == 0 ? 2 : 1,
                dashArray: value == 0 ? null : [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < sortedKeys.length) {
                    final month = sortedKeys[idx].length >= 7 
                        ? sortedKeys[idx].substring(5) 
                        : sortedKeys[idx];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        month,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Theme.of(context).colorScheme.inverseSurface,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final isPositive = spot.y >= 0;
                  return LineTooltipItem(
                    '${isPositive ? '+' : ''}\$${spot.y.toStringAsFixed(2)}',
                    TextStyle(
                      color: isPositive ? Colors.green : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              gradient: LinearGradient(
                colors: [Colors.green, Theme.of(context).colorScheme.error],
                stops: const [0.0, 1.0],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  final isPositive = spot.y >= 0;
                  return FlDotCirclePainter(
                    radius: 5,
                    color: Theme.of(context).colorScheme.surface,
                    strokeWidth: 2.5,
                    strokeColor: isPositive ? Colors.green : Theme.of(context).colorScheme.error,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green.withOpacity(0.2),
                    Colors.green.withOpacity(0.0),
                  ],
                ),
                cutOffY: 0,
                applyCutOffY: true,
              ),
              aboveBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).colorScheme.error.withOpacity(0.2),
                    Theme.of(context).colorScheme.error.withOpacity(0.0),
                  ],
                ),
                cutOffY: 0,
                applyCutOffY: true,
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, AppLocalizations t) {
    if (data.isEmpty) {
      return _buildEmptyChart();
    }

    final maxQuantity = data.fold<int>(
      0, 
      (max, item) => math.max(max, item['cantidad_total'] as int),
    );

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxQuantity.toDouble() * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Theme.of(context).colorScheme.inverseSurface,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = data[group.x.toInt()];
                return BarTooltipItem(
                  '${item['nombre']}\n${item['cantidad_total']} ${t.units}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < data.length) {
                    final name = data[idx]['nombre'] as String;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: 50,
                        child: Text(
                          name.length > 8 ? '${name.substring(0, 6)}...' : name,
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final quantity = (item['cantidad_total'] as int).toDouble();
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: quantity,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 24,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> data, AppLocalizations t) {
    if (data.isEmpty) {
      return _buildEmptyChart();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      Colors.green,
      Colors.orange,
      colorScheme.error,
      colorScheme.primary,
    ];

    final total = data.values.fold<double>(0, (sum, val) => sum + val);
    final entries = data.entries.toList();

    String getPaymentMethodName(String key) {
      switch (key.toLowerCase()) {
        case 'cash':
        case 'efectivo':
          return t.paymentCash;
        case 'card':
        case 'tarjeta':
          return t.paymentCard;
        case 'transfer':
        case 'transferencia':
          return t.paymentTransfer;
        case 'bizum':
          return t.paymentBizum;
        default:
          return t.paymentOther;
      }
    }

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final percentage = (item.value / total * 100);
                  
                  return PieChartSectionData(
                    value: item.value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    color: colors[index % colors.length],
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          getPaymentMethodName(item.key),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    final t = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              t.noChartData,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KPIData {
  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final String prefix;
  final String suffix;
  final bool isInteger;

  _KPIData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.prefix = '',
    this.suffix = '',
    this.isInteger = false,
  });
}

class _ChartData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  _ChartData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });
}
