import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

/// 共享偏好工具类，封装对用户配置和身体档案的本地读写
class PreferencesHelper {
  static const String _userProfileKey = 'user_profile_data';

  /// 保存 UserProfile 到 SharedPreferences
  static Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toMap());
      return await prefs.setString(_userProfileKey, profileJson);
    } catch (e) {
      // ignore: avoid_print
      print('Error saving UserProfile to SharedPreferences: $e');
      return false;
    }
  }

  /// 从 SharedPreferences 读取 UserProfile
  /// 如果初次打开或尚未保存数据，将返回 null
  static Future<UserProfile?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileString = prefs.getString(_userProfileKey);

      if (profileString != null && profileString.isNotEmpty) {
        final Map<String, dynamic> profileMap = jsonDecode(profileString);
        return UserProfile.fromMap(profileMap);
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Error reading UserProfile from SharedPreferences: $e');
      return null;
    }
  }

  // ============== 计步辅助模块 ==============
  static const String _stepBaselineDateKey = 'step_baseline_date';
  static const String _stepBaselineValueKey = 'step_baseline_value';

  /// 保存今天的基准步数，date 应传入 yyyy-MM-dd
  static Future<void> saveStepBaseline(String date, int baseline) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_stepBaselineDateKey, date);
      await prefs.setInt(_stepBaselineValueKey, baseline);
    } catch (e) {
      // ignore: avoid_print
      print('Error saving step baseline: $e');
    }
  }

  /// 获取最新存入基准步数的时间与刻度的 Map
  static Future<Map<String, dynamic>?> getStepBaseline() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final date = prefs.getString(_stepBaselineDateKey);
      if (date == null) return null;
      // 防止空指针，默认托底 0
      final value = prefs.getInt(_stepBaselineValueKey) ?? 0;
      return {'date': date, 'value': value};
    } catch (e) {
      // ignore: avoid_print
      print('Error parsing step baseline: $e');
      return null;
    }
  }
}
