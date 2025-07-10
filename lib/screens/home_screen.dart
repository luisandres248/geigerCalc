import 'package:flutter/material.dart';
import 'package:geiger_calc/widgets/analysis_form.dart';
import 'package:geiger_calc/widgets/audio_input_handler.dart';
import 'package:geiger_calc/widgets/audio_visualizer.dart';
import 'package:geiger_calc/widgets/results_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeigerCalc'),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AudioInputHandler(),
            const SizedBox(height: 16),
            const Expanded(
              flex: 2,
              child: AudioVisualizer(),
            ),
            const SizedBox(height: 16),
            const Expanded(
              flex: 3,
              child: AnalysisForm(),
            ),
            const SizedBox(height: 16),
            const ResultsPanel(),
          ],
        ),
      ),
    );
  }
}
