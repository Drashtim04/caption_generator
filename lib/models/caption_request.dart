/// Supported caption categories with their associated tones.
enum CaptionCategory {
  men,
  women,
  savage,
  romantic,
  funny,
  aesthetic,
  travel,
  fitness,
  attitude,
  none,
}

/// Desired length of generated captions.
enum CaptionLength {
  short,
  medium,
  long,
}

/// Style transformations that can be applied.
enum CaptionStyle {
  humanize,
  rhyming,
  savage,
  funny,
  romantic,
}

/// Encapsulates all parameters for a caption generation request.
class CaptionRequest {
  /// Thematic category that determines the tone of generated captions.
  final CaptionCategory category;

  /// Controls how long / descriptive the captions are.
  final CaptionLength length;

  /// Free-form keywords used to make captions contextually relevant.
  final String keywords;

  /// One or more style transformations to apply to the captions.
  final List<CaptionStyle> styles;

  /// When true, the engine will delegate to an external AI API (future use).
  final bool useAI;

  const CaptionRequest({
    required this.category,
    required this.length,
    this.keywords = '',
    this.styles = const [],
    this.useAI = false,
  });

  /// Returns a copy of this request with selected fields overridden.
  CaptionRequest copyWith({
    CaptionCategory? category,
    CaptionLength? length,
    String? keywords,
    List<CaptionStyle>? styles,
    bool? useAI,
  }) {
    return CaptionRequest(
      category: category ?? this.category,
      length: length ?? this.length,
      keywords: keywords ?? this.keywords,
      styles: styles ?? this.styles,
      useAI: useAI ?? this.useAI,
    );
  }

  @override
  String toString() =>
      'CaptionRequest(category: $category, length: $length, '
      'keywords: "$keywords", styles: $styles, useAI: $useAI)';
}
