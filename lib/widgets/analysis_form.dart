import 'package:flutter/material.dart';
import 'package:geiger_calc/models/analysis_params.dart';
import 'package:geiger_calc/state/app_state.dart';
import 'package:provider/provider.dart';

class AnalysisForm extends StatelessWidget {
  const AnalysisForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final params = appState.params;
        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Analysis Parameters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildSlider(
                  context,
                  'Threshold',
                  params.threshold,
                  0.0,
                  1.0,
                  (newValue) => appState.updateAnalysisParams(
                    params.copyWith(threshold: newValue),
                  ),
                ),
                _buildSlider(
                  context,
                  'Min Spacing (ms)',
                  params.minSpacingMs.toDouble(),
                  10,
                  200,
                  (newValue) => appState.updateAnalysisParams(
                    params.copyWith(minSpacingMs: newValue.toInt()),
                  ),
                ),
                _buildSlider(
                  context,
                  'Detector Efficiency',
                  params.detectorEfficiency,
                  0.01,
                  1.0,
                  (newValue) => appState.updateAnalysisParams(
                    params.copyWith(detectorEfficiency: newValue),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlider(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(2)}'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / ((max - min) > 100 ? 1 : 0.01)).round(), // Adjust divisions based on range
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
