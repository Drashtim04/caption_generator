import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/caption_result.dart';
import '../utils/app_constants.dart';

class HistoryService {
  static const _keyHistory = "caption_history";

  Future<List<CaptionHistoryEntry>> fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyHistory);
    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((e) => CaptionHistoryEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> saveResult(CaptionHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _readRawList(prefs);

    current.add(entry.toMap());

    final trimmed = _trimToMax(current);
    await prefs.setString(_keyHistory, jsonEncode(trimmed));
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHistory);
  }

  Future<List<Map<String, dynamic>>> _readRawList(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_keyHistory);
    if (raw == null || raw.trim().isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<Map<String, dynamic>> _trimToMax(List<Map<String, dynamic>> list) {
    final max = AppConstants.historyMaxEntries;
    if (list.length <= max) return list;
    return list.sublist(list.length - max);
  }
}
