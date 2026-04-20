import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/preferences_helper.dart';

/// 步数提供者：请求授权并监听设备传感器吐出的系统连续总步数，并自动运用本地基线差法转换为“今日真实日活”
final stepCountProvider = StreamProvider<int>((ref) async* {
  // 1. 发起授权请求
  final status = await Permission.activityRecognition.request();

  // 2. 只有被授权，才开启流监听
  if (status.isGranted) {
    // try-catch 包裹对设备硬件 API 发起订阅的动作
    try {
      await for (final event in Pedometer.stepCountStream) {
        final currentSteps = event.steps;
        final todayStr = DateTime.now().toIso8601String().split('T').first; // 'yyyy-MM-dd'

        int dailySteps = 0;
        final baselineData = await PreferencesHelper.getStepBaseline();

        if (baselineData == null || baselineData['date'] != todayStr) {
          // 首次启动，或检测到日期不同（跨日）：将当前硬件系统的绝对步数强行打底，今日重造为 0
          await PreferencesHelper.saveStepBaseline(todayStr, currentSteps);
          dailySteps = 0;
        } else {
          final int baseline = baselineData['value'] as int;
          if (currentSteps < baseline) {
            // 出现异常（如设备软重启计步归零）：重新记录底部并顺承计步
            await PreferencesHelper.saveStepBaseline(todayStr, 0);
            dailySteps = currentSteps;
          } else {
            // 平滑稳定状态：用底层传感器总数减去今天的底池 => 算出纯净的单日新增
            dailySteps = currentSteps - baseline;
          }
        }

        yield dailySteps;
      }
    } catch (e) {
      // 如果设备硬件不支持计步器或引发异常，静默降级为 0
      yield 0;
    }
  } else {
    // 无论是永久拒绝还是临时拒绝，对无法获取数据的场景直接降级返回 0
    yield 0;
  }
});
