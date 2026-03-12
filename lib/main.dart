import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'features/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 我们使用 Riverpod，必须在应用的最外层用 ProviderScope 包裹
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '智能血糖管理',
      // 使用前置定义好的现代健康主题样式
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // 挂载主路由页面 (Dashboard, Exercise, Settings 的容器)
      home: const MainLayout(),
    );
  }
}
