import 'package:flutter/material.dart';
import 'package:geiger_calc/state/app_state.dart';
import 'package:provider/provider.dart';

class ResultsPanel extends StatelessWidget {
  const ResultsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final result = appState.result;
        final audioData = appState.audioData;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Results', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ResultDisplay(label: 'Bq', value: result?.activityBq.toStringAsFixed(2) ?? '-'),
                    _ResultDisplay(label: 'CPM', value: result?.countsPerMinute.toStringAsFixed(0) ?? '-'),
                    _ResultDisplay(label: 'CPS', value: result?.countsPerSecond.toStringAsFixed(2) ?? '-'),
                  ],
                ),
                const Divider(height: 24),
                const Text('Audio Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Time: ${audioData?.totalDurationSeconds.toStringAsFixed(1) ?? '-'} s'),
                    Text('Max Amp: ${audioData?.maxAmplitude.toStringAsFixed(2) ?? '-'}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Avg Amp (RMS): ${audioData?.averageAmplitude.toStringAsFixed(2) ?? '-'}'),
                    Text('Min Peak Dist: ${audioData?.minPeakDistanceMs.toStringAsFixed(0) ?? '-'} ms'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResultDisplay extends StatelessWidget {
  final String label;
  final String value;

  const _ResultDisplay({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
