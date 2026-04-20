class RecommendationResult {
  final String title;
  final String message;
  final String severity; // 'critical', 'warning', 'info', 'success'

  RecommendationResult({
    required this.title,
    required this.message,
    required this.severity,
  });
}

/// 基于预设阈值与复合条件的本地离线健康建议判定引擎
class RecommendationEngine {
  // 1. 全局危险阈值 (单位: mmol/L)
  static const double hypoThreshold = 3.9;
  static const double hyperDangerThreshold = 13.9;
  static const double preMealLowWarning = 4.4;
  static const double bedtimeLowWarning = 6.0;

  // 2. 活动卡路里阈值 (单位: kcal)
  static const double calLightActivity = 50.0;
  static const double calSufficientActivity = 150.0;

  /// 根据输入的当前状态返回一条决策判定结果
  /// [timeTag] 支持 'fasting', 'preMeal', 'postMeal', 'bedtime' 四类粗粒度识别
  static RecommendationResult evaluate({
    required double bloodSugar,
    required String timeTag,
    required double activeCalories,
    required bool isDiabetic,
  }) {
    // 3. 动态目标阈值定义
    final double fastingTargetMax = isDiabetic ? 7.0 : 6.1;
    final double postMealTargetMax = isDiabetic ? 10.0 : 7.8;
    final double fastingHighWarning = isDiabetic ? 10.0 : 7.0;
    final double bedtimeHighWarning = isDiabetic ? 10.0 : 7.0;

    // ----- 优先级 1：全局高危 (无视时段与卡路里) -----
    if (bloodSugar < hypoThreshold) {
      return RecommendationResult(
        title: '【危急】',
        message: '检测到低血糖！请立即补充15g快发碳水（如糖水、果汁），15分钟后复测。血糖恢复正常前，请绝对避免任何运动！',
        severity: 'critical',
      );
    } else if (bloodSugar > hyperDangerThreshold) {
      return RecommendationResult(
        title: '【危急】',
        message: '当前血糖显著偏高。请多喝水促进排泄，切勿进行剧烈运动（以免诱发酮症）。如伴有恶心、腹痛等不适，请立即就医。',
        severity: 'critical',
      );
    }

    // ----- 优先级 2：空腹/餐前时段 -----
    if (timeTag == 'fasting' || timeTag == 'preMeal') {
      if (bloodSugar < preMealLowWarning) {
        return RecommendationResult(
          title: '【提示】',
          message: '当前血糖偏低。请勿空腹运动，建议尽快正常进餐，并在餐后关注血糖变化。',
          severity: 'warning',
        );
      } else if (bloodSugar <= fastingTargetMax &&
          activeCalories < calLightActivity) {
        return RecommendationResult(
          title: '【良好】',
          message: '空腹/餐前血糖控制得非常完美。请安心享用下一餐，保持当前的健康节奏。',
          severity: 'success',
        );
      } else if (bloodSugar <= fastingTargetMax &&
          activeCalories >= calLightActivity) {
        return RecommendationResult(
          title: '【活力】',
          message: '空腹/餐前血糖完美达标，且您已经保持了不错的活动量！由于有能量消耗，下一餐请注意适量补充优质碳水。',
          severity: 'success',
        );
      } else if (bloodSugar > fastingTargetMax &&
          bloodSugar <= fastingHighWarning &&
          activeCalories < calLightActivity) {
        return RecommendationResult(
          title: '【行动】',
          message:
              '当前血糖略高于目标值。建议您正常进餐，并计划在餐后半小时进行15分钟的轻松散步，这有助于提升胰岛素敏感性，平稳全天血糖。',
          severity: 'info',
        );
      } else if (bloodSugar > fastingTargetMax &&
          bloodSugar <= fastingHighWarning &&
          activeCalories >= calLightActivity) {
        return RecommendationResult(
          title: '【鼓励】',
          message: '虽然当前血糖略高，但您已经进行了积极的活动！规律的运动对改善代谢非常有益，请继续保持，下一餐注意控制碳水摄入。',
          severity: 'info',
        );
      } else if (bloodSugar > fastingHighWarning &&
          activeCalories < calLightActivity) {
        return RecommendationResult(
          title: '【干预】',
          message:
              '当前血糖明显偏高！建议您先进行15-20分钟的中低强度活动（如快走），再根据身体感受平缓进餐，并严格控制本餐的主食分量。',
          severity: 'warning',
        );
      } else if (bloodSugar > fastingHighWarning &&
          activeCalories >= calLightActivity) {
        return RecommendationResult(
          title: '【留意】',
          message: '当前血糖明显偏高。虽然您已经有过活动，但接下来的饮食仍需格外警惕，避免摄入过多快速升糖食物，建议多补充水分。',
          severity: 'warning',
        );
      }
    }
    // ----- 优先级 3：餐后时段 -----
    else if (timeTag == 'postMeal') {
      if (bloodSugar <= postMealTargetMax &&
          activeCalories < calLightActivity) {
        return RecommendationResult(
          title: '【安逸】',
          message: '餐后血糖平稳达标，继续保持良好的饮食结构。',
          severity: 'success',
        );
      } else if (bloodSugar <= postMealTargetMax &&
          activeCalories >= calLightActivity) {
        return RecommendationResult(
          title: '【卓越】',
          message: '餐后血糖完美达标，且您饭后进行了适宜的活动，这对您的健康是十分有益的。',
          severity: 'success',
        );
      } else if (bloodSugar > postMealTargetMax &&
          activeCalories < calLightActivity) {
        return RecommendationResult(
          title: '【干预】',
          message:
              '餐后血糖偏高，且您目前基本处于静坐状态。建议立刻起身进行15-20分钟的轻中度活动（如散步或家务），让肌肉直接吸收血液中的糖分，削平血糖尖峰！',
          severity: 'warning',
        );
      } else if (bloodSugar > postMealTargetMax &&
          activeCalories >= calLightActivity &&
          activeCalories < calSufficientActivity) {
        return RecommendationResult(
          title: '【跟进】',
          message: '餐后血糖偏高，但您已经进行了轻度运动以干预，建议您继续保持运动，稍后可再次复测观察血糖回落情况。',
          severity: 'info',
        );
      } else if (bloodSugar > postMealTargetMax &&
          activeCalories >= calSufficientActivity) {
        return RecommendationResult(
          title: '【表扬】',
          message:
              '虽然餐后血糖偏高，但您已完成了充足的活动量！运动能有效改善胰岛素抵抗。请适当补充水分，避免过度劳累，留意随后的血糖下降。',
          severity: 'success',
        );
      }
    }
    // ----- 优先级 4：睡前时段 -----
    else if (timeTag == 'bedtime') {
      if (bloodSugar <= bedtimeLowWarning) {
        return RecommendationResult(
          title: '【防范】',
          message: '睡前血糖偏低，夜间存在低血糖风险。建议睡前补充少量慢吸收碳水（如半杯牛奶或两块饼干），并禁止任何剧烈运动。',
          severity: 'warning',
        );
      } else if (bloodSugar > bedtimeHighWarning) {
        return RecommendationResult(
          title: '【警惕】',
          message: '睡前血糖明显偏高，可能导致夜间休息不佳或晨起高血糖。建议适量饮水促进代谢，不建议再进食任何食物。',
          severity: 'warning',
        );
      } else if (bloodSugar > bedtimeLowWarning &&
          bloodSugar <= bedtimeHighWarning &&
          activeCalories > calLightActivity) {
        return RecommendationResult(
          title: '【提醒】',
          message: '睡前血糖安全，但您刚才消耗了较多热量。运动后的代谢加快可能增加夜间低血糖风险，请准备休息，必要时可在床头备好糖果。',
          severity: 'warning',
        );
      } else if (bloodSugar > bedtimeLowWarning &&
          bloodSugar <= bedtimeHighWarning &&
          activeCalories <= calLightActivity) {
        return RecommendationResult(
          title: '【晚安】',
          message: '睡前状态非常平稳，活动量也恰到好处。祝您有个好梦，明天继续保持！',
          severity: 'success',
        );
      }
    }

    // ----- 优先级 5：兜底策略 -----
    return RecommendationResult(
      title: '【良好】',
      message: '您的数据已成功记录且无特殊情况。请遵循医嘱，或根据身体的真实感受来安排接下来的活动，保持好心情！',
      severity: 'info',
    );
  }
}
