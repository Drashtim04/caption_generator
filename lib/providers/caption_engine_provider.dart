import 'package:flutter/material.dart';
import '../models/caption_request.dart';
import '../models/caption_response.dart';
import '../services/caption_engine.dart';

/// ---------------------------------------------------------------------------
/// CaptionEngineProvider
/// ---------------------------------------------------------------------------
/// A [ChangeNotifier] that wraps [CaptionEngine] and exposes state to the UI.
///
/// This is intentionally a *separate* provider from the existing
/// [CaptionProvider] so that the original image-based generation flow is
/// not touched at all.
/// ---------------------------------------------------------------------------
class CaptionEngineProvider extends ChangeNotifier {
  final _engine = CaptionEngine();

  // ---- State ----
  bool loading = false;
  String? error;
  CaptionResponse response = CaptionResponse.empty();

  // ---- Current request parameters (mutable for reactive UI) ----
  CaptionCategory selectedCategory = CaptionCategory.men;
  CaptionLength selectedLength = CaptionLength.medium;
  String keywords = '';
  List<CaptionStyle> selectedStyles = [];
  bool useAI = false;

  // ---- Transformed captions for the transformer panel ----
  String? transformInput; // the caption the user wants to transform
  List<String> transformedResults = [];

  // -------------------------------------------------------------------------
  // Setters (each calls notifyListeners)
  // -------------------------------------------------------------------------

  void setCategory(CaptionCategory category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setLength(CaptionLength length) {
    selectedLength = length;
    notifyListeners();
  }

  void setKeywords(String value) {
    keywords = value;
    notifyListeners();
  }

  void toggleStyle(CaptionStyle style) {
    if (selectedStyles.contains(style)) {
      selectedStyles = selectedStyles.where((s) => s != style).toList();
    } else {
      selectedStyles = [...selectedStyles, style];
    }
    notifyListeners();
  }

  void setUseAI({required bool value}) {
    useAI = value;
    notifyListeners();
  }

  void setTransformInput(String? caption) {
    transformInput = caption;
    transformedResults = [];
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  /// Generate captions from the current parameter state.
  Future<void> generateCaptions() async {
    error = null;
    loading = true;
    notifyListeners();

    try {
      final request = CaptionRequest(
        category: selectedCategory,
        length: selectedLength,
        keywords: keywords,
        styles: selectedStyles,
        useAI: useAI,
      );
      response = await _engine.generate(request);
    } catch (e) {
      error = e.toString();
      response = CaptionResponse.empty();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Transform [caption] into styled variants using all selected styles.
  /// If no styles are selected, every non-humanize style is tried.
  Future<void> transformCaption(String caption) async {
    error = null;
    loading = true;
    transformInput = caption;
    transformedResults = [];
    notifyListeners();

    try {
      final stylesToApply = selectedStyles.isNotEmpty
          ? selectedStyles
          : CaptionStyle.values; // try all when nothing selected

      final results = _engine.transformCaption(caption, stylesToApply);
      transformedResults = results;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Reset the response and any errors.
  void clear() {
    response = CaptionResponse.empty();
    transformedResults = [];
    transformInput = null;
    error = null;
    notifyListeners();
  }
}
