import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';

class RateLimitService {
  static const _keyDate = "gen_date";
  static const _keyCount = "gen_count";

  Future<bool> canGenerate() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    final savedDate = prefs.getString(_keyDate);
    if (savedDate != today) {
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyCount, 0);
      return true;
    }

    final count = prefs.getInt(_keyCount) ?? 0;
    return count < AppConstants.dailyMaxGenerations;
  }

  Future<int> remaining() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    final savedDate = prefs.getString(_keyDate);
    if (savedDate != today) return AppConstants.dailyMaxGenerations;

    final count = prefs.getInt(_keyCount) ?? 0;
    final left = AppConstants.dailyMaxGenerations - count;
    return left < 0 ? 0 : left;
  }

  Future<void> consumeOne() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    final savedDate = prefs.getString(_keyDate);
    if (savedDate != today) {
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyCount, 1);
      return;
    }

    final count = prefs.getInt(_keyCount) ?? 0;
    await prefs.setInt(_keyCount, count + 1);
  }

  String _todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";
  }
}
