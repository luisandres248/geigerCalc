import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'dart:js_util';
import 'dart:js_interop';

class DecodedAudio {
  final Float32List audioBuffer;
  final int sampleRate;

  DecodedAudio({
    required this.audioBuffer,
    required this.sampleRate,
  });
}

class AudioDecoderService {
  static Future<DecodedAudio> decodeAudioBytes(Uint8List bytes) async {
    try {
      final audioContext = web.AudioContext();

      // Convert Uint8List to JavaScript ArrayBuffer
      final jsArrayBuffer = bytes.buffer.toJS;

      // Decode the audio data using promiseToFuture
      final web.AudioBuffer audioBufferJs = await promiseToFuture(
        audioContext.decodeAudioData(jsArrayBuffer),
      );

      final int numberOfChannels = audioBufferJs.numberOfChannels.toInt();
      final int sampleRate = audioBufferJs.sampleRate.toInt();
      final int length = audioBufferJs.length.toInt();

      Float32List pcmDataDart;

      if (numberOfChannels == 1) {
        // Explicitly convert JSFloat32Array to Dart Float32List
        pcmDataDart = Float32List.fromList(audioBufferJs.getChannelData(0).toDart);
      } else {
        // Convert to mono by averaging channels
        pcmDataDart = Float32List(length);
        for (int i = 0; i < length; i++) {
          double sum = 0.0;
          for (int c = 0; c < numberOfChannels; c++) {
            // Explicitly convert JSFloat32Array to Dart List and then access element
            sum += audioBufferJs.getChannelData(c).toDart[i];
          }
          pcmDataDart[i] = sum / numberOfChannels;
        }
      }

      audioContext.close();

      return DecodedAudio(
        audioBuffer: pcmDataDart,
        sampleRate: sampleRate,
      );
    } catch (e) {
      throw Exception('Error decoding audio with Web Audio API: $e');
    }
  }
}