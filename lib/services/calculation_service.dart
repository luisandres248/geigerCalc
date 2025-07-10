import '../models/analysis_params.dart';

class CalculationResult {
  final double countsPerSecond;
  final double countsPerMinute;
  final double activityBq;

  CalculationResult({
    required this.countsPerSecond,
    required this.countsPerMinute,
    required this.activityBq,
  });
}

class CalculationService {
  static CalculationResult calculateMetrics({
    required int counts,
    required AnalysisParams params,
  }) {
    if (params.analysisDurationS <= 0) {
      return CalculationResult(countsPerSecond: 0, countsPerMinute: 0, activityBq: 0);
    }

    final double countsPerSecond = counts / params.analysisDurationS;
    final double countsPerMinute = countsPerSecond * 60;

    final double activityBq = (params.detectorEfficiency > 0)
        ? (countsPerSecond / params.detectorEfficiency)
        : 0;

    return CalculationResult(
      countsPerSecond: countsPerSecond,
      countsPerMinute: countsPerMinute,
      activityBq: activityBq,
    );
  }
}
