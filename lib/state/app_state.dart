import 'dart:async';
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
import 'package:geiger_calc/services/audio_player_service.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart' as fs_player; // Added import

class AppState with ChangeNotifier {
  AnalysisParams _params = AnalysisParams();
  CalculationResult? _result;
  AudioData? _audioData;
  final AudioPlayerService audioPlayerService = AudioPlayerService(); // Instance of AudioPlayerService
  bool _isLoading = false;
  final AudioRecorder? _audioRecorder = kIsWeb ? null : AudioRecorder();
  bool _isRecording = false;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  // Constructor to initialize AudioPlayerService
  AppState() {
    audioPlayerService.init().then((_) {
      // Listen to player state changes to notify UI if needed
      audioPlayerService.playerStateStream.listen((state) {
        // We might want to trigger notifyListeners() for specific state changes
        // if they affect UI elements not directly listening to playerStateStream.
        // For now, direct consumers will use the stream.
        notifyListeners(); // General notification for state change
      });
      audioPlayerService.playbackDispositionStream.listen((disposition) {
        // Similar to above, notify if general UI elements depend on this.
        // Direct consumers (like the visualizer progress bar) will use the stream.
         notifyListeners(); // General notification for progress change
      });
    });
  }

  AnalysisParams get params => _params;
  CalculationResult? get result => _result;
  AudioData? get audioData => _audioData;
  // Expose player state and disposition for UI
  PlayerState get playerState => audioPlayerService.currentPlayerState;
  Stream<fs_player.PlaybackDisposition> get playbackDispositionStream => audioPlayerService.playbackDispositionStream; // Changed to fs_player.PlaybackDisposition
  Duration get currentAudioDuration => audioPlayerService.currentAudioDuration;

