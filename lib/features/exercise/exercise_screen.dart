import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_theme.dart';
import '../../models/glucose_record.dart';
import '../settings/settings_provider.dart';
import 'exercise_provider.dart';
import 'recommendation_engine.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({super.key});

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  // 映射细化的测量时段为引擎需要的 4 类粗颗粒度 Tag
  String _mapTimeTagForEngine(GlucoseTimeTag tag) {
    switch (tag) {
      case GlucoseTimeTag.fasting:
      case GlucoseTimeTag.beforeLunch:
      case GlucoseTimeTag.beforeDinner:
        return 'preMeal'; // 包含 fasting 等餐前概念
      case GlucoseTimeTag.afterBreakfast2h:
      case GlucoseTimeTag.afterLunch2h:
      case GlucoseTimeTag.afterDinner2h:
        return 'postMeal'; // 统归入餐后
      case GlucoseTimeTag.beforeSleep:
        return 'bedtime'; // 睡前
    }
  }

  // 将引擎吐出的级别映射为颜色主题
  Color _mapSeverityToColor(String severity) {
    switch (severity) {
      case 'critical':
        return AppTheme.warningRed;
      case 'warning':
        return Colors.orange.shade700;
      case 'success':
        return AppTheme.primaryTeal;
      case 'info':
      default:
        return AppTheme.primaryAzure;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 采用敏捷的同步 Provider，保证切页和最新步数能毫秒级送达渲染
    final state = ref.watch(exerciseProvider);
    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('运动与干预'), centerTitle: false),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final lastRecord = state.lastRecord;
            final isToday =
                lastRecord != null &&
                DateUtils.isSameDay(DateTime.now(), lastRecord.timestamp);

            // 状态 A：跨日或无数据
            if (!isToday) {
              return _buildEmptyOrCrossDayState();
            }

            // 状态 B：今日已有数据，具备推算根基
            return _buildActiveInterventionState(state, profile);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyOrCrossDayState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_run, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 24),
            const Text(
              '今日尚未检测血糖',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '请先在首页进行一次测量，系统将基于您的血糖数据与运动数据，为您给出健康评估和运动建议。',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.5,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveInterventionState(ExerciseState state, dynamic profile) {
    final record = state.lastRecord!;
    final bool isDiabetic = profile?.hasDiabetes ?? false;

    // 唤起离线引擎获取当场推断意见
    final recommendation = RecommendationEngine.evaluate(
      bloodSugar: record.glucoseValue,
      timeTag: _mapTimeTagForEngine(record.timeTag),
      activeCalories: state.activeCalories,
      isDiabetic: isDiabetic,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 上次测量状态
          _buildLatestRecordCard(record),
          const SizedBox(height: 16),
          // 2. 测后耗能卡片
          _buildActivityCard(state),
          const SizedBox(height: 16),
          // 3. 智能建议卡片
          _buildRecommendationCard(recommendation),
        ],
      ),
    );
  }

  Widget _buildLatestRecordCard(GlucoseRecord record) {
    // 简易格式化时间 例如 08:30
    final timeStr =
        '${record.timestamp.hour.toString().padLeft(2, '0')}:${record.timestamp.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '上次测得血糖数据',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      record.glucoseValue.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 6.0, left: 4),
                      child: Text(
                        'mmol/L',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    record.timeTag.displayName,
                    style: const TextStyle(
                      color: AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(ExerciseState state) {
    return Card(
      color: AppTheme.primaryTeal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppTheme.pureWhite.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Text(
                  '测后活动代谢',
                  style: TextStyle(
                    color: AppTheme.pureWhite.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActivityItem('有效步数', '${state.activeSteps}', '步'),
                Container(
                  height: 40,
                  width: 1,
                  color: AppTheme.pureWhite.withValues(alpha: 0.2),
                ),
                _buildActivityItem(
                  '总消耗卡路里',
                  state.activeCalories.toStringAsFixed(1),
                  'kcal',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.pureWhite.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.pureWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: TextStyle(
                color: AppTheme.pureWhite.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(RecommendationResult rec) {
    final color = _mapSeverityToColor(rec.severity);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '健康评估 ${rec.title}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            rec.message,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTheme.textPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
