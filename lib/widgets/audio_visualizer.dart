import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geiger_calc/services/audio_player_service.dart'; // Para PlayerState
import 'package:geiger_calc/state/app_state.dart';
import 'package:provider/provider.dart';
// Asegurarse de que PlaybackDisposition esté disponible.
import 'package:flutter_sound/public/flutter_sound_player.dart' as fs_player;


class AudioVisualizer extends StatelessWidget {
  const AudioVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final audioData = appState.audioData;

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            List<FlSpot> spots = [];
            double actualMaxX = 0;
            double bottomTitleInterval = 1.0;
            const double fixedMinY = -1.0;
            const double fixedMaxY = 1.0;

            if (audioData != null && audioData.audioBuffer.isNotEmpty) {
              final audioBuffer = audioData.audioBuffer;
              final totalDurationSeconds = audioData.totalDurationSeconds;
              actualMaxX = totalDurationSeconds;

              final double effectiveChartWidth = constraints.maxWidth;

              int step = 1;
              if (effectiveChartWidth > 0 && audioBuffer.length > effectiveChartWidth) {
                step = (audioBuffer.length / effectiveChartWidth).ceil();
                if (step == 0) step = 1;
              }

              double sampleRate = audioData.sampleRate.toDouble();
              if (sampleRate <= 0 && totalDurationSeconds > 0) {
                sampleRate = audioBuffer.length / totalDurationSeconds;
              }
              if (sampleRate <= 0) sampleRate = 1;


              for (int i = 0; i < audioBuffer.length; i += step) {
                final timeInSeconds = i / sampleRate;
                spots.add(FlSpot(timeInSeconds, audioBuffer[i]));
              }

              if (spots.isEmpty && audioBuffer.isNotEmpty) {
                spots.add(FlSpot(0, audioBuffer[0]));
                if (totalDurationSeconds == 0 && audioBuffer.length == 1) actualMaxX = 1;
              }

              if (actualMaxX == 0 && spots.isNotEmpty) actualMaxX = spots.last.x;
              if (actualMaxX == 0) actualMaxX = 1;

              if (totalDurationSeconds > 0 && effectiveChartWidth > 0) {
                final numLabels = max(2.0, min(10.0, effectiveChartWidth / 80));
                bottomTitleInterval = actualMaxX / numLabels;
                if (bottomTitleInterval <= 0) bottomTitleInterval = actualMaxX > 0 ? actualMaxX / 2 : 1;
              } else {
                bottomTitleInterval = 1;
              }
            }

            return Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    if (audioData != null && spots.isNotEmpty)
                      LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: bottomTitleInterval,
                                getTitlesWidget: (value, meta) {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text('${value.toStringAsFixed(1)}s'),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  if (value == -1.0 || value == -0.5 || value == 0 || value == 0.5 || value == 1.0) {
                                    return Text(value.toStringAsFixed(1));
                                  }
                                  return const Text('');
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
                              barWidth: 1.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                          minX: 0,
                          maxX: actualMaxX,
                          minY: fixedMinY,
                          maxY: fixedMaxY,
                          clipData: const FlClipData.all(),
                          extraLinesData: _getPeakMarkersExtraLinesData(appState),
                        ),
                      ),
                    if (audioData == null || spots.isEmpty)
                      const Center(child: Text("Load an audio file to see the waveform.")),

                    if (audioData != null && spots.isNotEmpty && appState.currentAudioDuration.inMilliseconds > 0)
                      StreamBuilder<fs_player.PlaybackDisposition>(
                        stream: appState.playbackDispositionStream,
                        builder: (context, snapshot) {
                          double barXPosition = 0;
                          bool showBar = false;

                          if (snapshot.hasData && snapshot.data!.duration.inMilliseconds > 0) {
                            final disposition = snapshot.data!;
                            if (disposition.duration.inMilliseconds > 0) { // Check again to be safe
                                final currentPositionRatio = disposition.position.inMilliseconds / disposition.duration.inMilliseconds;
                                barXPosition = currentPositionRatio * constraints.maxWidth;
                                showBar = true;
                            }
                          } else if (appState.playerState == PlayerState.paused ||
                                     appState.playerState == PlayerState.stopped ||
                                     appState.playerState == PlayerState.completed) {
                            if (appState.currentAudioDuration.inMilliseconds > 0) {
                                barXPosition = 0;
                                showBar = true;
                            }
                          }

                          if (!showBar) return const SizedBox.shrink();

                          return Positioned(
                            left: barXPosition.clamp(0.0, constraints.maxWidth),
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: Colors.redAccent,
                            ),
                          );
                        },
                      ),

                    if (audioData != null && spots.isNotEmpty && appState.currentAudioDuration.inMilliseconds > 0)
                      Positioned.fill(
                        child: GestureDetector(
                          onTapDown: (details) {
                            final RenderBox box = context.findRenderObject() as RenderBox;
                            final Offset localOffset = box.globalToLocal(details.globalPosition);
                            final double gestureDetectorWidth = constraints.maxWidth;

                            if (gestureDetectorWidth <= 0) return;
                            double tapX = localOffset.dx;
                            tapX = tapX.clamp(0.0, gestureDetectorWidth);

                            final double seekRatio = tapX / gestureDetectorWidth;
                            final double seekMilliseconds = appState.currentAudioDuration.inMilliseconds * seekRatio;

                            appState.audioPlayerService.seek(Duration(milliseconds: seekMilliseconds.toInt()));
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  ExtraLinesData _getPeakMarkersExtraLinesData(AppState appState) {
    List<VerticalLine> peakVerticalLines = [];
    if (appState.audioData?.peakTimestamps.isNotEmpty ?? false) {
      for (double peakTimeInSeconds in appState.audioData!.peakTimestamps) {
        peakVerticalLines.add(
          VerticalLine(
            x: peakTimeInSeconds,
            color: Colors.orange.withOpacity(0.8),
            strokeWidth: 1,
            dashArray: [3, 3],
            label: VerticalLineLabel(show: false),
          ),
        );
      }
    }
    return ExtraLinesData(
      verticalLines: peakVerticalLines,
    );
  }
}
