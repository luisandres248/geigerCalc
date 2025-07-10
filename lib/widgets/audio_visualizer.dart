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

        if (audioData != null) {
          final audioBuffer = audioData.audioBuffer;
          // Downsample for visualization
          final step = (audioBuffer.length / 500).ceil();
          for (int i = 0; i < audioBuffer.length; i += step) {
            spots.add(FlSpot(i.toDouble(), audioBuffer[i]));
          }
          maxX = audioData.totalDurationSeconds * 44100; // Assuming 44100 samples/sec
          maxY = audioData.maxAmplitude > 0 ? audioData.maxAmplitude * 1.1 : 1.0; // Add some padding
          minY = audioData.maxAmplitude > 0 ? -audioData.maxAmplitude * 1.1 : -1.0;
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
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text('${(value / 44100).toStringAsFixed(1)}s'),
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
