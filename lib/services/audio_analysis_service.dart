import 'dart:typed_data';
import 'dart:math';
import '../models/analysis_params.dart';

class AudioAnalysisResult {
  final int peakCount;
  final int minPeakDistanceMs;

  AudioAnalysisResult({
    required this.peakCount,
    required this.minPeakDistanceMs,
  });
}

class AudioAnalysisService {
  static AudioAnalysisResult detectPeaks(Float32List audioBuffer, AnalysisParams params, int sampleRate) {
    int peakCount = 0;
    int lastPeakPosition = -1;
    int minPeakDistanceSamples = audioBuffer.length; // Initialize with a large value
    List<int> peakPositions = [];

    final int minSpacingSamples = (params.minSpacingMs * 44100) ~/ 1000; // Assuming 44100 sample rate

    for (int i = 0; i < audioBuffer.length; i++) {
      if (audioBuffer[i].abs() > params.threshold) {
        if (lastPeakPosition == -1 || (i - lastPeakPosition) > minSpacingSamples) {
          peakCount++;
          peakPositions.add(i);
          if (lastPeakPosition != -1) {
            final currentDistance = i - lastPeakPosition;
            if (currentDistance < minPeakDistanceSamples) {
              minPeakDistanceSamples = currentDistance;
            }
          }
          lastPeakPosition = i;
        }
      }
    }

    final int minPeakDistanceMs = (minPeakDistanceSamples * 1000 / 44100).toInt();

    return AudioAnalysisResult(
      peakCount: peakCount,
      minPeakDistanceMs: peakPositions.length > 1 ? minPeakDistanceMs : 0,
    );
  }
}