enum Gender { male, female }

/// 用户身体档案模型
class UserProfile {
  final int age; // 年龄
  final Gender gender; // 性别
  final double height; // 身高 (cm)
  final double weight; // 体重 (kg)
  final bool hasDiabetes; // 是否确诊糖尿病
  final bool isActual; // 数据是否由用户真实填写并保存过

  UserProfile({
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.hasDiabetes,
    this.isActual = true, // 默认构造认为是真实数据，由特殊占位指定为 false
  });

  // 便利方法：计算 BMI
  double get bmi => weight / ((height / 100) * (height / 100));

  /// 计算基础代谢率 (BMR) - Mifflin-St Jeor 公式 (一整天静息消耗大卡)
  double get bmr {
    // 基础部分: 10 * 体重(kg) + 6.25 * 身高(cm) - 5 * 年龄
    double baseBmr = 10 * weight + 6.25 * height - 5 * age;
    if (gender == Gender.female) {
      return baseBmr - 161;
    } else {
      // 男性
      return baseBmr + 5;
    }
  }

  /// 估算平均步幅 (米)
  double get strideLength {
    if (gender == Gender.female) {
      return height * 0.413 / 100;
    } else {
      // 男性
      return height * 0.415 / 100;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'age': age,
      'gender': gender.index,
      'height': height,
      'weight': weight,
      'hasDiabetes': hasDiabetes ? 1 : 0,
      'isActual': isActual ? 1 : 0,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      age: map['age'] as int,
      gender: Gender.values[map['gender'] as int],
      height: map['height'] as double,
      weight: map['weight'] as double,
      hasDiabetes: map['hasDiabetes'] == 1,
      isActual: map['isActual'] == 1,
    );
  }

  UserProfile copyWith({
    int? age,
    Gender? gender,
    double? height,
    double? weight,
    bool? hasDiabetes,
    bool? isActual,
  }) {
    return UserProfile(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      hasDiabetes: hasDiabetes ?? this.hasDiabetes,
      isActual: isActual ?? this.isActual,
    );
  }
}
