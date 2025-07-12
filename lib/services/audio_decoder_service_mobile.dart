import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:wav_io/wav_io.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:geiger_calc/services/audio_decoder_service.dart'; // For DecodedAudio

class AudioDecoderServiceImpl {
  static Future<DecodedAudio> decodeAudioBytes(Uint8List bytes, String fileExtension) async {
    fileExtension = fileExtension.toLowerCase();

    if (fileExtension == 'wav') {
      try {
        final wavFile = Wav.read(bytes);
        final int sampleRate = wavFile.samplesPerSecond;
        final int numChannels = wavFile.channels.length;
        final int numFrames = wavFile.channels[0].length;

        Float32List pcmDataMono;
        if (numChannels == 1) {
          pcmDataMono = Float32List.fromList(wavFile.channels[0]);
        } else {
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
      FlutterSoundPlayer? player = FlutterSoundPlayer();
      FlutterSoundHelper helper = FlutterSoundHelper();
      io.Directory tempDir = await getTemporaryDirectory();
      String tempInputPath = p.join(tempDir.path, "temp_input.mp3");
      String tempOutputPath = p.join(tempDir.path, "temp_output.pcm");
      io.File tempInputFile = io.File(tempInputPath);
      io.File tempOutputFile = io.File(tempOutputPath);

      try {
        await tempInputFile.writeAsBytes(bytes, flush: true);
        await player.openPlayer();

        // Note: getTrackProperties might not be available on all flutter_sound versions or platforms.
        // This is a potential point of failure if not supported.
        TrackProperties? trackProperties = await player.getTrackProperties(tempInputPath);
        int sampleRate = trackProperties?.sampleRate?.toInt() ?? 44100;

        await helper.pcmExtractor(
          tempInputPath,
          tempOutputPath,
          sampleRate,
          1, // mono
          16, // 16-bit
        );

        if (!await tempOutputFile.exists() || await tempOutputFile.length() == 0) {
          throw Exception('PCM extractor failed.');
        }

        Uint8List pcmBytes = await tempOutputFile.readAsBytes();
        Int16List pcmInt16 = pcmBytes.buffer.asInt16List();

        Float32List pcmFloat32 = Float32List(pcmInt16.length);
        for (int i = 0; i < pcmInt16.length; i++) {
          pcmFloat32[i] = pcmInt16[i] / 32768.0;
        }

        return DecodedAudio(audioBuffer: pcmFloat32, sampleRate: sampleRate);

      } catch (e) {
        throw Exception('Error decoding MP3 file on mobile: $e');
      } finally {
        await player.closePlayer();
        player = null;
        if (await tempInputFile.exists()) {
          try { await tempInputFile.delete(); } catch (_) {}
        }
        if (await tempOutputFile.exists()) {
          try { await tempOutputFile.delete(); } catch (_) {}
        }
      }
    } else {
      throw Exception('Unsupported file extension for mobile: $fileExtension');
    }
  }
}
