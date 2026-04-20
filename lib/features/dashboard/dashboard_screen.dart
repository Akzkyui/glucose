import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../core/app_theme.dart';
import '../../models/glucose_record.dart';
import 'dashboard_provider.dart';
import '../exercise/step_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // 底部弹窗调用
  void _showAddRecordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddRecordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsyncValue = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('健康概览')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBluetoothCard(),
              const SizedBox(height: 16),
              _buildChartCard(recordsAsyncValue),
              const SizedBox(height: 16),
              // 将计步卡片提取为独立 ConsumerWidget，隔离高频重绘区域
              const _StepsCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRecordDialog,
        icon: const Icon(Icons.add),
        label: const Text('记录数据'),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: AppTheme.pureWhite,
        elevation: 4,
      ),
    );
  }

  /// 蓝牙连接状态卡片
  Widget _buildBluetoothCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bluetooth_disabled,
                color: AppTheme.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '设备连接状态',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '蓝牙未连接',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // 电量占位图标
            const Icon(Icons.battery_unknown, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  /// 血糖波动趋势图卡片
  Widget _buildChartCard(AsyncValue<List<GlucoseRecord>> recordsAsync) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '近期血糖波动',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: recordsAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return _buildEmptyChart();
                  }
                  return _buildLineChart(records);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('加载失败: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 图表无数据时的空视图提示
  Widget _buildEmptyChart() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: AppTheme.textSecondary),
          SizedBox(height: 16),
          Text(
            '暂无血糖数据\n请点击右下角录入',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// 依据记录数据绘制优雅的带平滑渐变的折线图
  Widget _buildLineChart(List<GlucoseRecord> records) {
    // 【修复 2】直接享用 Provider 给的排序结果，这里只负责渲染不再进行 CPU 耗时的 .sort()
    final sortedRecords = records;

    final List<FlSpot> spots = [];
    double maxDataValue = 0;

    for (int i = 0; i < sortedRecords.length; i++) {
      final value = sortedRecords[i].glucoseValue;
      spots.add(FlSpot(i.toDouble(), value));
      if (value > maxDataValue) maxDataValue = value;
    }

    // 动态提取数据的真实峰值，并强制给顶部预留出 2 mmol/L 的极度宽裕空间，避免裁切提示框
    final double maxY = maxDataValue < 8 ? 10.0 : maxDataValue + 2.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = constraints.maxWidth;
        // 每条数据分配约 60 逻辑像素宽度，加上为左侧 Y 轴预留固定的 40 宽度
        final chartDataWidth = sortedRecords.length * 60.0 + 40.0;
        final actualWidth = chartDataWidth > minWidth ? chartDataWidth : minWidth;

        return Stack(
          children: [
            // 1. 底层支持水平方向滚动的折线图（隐藏左侧 Y 轴数字，避免与顶层固定轴冲突）
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: actualWidth,
                // left: 40 预留给固定的 Y 轴覆盖使用
                padding: const EdgeInsets.only(top: 16, right: 16, left: 40),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 5,
                      getDrawingHorizontalLine: (value) {
                        return const FlLine(
                          color: AppTheme.backgroundLight,
                          strokeWidth: 1.5,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      // 关键点：底层滚动图表关闭左侧纵轴数字，避免被看见和重叠
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: (sortedRecords.length / 6).ceilToDouble().clamp(
                            1.0,
                            double.infinity,
                          ),
                          getTitlesWidget: (value, meta) {
                            final int index = value.toInt();
                            // 确保在数据点范围内，且对横坐标轴上的文字不至于太密集
                            if (index >= 0 && index < sortedRecords.length) {
                              final record = sortedRecords[index];
                              // 格式化：14:30 的显示格式
                              final timeLabel =
                                  '${record.timestamp.hour}:${record.timestamp.minute.toString().padLeft(2, '0')}';
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  timeLabel,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    maxY: maxY,
                    minY: 0,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true, // 开启平滑折线
                        color: AppTheme.primaryTeal,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true), // 展现每个数据的结点
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryTeal.withValues(alpha: 0.3),
                              AppTheme.primaryTeal.withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // 2. 覆盖在上层的固定 Y 轴容器
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 40, // reservedSize=32，剩余8px做边距距离
              child: Container(
                // 铺纯白底色，有效遮挡下方滑动进去的图表折线和横网格线
                color: AppTheme.pureWhite,
                padding: const EdgeInsets.only(top: 16),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    maxY: maxY,
                    minY: 0,
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      // 保持底部占位以确保主图网格对齐
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) => const SizedBox(),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 5,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.right,
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      // 用透明数据点撑起框架高度，但不绘制出任何可见线条
                      LineChartBarData(
                        spots: const [FlSpot(0, 0), FlSpot(1, 0)],
                        color: Colors.transparent,
                        barWidth: 0,
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} // 此处才是真正的 _DashboardScreenState 的结束

/// 目标步数环形进度独立卡片：防止它随心跳般高频刷新时连带整个主页图表崩溃重绘
class _StepsCard extends ConsumerWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 【修复 1】只有这个独立小组件会响应步数的狂魔变化
    final stepAsync = ref.watch(stepCountProvider);
    final int steps = stepAsync.value ?? 0;
    final double percent = (steps / 10000).clamp(0.0, 1.0);

    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            const Text(
              '今日步数进度',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            CircularPercentIndicator(
              radius: 70.0,
              lineWidth: 14.0,
              animation: true,
              percent: percent, // 真实数据填充
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$steps",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24.0,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  const Text(
                    "/ 10000 步",
                    style: TextStyle(
                      fontSize: 12.0,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: AppTheme.primaryTeal,
              backgroundColor: AppTheme.backgroundLight,
            ),
          ],
        ),
      ),
    );
  }
}

/// MVP模拟记录添加的底窗弹出版面
class _AddRecordSheet extends ConsumerStatefulWidget {
  const _AddRecordSheet();

  @override
  ConsumerState<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends ConsumerState<_AddRecordSheet> {
  final TextEditingController _valueController = TextEditingController();
  GlucoseTimeTag _selectedTag = GlucoseTimeTag.fasting;
  bool _isSaving = false;

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _saveData() async {
    final valueText = _valueController.text.trim();
    if (valueText.isEmpty) return;

    final doubleValue = double.tryParse(valueText);
    if (doubleValue == null) return;

    setState(() => _isSaving = true);

    int currentSteps = 0;
    try {
      // 临时唤起计步 Future，如果是第一次或能快速拿到都会通过该接口取得当前总步数 (抛错默认记0)
      currentSteps = await ref.read(stepCountProvider.future);
    } catch (_) {}

    try {
      final record = GlucoseRecord(
        timestamp: DateTime.now(),
        glucoseValue: doubleValue,
        timeTag: _selectedTag,
        baselineSteps: currentSteps,
      );

      // 调用 Provider 通过单例插入数据库并重新刷新视图状态
      await ref.read(dashboardProvider.notifier).addRecord(record);

      if (mounted) {
        Navigator.of(context).pop(); // 关闭弹窗表单
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
    // 【修复 3】去除了无用的 finally setState。因为弹窗被 pop 后会被直接销毁 (Unmounted)
  }

  @override
  Widget build(BuildContext context) {
    // 监听键盘的抬升，防止遮挡表单输入框
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '模拟添加单次记录',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _valueController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '本次测量血糖值 (mmol/L)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.primaryTeal,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<GlucoseTimeTag>(
            initialValue: _selectedTag,
            decoration: InputDecoration(
              labelText: '请选择检测时段',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: GlucoseTimeTag.values.map((tag) {
              return DropdownMenuItem(value: tag, child: Text(tag.displayName));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedTag = val;
                });
              }
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveData,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('保 存'),
          ),
        ],
      ),
    );
  }
}
