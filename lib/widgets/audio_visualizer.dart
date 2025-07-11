import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:geiger_calc/services/audio_player_service.dart'; // For PlayerState
import 'package:geiger_calc/state/app_state.dart';
import 'package:provider/provider.dart';

class AudioVisualizer extends StatelessWidget {
  const AudioVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final audioData = appState.audioData;
        final audioPlayerService = appState.audioPlayerService;

        // Use LayoutBuilder to get available width for dynamic downsampling
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            List<FlSpot> spots = [];
            double actualMaxX = 0; // This will be totalDurationSeconds
            double bottomTitleInterval = 1.0;

            if (audioData != null && audioData.audioBuffer.isNotEmpty) {
              final audioBuffer = audioData.audioBuffer;
              final totalDurationSeconds = audioData.totalDurationSeconds;
              actualMaxX = totalDurationSeconds;

              // Dynamic downsampling based on available width
              // constraints.maxWidth gives the available width for the LayoutBuilder
              // Subtract some pixels for padding/margin if any, to get effective chart width
              final double effectiveChartWidth = constraints.maxWidth - 32; // Assuming 16 padding on each side from Card

              int step = 1;
              if (effectiveChartWidth > 0 && audioBuffer.length > effectiveChartWidth) {
                step = (audioBuffer.length / effectiveChartWidth).ceil();
              }

              final sampleRate = audioBuffer.length / totalDurationSeconds;

              for (int i = 0; i < audioBuffer.length; i += step) {
                final timeInSeconds = i / sampleRate;
                spots.add(FlSpot(timeInSeconds, audioBuffer[i]));
              }
               if (spots.isEmpty && audioBuffer.isNotEmpty) { // Ensure at least one spot if buffer is not empty
                spots.add(FlSpot(0, audioBuffer[0]));
                 if (totalDurationSeconds == 0 && audioBuffer.length ==1) actualMaxX = 1; // Avoid maxX=0 if only one sample
              }


              // Calculate bottomTitleInterval based on desired number of labels (e.g., 5-10 labels)
              if (totalDurationSeconds > 0) {
                final numLabels = max(2.0, min(10.0, effectiveChartWidth / 80)); // Aim for labels every 80px
                bottomTitleInterval = totalDurationSeconds / numLabels;
                if (bottomTitleInterval == 0 && totalDurationSeconds > 0) { // Avoid interval 0
                    bottomTitleInterval = totalDurationSeconds / 2;
                } else if (bottomTitleInterval == 0 && totalDurationSeconds == 0) {
                    bottomTitleInterval = 1;
                }
              } else {
                bottomTitleInterval = 1;
              }
            }

            // Fixed Y-axis normalization
            const double fixedMinY = -1.0;
            const double fixedMaxY = 1.0;

            return Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    if (audioData != null && spots.isNotEmpty) // Only show chart if data exists
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
                                    child: Text('${value.toStringAsFixed(1)}s'), // Display time in seconds
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  // Show labels like -1.0, -0.5, 0, 0.5, 1.0
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
                              barWidth: 1.5, // Slightly thinner for potentially more data points
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false), // No dots for performance with many points
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                          minX: 0,
                          maxX: actualMaxX,
                          minY: fixedMinY,
                          maxY: fixedMaxY,
                          clipData: const FlClipData.all(), // Clip data to chart area
                        ),
                      ),
                    if (audioData != null && spots.isNotEmpty) // Only show chart if data exists
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
                                    child: Text('${value.toStringAsFixed(1)}s'), // Display time in seconds
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  // Show labels like -1.0, -0.5, 0, 0.5, 1.0
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
                              barWidth: 1.5, // Slightly thinner for potentially more data points
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false), // No dots for performance with many points
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                          minX: 0,
                          maxX: actualMaxX,
                          minY: fixedMinY,
                          maxY: fixedMaxY,
                          clipData: const FlClipData.all(), // Clip data to chart area
                          extraLinesData: _getPeakMarkersExtraLinesData(appState), // ADDED FOR PEAK MARKERS
                        ),
                      ),
                    if (audioData == null || spots.isEmpty) // Show a message if no audio data
                      const Center(child: Text("Load an audio file to see the waveform.")),

                    // Playback Progress Bar
                    if (audioData != null && spots.isNotEmpty && appState.currentAudioDuration.inMilliseconds > 0)
                      StreamBuilder<PlaybackDisposition>(
                        stream: appState.playbackDispositionStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.duration.inMilliseconds == 0) {
                            if (appState.playerState == PlayerState.paused ||
                                appState.playerState == PlayerState.stopped ||
                                appState.playerState == PlayerState.completed) {
                                final currentPositionRatio = (snapshot.data?.position.inMilliseconds ?? 0) /
                                                             appState.currentAudioDuration.inMilliseconds;
                                final barXPosition = currentPositionRatio * (constraints.maxWidth); // Use full width of LayoutBuilder for ratio
                                return Positioned(
                                  left: barXPosition.clamp(0, constraints.maxWidth),
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 2,
                                    color: Colors.redAccent,
                                  ),
                                );
                            }
                            return const SizedBox.shrink();
                          }

                          final disposition = snapshot.data!;
                          final currentPositionRatio = disposition.position.inMilliseconds / disposition.duration.inMilliseconds;
                          final barXPosition = currentPositionRatio * (constraints.maxWidth);

                          return Positioned(
                            left: barXPosition.clamp(0, constraints.maxWidth),
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: Colors.redAccent,
                            ),
                          );
                        },
                      ),

                    // GestureDetector for seek functionality
                    if (audioData != null && spots.isNotEmpty && appState.currentAudioDuration.inMilliseconds > 0)
                      Positioned.fill(
                        child: GestureDetector(
                          onTapDown: (details) {
                            final RenderBox box = context.findRenderObject() as RenderBox;
                            final Offset localOffset = box.globalToLocal(details.globalPosition);
                            final double gestureDetectorWidth = constraints.maxWidth;

                            if (gestureDetectorWidth <= 0) return;
                            double tapX = localOffset.dx;
                            tapX = tapX.clamp(0, gestureDetectorWidth);

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
            ),
          ),
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
            dashArray: [3, 3], // Dashed line for peaks
            label: VerticalLineLabel(show: false), // No text label for peaks
          ),
        );
      }
    }
    return ExtraLinesData(
      verticalLines: peakVerticalLines,
    );
  }
}