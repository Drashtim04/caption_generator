import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/backend_caption_service.dart';
import '../services/caption_engine.dart';
import '../services/rate_limit_service.dart';
import '../services/admob_service.dart';
import '../services/history_service.dart';
import '../models/caption_result.dart';
import '../models/caption_request.dart';
import '../utils/app_constants.dart';

class CaptionProvider extends ChangeNotifier {
  final _backend = BackendCaptionService();
  final _rate = RateLimitService();
  final _history = HistoryService();
  final _engine = CaptionEngine();

  final AdMobService ads;

  CaptionProvider({required this.ads});

  bool loading = false;
  String? error;

  String? imageDescription;
  List<String> captions = [];
  List<String> tags = [];
  String? mood;
  List<CaptionHistoryEntry> history = [];

  // ── Caption Engine parameters ────────────────────────────────────────────
  CaptionCategory selectedCategory = CaptionCategory.men;
  CaptionLength selectedLength = CaptionLength.medium;
  String keywords = '';
  List<CaptionStyle> selectedStyles = [];

  void setCategory(CaptionCategory cat) {
    selectedCategory = cat;
    notifyListeners();
  }

  void setLength(CaptionLength len) {
    selectedLength = len;
    notifyListeners();
  }

  void setKeywords(String kw) {
    keywords = kw;
    // no notifyListeners – called on every keystroke; UI reads from controller
  }

  void toggleStyle(CaptionStyle style) {
    if (selectedStyles.contains(style)) {
      selectedStyles = selectedStyles.where((s) => s != style).toList();
    } else {
      selectedStyles = [...selectedStyles, style];
    }
    notifyListeners();
  }

  /// Returns transformed variants of [caption] using [selectedStyles].
  /// Falls back to all styles when nothing is selected.
  List<String> transformCaption(String caption) {
    final stylesToApply =
        selectedStyles.isNotEmpty ? selectedStyles : CaptionStyle.values.toList();
    return _engine.transformCaption(caption, stylesToApply);
  }
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> loadHistory() async {
    history = await _history.fetchHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _history.clearHistory();
    history = [];
    notifyListeners();
  }

  Future<int> remainingToday() => _rate.remaining();

  void clear() {
    error = null;
    imageDescription = null;
    captions = [];
    tags = [];
    mood = null;
    notifyListeners();
  }

  Future<void> generateFromImageBytes(Uint8List? imageBytes) async {
    error = null;

    if (imageBytes == null) {
      error = "Please select an image first.";
      notifyListeners();
      return;
    }

    // connectivity_plus v6+ returns List<ConnectivityResult>
    final connectivityList = await Connectivity().checkConnectivity();
    final hasConnection = connectivityList.any(
      (r) => r != ConnectivityResult.none,
    );
    if (!hasConnection) {
      error = "No internet connection.";
      notifyListeners();
      return;
    }

    final can = await _rate.canGenerate();
    if (!can) {
      error =
          "Daily limit reached (${AppConstants.dailyMaxGenerations}/day). Try tomorrow.";
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    try {
      // 1. Interstitial ad (existing)
      ads.showInterstitialIfReady();

      // 2. Backend: image → description + raw captions + tags + mood
      List<String> backendCaptions = [];
      try {
        final result = await _backend.generate(imageBytes);
        imageDescription = result.description;
        tags = result.tags;
        mood = result.mood;
        backendCaptions = result.captions;
      } catch (e) {
        debugPrint("Backend failed: $e");
        // imageDescription and tags remain null/empty as intended if backend fails
      }

      // 3. Apply selected styles to the backend captions (separated to avoid clearing data on error)
      if (backendCaptions.isNotEmpty && selectedStyles.isNotEmpty) {
        try {
          backendCaptions = backendCaptions.map((c) {
            final variants = _engine.transformCaption(c, selectedStyles);
            return variants.isNotEmpty ? variants.first : c;
          }).toList();
        } catch (e) {
          debugPrint("Style transformation failed: $e");
        }
      }

      // 4. Generate local captions using category / length / keywords / styles
      final contextualKeywords = keywords.trim();

      final request = CaptionRequest(
        category: selectedCategory,
        length: selectedLength,
        keywords: contextualKeywords,
        styles: selectedStyles,
        useAI: false,
      );
      final engineResponse = await _engine.generate(request);

      // 5. Merge & deduplicate (backend first, engine captions appended)
      final seen = <String>{};
      final merged = <String>[];
      for (final c in [...backendCaptions, ...engineResponse.captions]) {
        final key = c.trim().toLowerCase();
        if (key.isNotEmpty && seen.add(key)) merged.add(c.trim());
      }
      captions = merged;

      await _rate.consumeOne();

      // 6. Save to history (use provider fields already set above)
      final entry = CaptionHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        description: imageDescription ?? '',
        captions: captions,
        tags: tags,
        mood: mood,
        imageBase64: base64Encode(imageBytes),
      );
      await _history.saveResult(entry);
      history = [entry, ...history];
      if (history.length > AppConstants.historyMaxEntries) {
        history = history.sublist(0, AppConstants.historyMaxEntries);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
