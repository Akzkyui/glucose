/// 测量时间段标签枚举
enum GlucoseTimeTag {
  fasting, // 空腹
  afterBreakfast2h, // 早餐后2h
  beforeLunch, // 午餐前
  afterLunch2h, // 午餐后2h
  beforeDinner, // 晚餐前
  afterDinner2h, // 晚餐后2h
  beforeSleep, // 睡前
}

/// 扩展枚举，增加获取中文显示名称的方法
extension GlucoseTimeTagExtension on GlucoseTimeTag {
  String get displayName {
    switch (this) {
      case GlucoseTimeTag.fasting:
        return '空腹';
      case GlucoseTimeTag.afterBreakfast2h:
        return '早餐后2h';
      case GlucoseTimeTag.beforeLunch:
        return '午餐前';
      case GlucoseTimeTag.afterLunch2h:
        return '午餐后2h';
      case GlucoseTimeTag.beforeDinner:
        return '晚餐前';
      case GlucoseTimeTag.afterDinner2h:
        return '晚餐后2h';
      case GlucoseTimeTag.beforeSleep:
        return '睡前';
    }
  }
}

/// 血糖记录模型
class GlucoseRecord {
  final int? id; // 数据库自增 ID（新建记录时为空）
  final DateTime timestamp; // 测量时间戳
  final double glucoseValue; // 血糖值 (mmol/L)
  final GlucoseTimeTag timeTag; // 测量时间段标签
  final int baselineSteps; // 记录血糖时的当前系统总计步基线，用于计算时差内的真实步行量

  GlucoseRecord({
    this.id,
    required this.timestamp,
    required this.glucoseValue,
    required this.timeTag,
    this.baselineSteps = 0, // 默认赋予 0 保持向后及旧数据兼容
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp.toIso8601String(),
      'glucoseValue': glucoseValue,
      'timeTag': timeTag.index,
      'baselineSteps': baselineSteps,
    };
  }

  factory GlucoseRecord.fromMap(Map<String, dynamic> map) {
    return GlucoseRecord(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      glucoseValue: map['glucoseValue'] as double,
      timeTag: GlucoseTimeTag.values[map['timeTag'] as int],
      baselineSteps: map['baselineSteps'] as int? ?? 0,
    );
  }

  GlucoseRecord copyWith({
    int? id,
    DateTime? timestamp,
    double? glucoseValue,
    GlucoseTimeTag? timeTag,
    int? baselineSteps,
  }) {
    return GlucoseRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      glucoseValue: glucoseValue ?? this.glucoseValue,
      timeTag: timeTag ?? this.timeTag,
      baselineSteps: baselineSteps ?? this.baselineSteps,
    );
  }
}
