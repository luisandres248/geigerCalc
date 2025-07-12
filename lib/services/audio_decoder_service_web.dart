import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'dart:js_util';
import 'dart:js_interop';
import 'package:geiger_calc/services/audio_decoder_service.dart'; // For DecodedAudio

class AudioDecoderServiceImpl {
  static Future<DecodedAudio> decodeAudioBytes(Uint8List bytes, String fileExtension) async {
    // The web implementation can handle various formats, so fileExtension is not strictly needed but kept for API consistency.
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
        pcmDataDart = Float32List(length);
        for (int i = 0; i < length; i++) {
          double sum = 0.0;
          for (int c = 0; c < numberOfChannels; c++) {
            sum += audioBufferJs.getChannelData(c).toDart[i];
          }
          pcmDataDart[i] = sum / numberOfChannels;
        }
      }
      audioContext.close();
      return DecodedAudio(audioBuffer: pcmDataDart, sampleRate: sampleRate);
    } catch (e) {
      throw Exception('Error decoding audio with Web Audio API: $e');
    }
  }
}
