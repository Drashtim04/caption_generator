/// Holds captions produced by [CaptionEngine].
class CaptionResponse {
  /// The generated (and optionally transformed) captions.
  final List<String> captions;

  /// The request that produced these captions – kept for traceability.
  final String requestSummary;

  const CaptionResponse({
    required this.captions,
    this.requestSummary = '',
  });

  /// Convenience factory when there are no results.
  factory CaptionResponse.empty() =>
      const CaptionResponse(captions: [], requestSummary: '');

  bool get isEmpty => captions.isEmpty;

  @override
  String toString() =>
      'CaptionResponse(${captions.length} captions, summary: "$requestSummary")';
}
