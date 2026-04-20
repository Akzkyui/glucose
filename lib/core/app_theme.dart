import 'package:flutter/material.dart';

/// 统一色彩与主题配置，采用现代健康、极简科技感风格
class AppTheme {
  // 主色调：具有活力和生命力的青绿色
  static const Color primaryTeal = Color(0xFF00CBA9);
  // 备用主色调（可用于高亮对比）：湛蓝色
  static const Color primaryAzure = Color(0xFF007AFF);
  // 警告色调：用于低血糖风险提示等
  static const Color warningRed = Color(0xFFFF3B30);

  // 背景色组合：纯白背景和稍微偏暖的白底
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color pureWhite = Colors.white;

  // 文本色调：深色和次级灰色
  static const Color textPrimary = Color(0xFF2D3142);
  static const Color textSecondary = Color(0xFF9094A6);

  // 卡片层级阴影：清晰且柔和的灰度阴影 (类似 Apple Health 风格)
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  // 全局浅色主题配置
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        secondary: primaryAzure,
        surface: pureWhite,
        error: warningRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: pureWhite,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      // 大圆角卡片样式
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: pureWhite,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      // 字体排版风格
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      ),
    );
  }
}
