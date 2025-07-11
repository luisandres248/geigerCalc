import 'package:flutter/material.dart';
import 'package:geiger_calc/state/app_state.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AudioInputHandler extends StatelessWidget {
  const AudioInputHandler({super.key});

  Future<void> _handleRecordAudio(BuildContext context, AppState appState) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio recording is not available on the Web platform.'),
        ),
      );
      return;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        appState.startRecording();
      } else if (status.isPermanentlyDenied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Microphone permission is permanently denied. Please enable it in app settings.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  openAppSettings();
                },
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required to record audio.'),
            ),
          );
        }
      }
    } else {
      // For other non-mobile, non-web platforms (e.g. desktop), attempt recording.
      // Desktop platforms might need specific permission handling not covered here.
      print("Attempting to record on non-mobile, non-web platform.");
      appState.startRecording();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: kIsWeb
                  ? null // Disabled on web
                  : appState.isRecording
                      ? () => appState.stopRecording() // Allow stopping if recording
                      : appState.isLoading
                          ? null // Disabled if loading (and not recording)
                          : () => _handleRecordAudio(context, appState), // Allow starting if not loading/recording
              icon: appState.isRecording ? const Icon(Icons.stop) : const Icon(Icons.mic),
              label: Text(kIsWeb
                  ? 'Record (Not on Web)'
                  : appState.isRecording
                      ? 'Stop Recording (${_formatDuration(appState.recordingDuration)})'
                      : 'Record Audio'),
            ),
            ElevatedButton.icon(
              onPressed: appState.isLoading ? null : appState.loadAudioAndAnalyze,
              icon: const Icon(Icons.upload_file),
              label: const Text('Load File'),
            ),
          ],
        );
      },
    );
  }
}