import 'dart:typed_data';
import 'package:geiger_calc/services/audio_decoder_service.dart';

class AudioDecoderServiceImpl {
  static Future<DecodedAudio> decodeAudioBytes(Uint8List bytes, String fileExtension) async {
    throw UnsupportedError('Cannot decode audio on this platform.');
  }
}