  bool get isLoading => _isLoading;
  bool get isRecording => _isRecording;
  Duration get recordingDuration => _recordingDuration;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadAudioAndAnalyze() async {
    _setLoading(true);
    try {
      FilePickerResult? pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        // TODO: Consider specifying allowedExtensions: ['wav', 'mp3']
        // However, AudioDecoderService needs to be ready for mp3 on mobile first.
      );

      if (pickerResult != null && pickerResult.files.single.bytes != null) {
        final PlatformFile file = pickerResult.files.single;
        final Uint8List bytes = file.bytes!;
         String fileExtension = file.extension ?? '';
        if (fileExtension.isEmpty) {
          // Try to get extension from name if not available
           final String name = file.name;
           final int dotIndex = name.lastIndexOf('.');
           if (dotIndex != -1 && dotIndex < name.length -1) {
              fileExtension = name.substring(dotIndex + 1).toLowerCase();
           }
        }
        // Ensure we have a valid extension to pass, default to 'wav' or handle error
        // For now, if extension is empty, it might fail in AudioDecoderService on mobile.
        // A more robust solution would be to ensure extension is always present or handle unknown.
        await _processAudioBytes(bytes, fileExtension);
      } else if (pickerResult != null && pickerResult.files.single.path != null && !kIsWeb) {
        // This branch is for non-web platforms where path is available
        final PlatformFile file = pickerResult.files.single;
        final String? filePath = file.path;
        if (filePath != null) {
          final Uint8List bytes = await File(filePath).readAsBytes();
          final String fileExtension = file.extension ?? p.extension(filePath).replaceFirst('.', '');
          await _processAudioBytes(bytes, fileExtension);
        } else {
           throw Exception("File path is null for a non-web platform.");
        }
      }
    } catch (e) {
      print('Error loading or analyzing file: $e');
      _result = null;
      _audioData = null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _processAudioBytes(Uint8List bytes, String fileExtension) async {
    // Decode audio for visualization
    final DecodedAudio decodedAudio = await AudioDecoderService.decodeAudioBytes(bytes, fileExtension);
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

    // First, perform analysis to get peak data
    final AudioAnalysisResult analysisResult = AudioAnalysisService.detectPeaks(audioBuffer, _params, sampleRate);

    _audioData = AudioData(
      audioBuffer: audioBuffer,
      totalDurationSeconds: totalDurationSeconds,
      maxAmplitude: maxAmp,
      averageAmplitude: averageAmplitude,
      minPeakDistanceMs: analysisResult.minPeakDistanceMs,
      peakTimestamps: analysisResult.peakTimestamps,
      sampleRate: sampleRate, // Store sampleRate
    );

    // Calculate metrics based on analysis results
    _result = CalculationService.calculateMetrics(counts: analysisResult.peakCount, params: _params);

    // Note: _audioData is already set with all necessary info including peakTimestamps.
    // No need to re-create it unless other properties were meant to be updated separately.

    // Load audio into player service (using original bytes and extension)
    // This happens after visual data is processed.
    await audioPlayerService.loadAudio(bytes, fileExtension);
    // Notify listeners after all processing, including loading audio for playback
    notifyListeners();
  }

  void updateAnalysisParams(AnalysisParams newParams) {
    _params = newParams;
    if (_audioData != null) {
      // Use the stored sampleRate
      final int sampleRate = _audioData!.sampleRate;

      if (sampleRate > 0) {
        final AudioAnalysisResult analysisResult = AudioAnalysisService.detectPeaks(_audioData!.audioBuffer, _params, sampleRate);
        _result = CalculationService.calculateMetrics(counts: analysisResult.peakCount, params: _params);

        _audioData = AudioData(
          audioBuffer: _audioData!.audioBuffer,
          totalDurationSeconds: _audioData!.totalDurationSeconds,
          maxAmplitude: _audioData!.maxAmplitude,
          averageAmplitude: _audioData!.averageAmplitude,
          minPeakDistanceMs: analysisResult.minPeakDistanceMs,
          peakTimestamps: analysisResult.peakTimestamps,
          sampleRate: sampleRate, // Keep the same sampleRate
        );
      } else {
        // This case should ideally not be reached if sampleRate is always correctly stored.
        // If it is, it implies an issue during initial processing.
        _result = null;
         _audioData = AudioData(
          audioBuffer: _audioData!.audioBuffer,
          totalDurationSeconds: _audioData!.totalDurationSeconds,
          maxAmplitude: _audioData!.maxAmplitude,
          averageAmplitude: _audioData!.averageAmplitude,
          minPeakDistanceMs: 0,
          peakTimestamps: [],
          sampleRate: 0, // Reflect that sampleRate is invalid
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
          _recordingDuration = Duration.zero;
          _recordingTimer?.cancel(); // Cancel any existing timer
          _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
            notifyListeners();
          });
          notifyListeners();
        }
      } else {
        print('Microphone permission not granted or recorder not available.');
        _setLoading(false); // Ensure loading is false if we don't start
      }
    } catch (e) {
      print('Error starting recording: $e');
      _isRecording = false; // Ensure recording state is false on error
      _recordingTimer?.cancel();
      _recordingDuration = Duration.zero;
      _setLoading(false);
    }
    // No finally setLoading(false) here, as it could be set true and recording starts
  }

  Future<void> stopRecording() async {
    if (kIsWeb || _audioRecorder == null || !_isRecording) {
      print('Recording not active or not supported.');
      return;
    }
    // setLoading is handled by _processAudioBytes or if error occurs
    // _setLoading(true);
    try {
      final path = await _audioRecorder!.stop();
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingDuration = Duration.zero;
      // notifyListeners(); // Notifying after processing audio or if path is null

      if (path != null) {
        _setLoading(true); // Set loading true before processing audio
        final fileBytes = await File(path).readAsBytes();
        // Recordings are saved as WAV
        await _processAudioBytes(fileBytes, 'wav'); // This will set loading to false
      } else {
        _setLoading(false); // If path is null, ensure loading is false
        notifyListeners(); // Notify to update UI if no path
      }
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingDuration = Duration.zero;
      _setLoading(false);
      notifyListeners(); // Notify to update UI on error
    }
  }

  // Call this method when AppState is no longer needed to clean up resources.
  @override
  void dispose() {
    audioPlayerService.dispose();
    _recordingTimer?.cancel();
    _audioRecorder?.dispose();
    super.dispose(); // Important if extending ChangeNotifier or other classes with dispose methods
  }
}