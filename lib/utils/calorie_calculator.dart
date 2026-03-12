import '../models/user_profile.dart';

/// 健康计算工具类：提供与卡路里消耗等健康转换相关的纯函数
class CalorieCalculator {
  /// 计算在一段时间内总的热量大卡(kcal)消耗
  ///
  /// 该方法是一个纯函数，它汇总了基础代谢的分配时间，加上由步数引起的额外活动做功。
  ///
  /// 参数说明:
  /// * [profile]: 包含用户真实生理数据（体重、身高、年龄、性别等）档案
  /// * [steps]: 这段期间内产生的步行总步数
  /// * [durationHours]: 需要计算的时间跨度 (单位: 小时, 例如换算一整天传入 24)
  ///
  /// 返回计算出的大卡值(kcal)
  static double calculateTotalCalories({
    required UserProfile profile,
    required int steps,
    required double durationHours,
  }) {
    // 1. 计算这段时间内的基础代谢(静息)消耗
    // profile.bmr 是一整天 (24小时) 的基础消耗
    final double restingCalories = (profile.bmr / 24.0) * durationHours;

    // 2. 估算步数带来的活动消耗 (距离-体重推算法)
    // 根据用户步幅估算出步数距离 (公里)
    final double distanceKm = (steps * profile.strideLength) / 1000.0;

    // 步行带来的卡路里：每公里每公斤体重消耗约 1.036 大卡
    final double walkingCalories = profile.weight * distanceKm * 1.036;

    // 3. 总卡路里消耗即为（躺平静息耗能 + 额外活动耗能）
    return restingCalories + walkingCalories;
  }
}
