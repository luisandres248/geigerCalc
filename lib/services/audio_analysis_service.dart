import 'dart:typed_data';
import 'dart:math';
import '../models/analysis_params.dart';

class AudioAnalysisResult {
  final int peakCount;
  final int minPeakDistanceMs;
  final List<double> peakTimestamps; // Timestamps of peaks in seconds

  AudioAnalysisResult({
    required this.peakCount,
    required this.minPeakDistanceMs,
    required this.peakTimestamps,
  });
}

class AudioAnalysisService {
  static AudioAnalysisResult detectPeaks(Float32List audioBuffer, AnalysisParams params, int sampleRate) {
    if (sampleRate <= 0) { // Prevent division by zero or invalid calculations
        return AudioAnalysisResult(peakCount: 0, minPeakDistanceMs: 0, peakTimestamps: []);
    }

    int peakCount = 0;
    int lastPeakSampleIndex = -1; // Store sample index of the last peak
    int minPeakDistanceSamples = audioBuffer.length;
    List<int> peakSampleIndexes = []; // Store sample indexes of detected peaks

    // Calculate minSpacingSamples using the actual sampleRate
    final int minSpacingSamples = (params.minSpacingMs * sampleRate) ~/ 1000;

    for (int i = 0; i < audioBuffer.length; i++) {
      if (audioBuffer[i].abs() > params.threshold) {
        if (lastPeakSampleIndex == -1 || (i - lastPeakSampleIndex) > minSpacingSamples) {
          peakCount++;
          peakSampleIndexes.add(i);
          if (lastPeakSampleIndex != -1) {
            final currentDistanceSamples = i - lastPeakSampleIndex;
            if (currentDistanceSamples < minPeakDistanceSamples) {
              minPeakDistanceSamples = currentDistanceSamples;
            }
          }
          lastPeakSampleIndex = i;
        }
      }
    }

    // Convert minPeakDistanceSamples to milliseconds using actual sampleRate
    final int minPeakDistanceMsResult = peakSampleIndexes.length > 1 && sampleRate > 0
        ? (minPeakDistanceSamples * 1000 / sampleRate).round()
        : 0;

    // Convert peak sample indexes to timestamps in seconds
    List<double> peakTimestamps = [];
    if (sampleRate > 0) {
        peakTimestamps = peakSampleIndexes.map((sampleIndex) => sampleIndex / sampleRate).toList();
    }

    return AudioAnalysisResult(
      peakCount: peakCount,
      minPeakDistanceMs: minPeakDistanceMsResult,
      peakTimestamps: peakTimestamps,
    );
  }
}