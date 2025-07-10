import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart' show AudioRecorder, AudioEncoder, RecordConfig;
import 'package:path/path.dart' as p;
import 'package:geiger_calc/models/analysis_params.dart';
import 'package:geiger_calc/services/audio_analysis_service.dart';
import 'package:geiger_calc/services/calculation_service.dart';
import 'package:geiger_calc/services/audio_decoder_service.dart';
import 'package:geiger_calc/models/audio_data.dart';

class AppState with ChangeNotifier {
  AnalysisParams _params = AnalysisParams();
  CalculationResult? _result;
  AudioData? _audioData;
  bool _isLoading = false;
  final AudioRecorder? _audioRecorder = kIsWeb ? null : AudioRecorder();
  bool _isRecording = false;

  AnalysisParams get params => _params;
  CalculationResult? get result => _result;
  AudioData? get audioData => _audioData;
  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadAudioAndAnalyze() async {
    _setLoading(true);
    try {
      FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (pickerResult != null && pickerResult.files.single.bytes != null) {
        final Uint8List bytes = pickerResult.files.single.bytes!;
        await _processAudioBytes(bytes);
      } else if (pickerResult != null && pickerResult.files.single.path != null) {
        // This branch is for non-web platforms where path is available
        final Uint8List bytes = await pickerResult.files.single.bytes!; // Read bytes from path
        await _processAudioBytes(bytes);
      }
    } catch (e) {
      print('Error loading or analyzing file: $e');
      _result = null;
      _audioData = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _processAudioBytes(Uint8List bytes) async {
    final DecodedAudio decodedAudio = await AudioDecoderService.decodeAudioBytes(bytes);
    final Float32List audioBuffer = decodedAudio.audioBuffer;
    final int sampleRate = decodedAudio.sampleRate;

    // Calculate metrics from the real audio buffer
    double maxAmp = 0.0;
    double sumAmps = 0.0;
    for (double sample in audioBuffer) {
      if (sample.abs() > maxAmp) {
        maxAmp = sample.abs();
      }
      sumAmps += sample * sample;
    }
    final double averageAmplitude = sqrt(sumAmps / audioBuffer.length);
    final double totalDurationSeconds = audioBuffer.length / sampleRate;

    _audioData = AudioData(
      audioBuffer: audioBuffer,
      totalDurationSeconds: totalDurationSeconds,
      maxAmplitude: maxAmp,
      averageAmplitude: averageAmplitude,
      minPeakDistanceMs: 0, // This will be updated by AudioAnalysisService
    );

    final AudioAnalysisResult analysisResult = AudioAnalysisService.detectPeaks(_audioData!.audioBuffer, _params, sampleRate);
    _result = CalculationService.calculateMetrics(counts: analysisResult.peakCount, params: _params);
    _audioData = AudioData(
      audioBuffer: _audioData!.audioBuffer,
      totalDurationSeconds: _audioData!.totalDurationSeconds,
      maxAmplitude: _audioData!.maxAmplitude,
      averageAmplitude: _audioData!.averageAmplitude,
      minPeakDistanceMs: analysisResult.minPeakDistanceMs,
    );
  }

  void updateAnalysisParams(AnalysisParams newParams) {
    _params = newParams;
    if (_audioData != null) {
      final AudioAnalysisResult analysisResult = AudioAnalysisService.detectPeaks(_audioData!.audioBuffer, _params, _audioData!.totalDurationSeconds.toInt() * 44100);
      _result = CalculationService.calculateMetrics(counts: analysisResult.peakCount, params: _params);
      // Update minPeakDistanceMs in AudioData if it's different
      if (_audioData!.minPeakDistanceMs != analysisResult.minPeakDistanceMs) {
        _audioData = AudioData(
          audioBuffer: _audioData!.audioBuffer,
          totalDurationSeconds: _audioData!.totalDurationSeconds,
          maxAmplitude: _audioData!.maxAmplitude,
          averageAmplitude: _audioData!.averageAmplitude,
          minPeakDistanceMs: analysisResult.minPeakDistanceMs,
        );
      }
    }
    notifyListeners();
  }

  // This is a placeholder to simulate having decoded audio data.
  AudioData _generateDummyAudioBuffer() {
    final random = Random();
    const int sampleRate = 44100; // samples per second
    const int durationSeconds = 60; // 60 seconds of dummy audio
    final int numberOfSamples = sampleRate * durationSeconds;

    double maxAmp = 0.0;
    double sumAmps = 0.0;
    final List<double> rawList = List<double>.generate(numberOfSamples, (i) {
      final value = random.nextDouble() * 2 - 1; // -1.0 to 1.0
      if (value.abs() > maxAmp) {
        maxAmp = value.abs();
      }
      sumAmps += value * value; // For RMS
      return value;
    });

    final Float32List audioBuffer = Float32List.fromList(rawList);

    final double averageAmplitude = sqrt(sumAmps / numberOfSamples); // RMS

    return AudioData(
      audioBuffer: audioBuffer,
      totalDurationSeconds: durationSeconds.toDouble(),
      maxAmplitude: maxAmp,
      averageAmplitude: averageAmplitude,
      minPeakDistanceMs: 0, // This will be updated by AudioAnalysisService
    );
  }

  Future<void> startRecording() async {
    if (kIsWeb) {
      print('Recording is not fully supported on web yet.');
      return;
    }

    _setLoading(true);
    try {
      if (_audioRecorder != null && await Permission.microphone.request().isGranted) {
        if (await _audioRecorder!.hasPermission()) {
          final directory = await getTemporaryDirectory();
          final path = p.join(directory.path, 'geiger_recording.wav');
          await _audioRecorder!.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
          _isRecording = true;
          notifyListeners();
        }
      } else {
        print('Microphone permission not granted or recorder not available.');
      }
    } catch (e) {
      print('Error starting recording: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> stopRecording() async {
    if (kIsWeb) {
      print('Recording is not fully supported on web yet.');
      return;
    }

    _setLoading(true);
    try {
      if (_audioRecorder != null) {
        final path = await _audioRecorder!.stop();
        _isRecording = false;
        notifyListeners();
        if (path != null) {
          final fileBytes = await File(path).readAsBytes();
          await _processAudioBytes(fileBytes);
        }
      }
    } catch (e) {
      print('Error stopping recording: $e');
    } finally {
      _setLoading(false);
    }
  }
}