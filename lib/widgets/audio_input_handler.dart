import 'package:flutter/material.dart';
import 'package:geiger_calc/state/app_state.dart';
import 'package:provider/provider.dart';

class AudioInputHandler extends StatelessWidget {
  const AudioInputHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: appState.isLoading
                  ? null
                  : () {
                      if (appState.isRecording) {
                        appState.stopRecording();
                      } else {
                        appState.startRecording();
                      }
                    },
              icon: appState.isRecording ? const Icon(Icons.stop) : const Icon(Icons.mic),
              label: Text(appState.isRecording ? 'Stop Recording' : 'Record Audio'),
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