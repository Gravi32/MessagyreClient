import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:messagyre_client/configuration/app_styles.dart';
import 'package:messagyre_client/utility/utility.dart';

class Chart extends StatelessWidget {
  final Color color;
  final List<FlSpot> spots;
  final bool showDots;
  final bool showTitles;
  final bool showLines;
  final double min;
  final double max;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const Chart({
    super.key,
    required this.color,
    required this.spots,
    this.showDots = false,
    this.showTitles = false,
    this.showLines = true,
    this.min = 1,
    this.max = 6,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (spots.length == 1) spots.add(spots.first.copyWith(x: spots.first.x + 1));

    return ClipRRect(
      borderRadius: .circular(12),
      clipBehavior: backgroundColor != null ? .antiAlias : .none,
      child: Container(
        padding: padding ?? .zero,
        color: backgroundColor,
        child: LineChart(
          LineChartData(
            minY: min,
            maxY: max,
            minX: spots.firstOrNull?.x ?? 0,
            maxX: spots.lastOrNull?.x ?? 1,
            lineBarsData: [
              LineChartBarData(
                color: color,
                isCurved: true,
                barWidth: 3,
                preventCurveOverShooting: true,
                isStrokeCapRound: true,
                isStrokeJoinRound: true,
                dotData: FlDotData(show: showDots),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(begin: .topCenter, end: .bottomCenter, colors: [color.withTransparency(.4), color.withTransparency(0)]),
                ),
                spots: spots,
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(),
              bottomTitles: AxisTitles(),
              topTitles: AxisTitles(),
              rightTitles: showTitles
                  ? AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 18,
                        getTitlesWidget: (value, meta) => Align(
                          alignment: .centerRight,
                          child: Text(meta.formattedValue, style: AppStyles.footer(context)),
                        ),
                      ),
                    )
                  : AxisTitles(),
            ),
            lineTouchData: LineTouchData(enabled: false),
            gridData: FlGridData(drawVerticalLine: false, drawHorizontalLine: showLines, horizontalInterval: 1),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}
