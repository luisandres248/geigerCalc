import 'dart:typed_data';

class AudioData {
  final Float32List audioBuffer;
  final double totalDurationSeconds;
  final double maxAmplitude;
  final double averageAmplitude;
  final int minPeakDistanceMs;
  final List<double> peakTimestamps;
  final int sampleRate;

  AudioData({
    required this.audioBuffer,
    required this.totalDurationSeconds,
    required this.maxAmplitude,
    required this.averageAmplitude,
    required this.minPeakDistanceMs,
    required this.peakTimestamps,
    required this.sampleRate,
  });
}
