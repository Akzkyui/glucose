import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preferences_helper.dart';
import '../../models/user_profile.dart';

/// 全局用户档案状态管理器
/// 基于 AsyncNotifier 使其可以优雅衔接 SharedPreferences 的异步加载流程
class UserProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    // 初始化时从本地抓取缓存数据
    final profile = await PreferencesHelper.getUserProfile();
    // 如果无数据，抛出一个带有默认占位初始值的 UserProfile
    return profile ??
        UserProfile(
          age: 25,
          gender: Gender.male,
          height: 175.0,
          weight: 70.0,
          hasDiabetes: false,
          isActual: false,
        );
  }

  /// 更新用户档案：同步保存到本地磁盘并刷新内存让界面重绘
  Future<void> updateProfile(UserProfile newProfile) async {
    // 覆盖本地
    final success = await PreferencesHelper.saveUserProfile(newProfile);

    // 回写显式内存状态触发相关界面更新联动
    if (success) {
      state = AsyncData(newProfile);
    } else {
      throw Exception('本地存储写入失败，请检查设备存储空间');
    }
  }
}

/// 暴漏给视图消费的全局设置状态 Provider
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile>(
      UserProfileNotifier.new,
    );
