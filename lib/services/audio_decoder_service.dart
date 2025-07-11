import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:wav_io/wav_io.dart' as wav_io;

// Imports for Mobile MP3 decoding
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;


// Imports for Web
import 'package:web/web.dart' as web;
import 'dart:js_util';
import 'dart:js_interop';

class DecodedAudio {
  final Float32List audioBuffer; // Should always be normalized to [-1.0, 1.0]
  final int sampleRate;

  DecodedAudio({
    required this.audioBuffer,
    required this.sampleRate,
  });
}

class AudioDecoderService {
  static Future<DecodedAudio> decodeAudioBytes(Uint8List bytes, String fileExtension) async {
    fileExtension = fileExtension.toLowerCase();

    if (kIsWeb) {
      // Web implementation (handles WAV and MP3 via browser's capabilities)
      try {
        final audioContext = web.AudioContext();
        final jsArrayBuffer = bytes.buffer.toJS;
        final web.AudioBuffer audioBufferJs = await promiseToFuture(
          audioContext.decodeAudioData(jsArrayBuffer),
        );

        final int numberOfChannels = audioBufferJs.numberOfChannels.toInt();
        final int sampleRate = audioBufferJs.sampleRate.toInt();
        final int length = audioBufferJs.length.toInt();
        Float32List pcmDataDart;

        if (numberOfChannels == 1) {
          pcmDataDart = Float32List.fromList(audioBufferJs.getChannelData(0).toDart);
        } else {
          // Convert to mono by averaging channels
          pcmDataDart = Float32List(length);
          for (int i = 0; i < length; i++) {
            double sum = 0.0;
            for (int c = 0; c < numberOfChannels; c++) {
              sum += audioBufferJs.getChannelData(c).toDart[i];
            }
            pcmDataDart[i] = sum / numberOfChannels;
          }
        }
        // Web Audio API getChannelData already returns Float32Array in the range -1.0 to 1.0
        audioContext.close();
        return DecodedAudio(audioBuffer: pcmDataDart, sampleRate: sampleRate);
      } catch (e) {
        throw Exception('Error decoding audio with Web Audio API: $e');
      }
    } else {
      // Mobile (Android/iOS) implementation
      if (fileExtension == 'wav') {
        try {
          final wavFile = wav_io.Wav.read(bytes);
          final int sampleRate = wavFile.samplesPerSecond;
          final int numChannels = wavFile.channels.length;
          final int numFrames = wavFile.channels[0].length;

          Float32List pcmDataMono;

          // wav_io.Wav.read returns List<List<double>>, where samples are already in -1.0 to 1.0 range.
          // No further normalization needed if the source WAV was standard float.
          // If it was int16/int24/int32, wav_io handles the conversion to double in [-1, 1].

          if (numChannels == 1) {
            pcmDataMono = Float32List.fromList(wavFile.channels[0]);
          } else {
            // Convert to mono by averaging channels
            pcmDataMono = Float32List(numFrames);
            for (int i = 0; i < numFrames; i++) {
              double sum = 0.0;
              for (int c = 0; c < numChannels; c++) {
                sum += wavFile.channels[c][i];
              }
              pcmDataMono[i] = sum / numChannels;
            }
          }
          return DecodedAudio(audioBuffer: pcmDataMono, sampleRate: sampleRate);
        } catch (e) {
          throw Exception('Error decoding WAV file on mobile: $e');
        }
      } else if (fileExtension == 'mp3') {
        // TODO: Implement MP3 decoding for mobile using flutter_sound or another library
        // This will likely involve:
        // 1. Writing bytes to a temporary file.
        // 2. Using flutter_sound's pcmExtractor or similar to get PCM data.
        // 3. Normalizing PCM data to Float32List in [-1.0, 1.0] range.
        // Implemented MP3 decoding for mobile using flutter_sound
        FlutterSoundPlayer? player = FlutterSoundPlayer();
        FlutterSoundHelper helper = FlutterSoundHelper();
        io.Directory tempDir = await getTemporaryDirectory();
        String tempInputPath = p.join(tempDir.path, "temp_input.mp3");
        String tempOutputPath = p.join(tempDir.path, "temp_output.pcm");
        io.File tempInputFile = io.File(tempInputPath);
        io.File tempOutputFile = io.File(tempOutputPath);

        try {
          await tempInputFile.writeAsBytes(bytes, flush: true);

          // Initialize player to use getMediaProperties
          await player.openPlayer();

          MediaProperties? mediaProperties = await player.getMediaProperties(tempInputPath);
          // Default to 44100 if sampleRate is not available, though it's unlikely for MP3.
          int sampleRate = mediaProperties?.sampleRate?.toInt() ?? 44100;
          // int originalNumChannels = mediaProperties?.numChannels?.toInt() ?? 1;

          // Extract PCM data.
          // pcmExtractor will output 16-bit PCM data.
          // We request 1 channel (mono). If the source is stereo, flutter_sound
          // might mix down or take one channel. This aligns with the spec:
          // "utilizando el promedio entre canales o un canal específico".
          await helper.pcmExtractor(
            tempInputPath,
            tempOutputPath,
            sampleRate, // Use the determined sample rate of the media
            1,          // Number of channels (1 for mono)
            16,         // Bit depth (16-bit)
          );

          if (!await tempOutputFile.exists() || await tempOutputFile.length() == 0) {
            throw Exception('PCM extractor failed to create output file or the file is empty.');
          }

          Uint8List pcmBytes = await tempOutputFile.readAsBytes();

          // The pcmBytes are 16-bit signed PCM, so two bytes per sample.
          Int16List pcmInt16 = pcmBytes.buffer.asInt16List();

          Float32List pcmFloat32 = Float32List(pcmInt16.length);
          for (int i = 0; i < pcmInt16.length; i++) {
            pcmFloat32[i] = pcmInt16[i] / 32768.0; // Normalize to [-1.0, 1.0]
          }

          return DecodedAudio(audioBuffer: pcmFloat32, sampleRate: sampleRate);

        } catch (e) {
          // Try to provide more specific error if possible
          if (e is PlayerException && e.message != null && e.message!.contains("No such file")) {
             throw Exception('Error decoding MP3 on mobile: Input file for pcmExtractor not found or inaccessible. Path: $tempInputPath. Original error: $e');
          }
          throw Exception('Error decoding MP3 file on mobile: $e');
        } finally {
          await player.closePlayer();
          player = null; // Release the player object
          if (await tempInputFile.exists()) {
            try { await tempInputFile.delete(); } catch (_) {} // Ignore delete errors
          }
          if (await tempOutputFile.exists()) {
            try { await tempOutputFile.delete(); } catch (_) {} // Ignore delete errors
          }
        }
      } else {
        throw Exception('Unsupported file extension for mobile decoding: $fileExtension. Only wav and mp3 are supported.');
      }
    }
  }
}