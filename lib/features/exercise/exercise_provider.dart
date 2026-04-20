import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/glucose_record.dart';
import '../settings/settings_provider.dart';
import '../dashboard/dashboard_provider.dart';
import '../../utils/calorie_calculator.dart';
import '../main_layout.dart';
import 'step_provider.dart';

/// 当日运动快照聚合数据包
class ExerciseState {
  final GlucoseRecord? lastRecord;
  final int activeSteps;
  final double activeCalories;

  ExerciseState({
    required this.lastRecord,
    required this.activeSteps,
    required this.activeCalories,
  });
}

/// 聚合计算的引擎桥接态：同步提供最新的测糖卡路里、步数等合并流
final exerciseProvider = Provider<ExerciseState>((ref) {
  // 0. 当用户通过下底部菜单栏切换时，强迫触发重构，以引入最新的 DateTime.now() 更新随着时间流逝的卡路里结算
  ref.watch(mainTabIndexProvider);

  // 1. 自动重调：随计步器上抛的新鲜事件无限刺激该计算发生
  final currentSteps = ref.watch(stepCountProvider).value ?? 0;

  // 2. 监听档案变更（当且仅当具有效真实身体数据时结算卡路里）
  final profile = ref.watch(userProfileProvider).value;

  // 3. 监听全局历史（由首页模块触发写表，这里能自动捕获并剥离出其携带的快照基线）
  // 注意：dashboardProvider 的数据源已被排为升序 (按 timestamp)，所以最新的记录是 .last
  final records = ref.watch(dashboardProvider).value ?? [];
  final lastRecord = records.isNotEmpty ? records.last : null;

  int activeSteps = 0;
  if (lastRecord != null) {
    if (currentSteps >= lastRecord.baselineSteps) {
      activeSteps = currentSteps - lastRecord.baselineSteps;
    } else {
      // 重启或传感器重置的情况：直接信任现存计数
      activeSteps = currentSteps;
    }
  }

  double activeCalories = 0.0;
  // 只有存在有效基础资料、且有上一次基准点时才开始累加做功
  if (profile != null && profile.isActual && lastRecord != null) {
    final diffHours =
        DateTime.now().difference(lastRecord.timestamp).inMinutes / 60.0;
    // 保底边界：避免可能微小倒退差影响
    activeCalories = CalorieCalculator.calculateTotalCalories(
      profile: profile,
      steps: activeSteps,
      durationHours: diffHours > 0 ? diffHours : 0,
    );
  }

  return ExerciseState(
    lastRecord: lastRecord,
    activeSteps: activeSteps,
    activeCalories: activeCalories,
  );
});
