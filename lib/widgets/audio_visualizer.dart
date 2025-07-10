import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geiger_calc/state/app_state.dart';
import 'package:provider/provider.dart';

class AudioVisualizer extends StatelessWidget {
  const AudioVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final audioData = appState.audioData;
        List<FlSpot> spots = [];
        double maxX = 0;
        double maxY = 1.0;
        double minY = -1.0;
        double bottomTitleInterval = 1.0; // Default interval
        double originalTotalDurationSeconds = 0; // To store original duration for label conversion

        if (audioData != null) {
          final audioBuffer = audioData.audioBuffer;
          originalTotalDurationSeconds = audioData.totalDurationSeconds;
          const normalizedMaxX = 500.0; // Fixed visual width for the chart

          // Downsample for visualization and normalize x-values
          final step = (audioBuffer.length / normalizedMaxX).ceil(); // Adjust step based on normalizedMaxX
          for (int i = 0; i < audioBuffer.length; i += step) {
            final normalizedX = (i / audioBuffer.length) * normalizedMaxX;
            spots.add(FlSpot(normalizedX, audioBuffer[i]));
          }
          maxX = normalizedMaxX; // Set chart's maxX to the normalized max

          maxY = audioData.maxAmplitude > 0 ? audioData.maxAmplitude * 1.1 : 1.0; // Add some padding
          minY = audioData.maxAmplitude > 0 ? -audioData.maxAmplitude * 1.1 : -1.0;

          // Calculate bottomTitleInterval based on desired number of labels (e.g., 5 labels)
          // This will give us an interval in normalized X units
          bottomTitleInterval = normalizedMaxX / 5; // To get 5 labels
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: bottomTitleInterval,
                      getTitlesWidget: (value, meta) {
                        // Convert normalized value back to original seconds for display
                        final originalSeconds = (value / maxX) * originalTotalDurationSeconds;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text('${originalSeconds.toStringAsFixed(0)}s'), // Display in seconds
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toStringAsFixed(1));
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                minX: 0,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
              ),
            ),
          ),
        );
      },
    );
  }
}