import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database_helper.dart';
import '../../models/glucose_record.dart';

/// 首页数据集状态管理
/// 继承自 [AsyncNotifier]，用于处理数据库读取此类异步流程
class DashboardNotifier extends AsyncNotifier<List<GlucoseRecord>> {
  @override
  Future<List<GlucoseRecord>> build() async {
    // 初次加载数据
    return _loadRecordsFromDb();
  }

  /// 私有方法：从数据库中拉取按时间倒序排列的全部记录
  Future<List<GlucoseRecord>> _loadRecordsFromDb() async {
    return DatabaseHelper.instance.getAllRecords();
  }

  /// 加载数据库历史并由底层统一承担时间戳排序（升序：解决 UI 端重复渲染时高耗时排序问题）
  Future<void> _fetchRecords() async {
    state = const AsyncValue.loading();
    try {
      final records = await DatabaseHelper.instance.getAllRecords();
      // 在计算层一次性排好序
      records.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      state = AsyncValue.data(records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 手动刷新或重新拉取记录
  Future<void> loadRecords() async {
    //state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadRecordsFromDb);
  }

  /// 插入新血糖记录，并立刻更新状态，进而驱动 UI 刷新
  Future<void> addRecord(GlucoseRecord record) async {
    // 将新数据存入 SQLite / IndexedDB
    final id = await DatabaseHelper.instance.insertRecord(record);

    if (id != -1) {
      // 重新从库中抓取，经过排序后再次发布
      _fetchRecords();
    }
  }
}

/// 对外可见的全局仪表盘 Provider 实例
final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, List<GlucoseRecord>>(
      DashboardNotifier.new,
    );
