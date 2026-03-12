import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard/dashboard_screen.dart';
import 'exercise/exercise_screen.dart';
import 'settings/settings_screen.dart';

/// 新版 Riverpod 推荐使用 Notifier 来替代 StateProvider
class MainTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

/// 增加一个全局 Provider 用于记录并分发由于导航切页意图而引发的“刷新因子”（Tick），强制刷新内部组件
class RefreshTickNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void increment() => state++;
}

final mainTabRefreshTickProvider = NotifierProvider<RefreshTickNotifier, int>(
  RefreshTickNotifier.new,
);

/// 全局 Provider 记录当前选中的 BottomNavigationBar 索引
final mainTabIndexProvider = NotifierProvider<MainTabNotifier, int>(
  MainTabNotifier.new,
);

/// 应用程序的主布局架构组件，包含底部导航栏与对应子页面
class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  // 取消 static const 固化页面实例
  List<Widget> _buildPages(int refreshTick) {
    return [
      const DashboardScreen(),
      // 巧用 ValueKey 将重构因子传入，当用户切换回此页时，Tick 会发生变化，从而击碎 IndexedStack 的保活缓存，强迫重走 build
      ExerciseScreen(key: ValueKey('exercise_$refreshTick')),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听当前激活的 Tab 索引
    final currentIndex = ref.watch(mainTabIndexProvider);
    // 监听强制刷新因子
    final refreshTick = ref.watch(mainTabRefreshTickProvider);

    return Scaffold(
      // IndexedStack 用来保持其它页面的存活状态，避免反复重建销毁导致的卡顿与状态丢失
      body: IndexedStack(
        index: currentIndex,
        children: _buildPages(refreshTick),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          // 修改全局的页面索引状态
          ref.read(mainTabIndexProvider.notifier).setIndex(index);
          // 每次切页都让 Tick 自增，为那些需要实时刷新的页面更换 Key 强制重建
          ref.read(mainTabRefreshTickProvider.notifier).increment();
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '健康概览'),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: '运动干预',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
