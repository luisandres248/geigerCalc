
class AnalysisParams {
  final double threshold;
  final int minSpacingMs;
  final int analysisDurationS;
  final double detectorEfficiency;
  final double sampleVolume;
  final String? isotope;

  AnalysisParams({
    this.threshold = 0.5,
    this.minSpacingMs = 50,
    this.analysisDurationS = 60,
    this.detectorEfficiency = 0.15,
    this.sampleVolume = 1.0,
    this.isotope,
  });

  AnalysisParams copyWith({
    double? threshold,
    int? minSpacingMs,
    int? analysisDurationS,
    double? detectorEfficiency,
    double? sampleVolume,
    String? isotope,
  }) {
    return AnalysisParams(
      threshold: threshold ?? this.threshold,
      minSpacingMs: minSpacingMs ?? this.minSpacingMs,
      analysisDurationS: analysisDurationS ?? this.analysisDurationS,
      detectorEfficiency: detectorEfficiency ?? this.detectorEfficiency,
      sampleVolume: sampleVolume ?? this.sampleVolume,
      isotope: isotope ?? this.isotope,
    );
  }
}
