import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/meal.dart';
import 'ux_components.dart';

/// Investment spending pattern chart with smooth animations
/// Follows UX advisor requirements for engaging data visualization
class InvestmentSpendingChart extends StatefulWidget {
  final List<Meal> meals;
  final String timeframe;
  final double weeklyBudget;
  final bool showAnimation;

  const InvestmentSpendingChart({
    super.key,
    required this.meals,
    this.timeframe = 'week',
    this.weeklyBudget = 0.0,
    this.showAnimation = true,
  });

  @override
  State<InvestmentSpendingChart> createState() => _InvestmentSpendingChartState();
}

class _InvestmentSpendingChartState extends State<InvestmentSpendingChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.showAnimation) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChartHeader(context),
            const SizedBox(height: UXComponents.paddingL),
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return widget.timeframe == 'week'
                      ? _buildWeeklyLineChart()
                      : _buildMonthlyBarChart();
                },
              ),
            ),
            const SizedBox(height: UXComponents.paddingM),
            _buildChartLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildChartHeader(BuildContext context) {
    final theme = Theme.of(context);
    final totalSpent = widget.meals.fold<double>(0.0, (sum, meal) => sum + meal.cost);
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(UXComponents.paddingS),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.analytics,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: UXComponents.paddingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Investment Analysis',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total invested: \$${totalSpent.toStringAsFixed(2)} this ${widget.timeframe}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            _animationController.reset();
            _animationController.forward();
            HapticFeedback.lightImpact();
          },
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh chart',
        ),
      ],
    );
  }

  Widget _buildWeeklyLineChart() {
    final weeklyData = _generateWeeklyData();
    
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: _getMaxYValue(weeklyData),
        lineBarsData: [
          LineChartBarData(
            spots: weeklyData.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value * _animation.value);
            }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Budget line
          if (widget.weeklyBudget > 0)
            LineChartBarData(
              spots: List.generate(7, (index) => FlSpot(index.toDouble(), widget.weeklyBudget / 7)),
              isCurved: false,
              color: Colors.red.withOpacity(0.7),
              barWidth: 2,
              isStrokeCapRound: true,
              dashArray: [5, 3],
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: _getMaxYValue(weeklyData) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
            if (touchResponse?.lineBarSpots?.isNotEmpty == true) {
              HapticFeedback.selectionClick();
            }
          },
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.surface,
            tooltipBorder: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                final dayName = days[barSpot.x.toInt()];
                return LineTooltipItem(
                  '$dayName\n\$${barSpot.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyBarChart() {
    final monthlyData = _generateMonthlyData();
    
    return BarChart(
      BarChartData(
        maxY: _getMaxYValue(monthlyData),
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
            setState(() {
              if (response == null || response.spot == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex = response.spot!.touchedBarGroupIndex;
            });
            if (response?.spot != null) {
              HapticFeedback.selectionClick();
            }
          },
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Theme.of(context).colorScheme.surface,
            tooltipBorder: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Week ${group.x + 1}\n\$${rod.toY.toStringAsFixed(2)}',
                TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  'W${(value + 1).toInt()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: _getMaxYValue(monthlyData) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: monthlyData.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          final isTouched = index == _touchedIndex;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value * _animation.value,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: isTouched ? 25 : 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: _getMaxYValue(monthlyData),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartLegend(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(
          context,
          theme.colorScheme.primary,
          'Investment',
        ),
        if (widget.weeklyBudget > 0 && widget.timeframe == 'week')
          _buildLegendItem(
            context,
            Colors.red.withOpacity(0.7),
            'Budget Line',
          ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: UXComponents.paddingS),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<double> _generateWeeklyData() {
    final weekData = List.filled(7, 0.0);
    
    for (final meal in widget.meals) {
      final weekday = meal.date.weekday - 1; // Monday = 0
      if (weekday >= 0 && weekday < 7) {
        weekData[weekday] += meal.cost;
      }
    }
    
    return weekData;
  }

  List<double> _generateMonthlyData() {
    final weekData = List.filled(4, 0.0);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    
    for (final meal in widget.meals) {
      final daysSinceStart = meal.date.difference(startOfMonth).inDays;
      final weekIndex = (daysSinceStart / 7).floor().clamp(0, 3);
      weekData[weekIndex] += meal.cost;
    }
    
    return weekData;
  }

  double _getMaxYValue(List<double> data) {
    final maxValue = data.isEmpty ? 100.0 : data.reduce(max);
    return (maxValue * 1.2).ceilToDouble();
  }
}

/// Meal category distribution pie chart
class MealCategoryChart extends StatefulWidget {
  final List<Meal> meals;
  final bool showAnimation;

  const MealCategoryChart({
    super.key,
    required this.meals,
    this.showAnimation = true,
  });

  @override
  State<MealCategoryChart> createState() => _MealCategoryChartState();
}

class _MealCategoryChartState extends State<MealCategoryChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.showAnimation) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryData = _generateCategoryData();
    
    if (categoryData.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(UXComponents.paddingS),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.pie_chart,
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: UXComponents.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Experience Distribution',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'How you invest in different experiences',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: UXComponents.paddingL),
            
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: categoryData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        final isTouched = index == _touchedIndex;
                        final radius = isTouched ? 110.0 : 100.0;
                        
                        return PieChartSectionData(
                          color: data.color,
                          value: data.value * _animation.value,
                          title: isTouched 
                              ? '\$${data.value.toStringAsFixed(0)}'
                              : '${data.percentage.toStringAsFixed(0)}%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize: isTouched ? 16 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                      pieTouchData: PieTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                          setState(() {
                            if (pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                          
                          if (pieTouchResponse?.touchedSection != null) {
                            HapticFeedback.selectionClick();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: UXComponents.paddingL),
            _buildCategoryLegend(context, categoryData),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryLegend(BuildContext context, List<CategoryData> categoryData) {
    return Column(
      children: categoryData.map((data) {
        return Padding(
          padding: const EdgeInsets.only(bottom: UXComponents.paddingS),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: data.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: UXComponents.paddingS),
              Expanded(
                child: Text(
                  data.category,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '\$${data.value.toStringAsFixed(2)} (${data.percentage.toStringAsFixed(1)}%)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: data.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: UXComponents.paddingM),
            Text(
              'No Experience Data',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: UXComponents.paddingS),
            Text(
              'Start logging meals to see your experience distribution',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<CategoryData> _generateCategoryData() {
    final categoryTotals = <String, double>{};
    
    for (final meal in widget.meals) {
      final category = _getMealCategoryDisplayName(meal.mealType);
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + meal.cost;
    }
    
    if (categoryTotals.isEmpty) return [];
    
    final totalSpent = categoryTotals.values.fold<double>(0.0, (sum, value) => sum + value);
    final colors = _getCategoryColors();
    
    return categoryTotals.entries.map((entry) {
      final colorIndex = categoryTotals.keys.toList().indexOf(entry.key) % colors.length;
      return CategoryData(
        category: entry.key,
        value: entry.value,
        percentage: (entry.value / totalSpent) * 100,
        color: colors[colorIndex],
      );
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by value descending
  }

  String _getMealCategoryDisplayName(String mealType) {
    switch (mealType) {
      case 'dining_out':
        return 'Dining Out';
      case 'delivery':
        return 'Delivery';
      case 'takeout':
        return 'Takeout';
      case 'groceries':
        return 'Groceries';
      case 'snack':
        return 'Snacks';
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      default:
        return 'Other';
    }
  }

  List<Color> _getCategoryColors() {
    return [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
  }
}

class CategoryData {
  final String category;
  final double value;
  final double percentage;
  final Color color;

  CategoryData({
    required this.category,
    required this.value,
    required this.percentage,
    required this.color,
  });
}

/// Investment ROI trend chart showing value over time
class InvestmentROIChart extends StatefulWidget {
  final List<Meal> meals;
  final bool showAnimation;

  const InvestmentROIChart({
    super.key,
    required this.meals,
    this.showAnimation = true,
  });

  @override
  State<InvestmentROIChart> createState() => _InvestmentROIChartState();
}

class _InvestmentROIChartState extends State<InvestmentROIChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.showAnimation) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roiData = _generateROIData();
    
    if (roiData.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(UXComponents.paddingS),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: UXComponents.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Investment Growth',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Your happiness investment over time',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: UXComponents.paddingL),
            
            SizedBox(
              height: 200,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: roiData.length.toDouble() - 1,
                      minY: 0,
                      maxY: _getMaxROI(roiData),
                      lineBarsData: [
                        LineChartBarData(
                          spots: roiData.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value * _animation.value);
                          }).toList(),
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [Colors.green, Colors.teal],
                          ),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 5,
                                color: Colors.green,
                                strokeWidth: 2,
                                strokeColor: theme.colorScheme.surface,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.3),
                                Colors.green.withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '\$${value.toStringAsFixed(0)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < roiData.length) {
                                return Text(
                                  'D${value.toInt() + 1}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        drawHorizontalLine: true,
                        horizontalInterval: _getMaxROI(roiData) / 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                          if (touchResponse?.lineBarSpots?.isNotEmpty == true) {
                            HapticFeedback.selectionClick();
                          }
                        },
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: theme.colorScheme.surface,
                          tooltipBorder: BorderSide(
                            color: theme.colorScheme.outline,
                          ),
                          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                            return touchedBarSpots.map((barSpot) {
                              return LineTooltipItem(
                                'Day ${barSpot.x.toInt() + 1}\n\$${barSpot.y.toStringAsFixed(2)}',
                                TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: UXComponents.paddingM),
            Container(
              padding: const EdgeInsets.all(UXComponents.paddingM),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: UXComponents.paddingS),
                  Expanded(
                    child: Text(
                      'Your investment in dining experiences shows consistent growth in happiness returns',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
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
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UXComponents.paddingL),
        child: Column(
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: UXComponents.paddingM),
            Text(
              'No ROI Data Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: UXComponents.paddingS),
            Text(
              'Keep logging meals to track your investment growth',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<double> _generateROIData() {
    if (widget.meals.isEmpty) return [];
    
    // Sort meals by date
    final sortedMeals = List<Meal>.from(widget.meals)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // Calculate cumulative investment over time
    final roiData = <double>[];
    double cumulativeInvestment = 0.0;
    
    for (final meal in sortedMeals) {
      cumulativeInvestment += meal.cost;
      roiData.add(cumulativeInvestment);
    }
    
    return roiData;
  }

  double _getMaxROI(List<double> data) {
    if (data.isEmpty) return 100.0;
    final maxValue = data.reduce(max);
    return (maxValue * 1.2).ceilToDouble();
  }
}