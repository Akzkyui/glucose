import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/user_profile.dart';
import 'settings_provider.dart';

/// 系统设置与个人档案详情页
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // 档案输入的表单控制器
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // 性别与疾病史一旦未被回填则处于初始不确定状态
  Gender? _selectedGender;
  bool _hasDiabetes = false;

  bool _hasInitialized = false;
  // 防止表单重复提交
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final currentProfile = ref.read(userProfileProvider).value;
    if (currentProfile != null) {
      _initFormValues(currentProfile);
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  /// 提取 asyncValue 成功加载后的原始数据，赋予表单初值
  void _initFormValues(UserProfile profile) {
    if (_hasInitialized) return;

    if (profile.isActual) {
      _ageController.text = profile.age.toString();
      _heightController.text = profile.height.toString();
      _weightController.text = profile.weight.toString();
      _selectedGender = profile.gender;
      _hasDiabetes = profile.hasDiabetes;
    }
    _hasInitialized = true;
  }

  /// 点击保存时，打包当前表单发送到 Provider 触发持久化更新
  Future<void> _submitProfile() async {
    // 触发字段层的 validator 检查
    if (!_formKey.currentState!.validate()) return;

    // 性别非空判断
    if (_selectedGender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择生理性别')));
      return;
    }

    // 清除键盘焦点
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true); // 触发加载动画

    try {
      final newProfile = UserProfile(
        age: int.parse(_ageController.text),
        gender: _selectedGender!,
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        hasDiabetes: _hasDiabetes,
        isActual: true, // 一旦手工提交保存，即视为有效的正式档案
      );

      // 调用全局 Provider 更新策略
      await ref.read(userProfileProvider.notifier).updateProfile(newProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('个人档案已保存'),
            backgroundColor: AppTheme.primaryTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: AppTheme.warningRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false); // 恢复按钮状态
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 监听档案初始化加载的异步流
    final profileAsync = ref.watch(userProfileProvider);

    ref.listen<AsyncValue<UserProfile>>(userProfileProvider, (previous, next) {
      if (!_hasInitialized && next.value != null) {
        _initFormValues(next.value!);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('系统与档案管理'), centerTitle: false),
      // 处理 Loading 或 Error 的情况并包装正常的 Body
      body: profileAsync.when(
        data: (profile) => _buildMainContent(profile.isActual),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载配置失败: $error')),
      ),
    );
  }

  Widget _buildMainContent(bool isActual) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileFormCard(isActual),
            const SizedBox(height: 24),
            _buildDeviceManagerCard(),
          ],
        ),
      ),
    );
  }

  /// 构建区块 A：个人身体资料档案中心（带提交表单与校验）
  Widget _buildProfileFormCard(bool isActual) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person_outline, color: AppTheme.primaryTeal),
                SizedBox(width: 8),
                Text(
                  '基础身体档案',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 补充提示 Banner，供未形成真实数据 (isActual == false) 的新用户查看
            if (!isActual)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryAzure.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryAzure.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primaryAzure),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '请完善您的真实身体参数，这将影响卡路里消耗与健康指标引擎的计算精度。',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // 性别选项 (采用 SegmentedButton，符合 MD3 规格且直观)
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<Gender>(
                emptySelectionAllowed: true, // 允许初始无选择，促使用户主动点击
                segments: const [
                  ButtonSegment(value: Gender.male, label: Text('男性')),
                  ButtonSegment(value: Gender.female, label: Text('女性')),
                ],
                selected: _selectedGender != null
                    ? {_selectedGender!}
                    : const <Gender>{},
                onSelectionChanged: (Set<Gender> newSelection) {
                  if (newSelection.isNotEmpty) {
                    setState(() {
                      _selectedGender = newSelection.first;
                    });
                  }
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.primaryTeal.withValues(alpha: 0.15);
                    }
                    return Colors.transparent;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 年龄（限制整数边界）
            TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('年龄 (岁)'),
              validator: (val) {
                if (val == null || val.isEmpty) return '请填写年龄';
                if (int.tryParse(val) == null) return '无效数字';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 物理维度：身高/体重 并列排列
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration('身高 (cm)'),
                    validator: (val) => val!.isEmpty ? '必填' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDecoration('体重 (kg)'),
                    validator: (val) => val!.isEmpty ? '必填' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 糖尿病史 Switch (通过视觉切分划出重要等级)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '确诊糖尿病',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Switch(
                    value: _hasDiabetes,
                    activeTrackColor: AppTheme.warningRed,
                    onChanged: (val) {
                      setState(() {
                        _hasDiabetes = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 主操作按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isSaving ? '正在保存...' : '保存档案'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: AppTheme.pureWhite,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建区块 B：低功耗蓝牙接入占位区，宣导未来的核心能力
  Widget _buildDeviceManagerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bluetooth_searching,
              size: 32,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '绑定的设备',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '暂未搜索到任何设备连接，请先打开周围设备蓝牙广播并尝试再次配对。',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('设备管理模块尚未接入硬件库...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.radar),
            label: const Text('寻找智能探头'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(color: Colors.grey.shade300, width: 2),
              foregroundColor: AppTheme.textPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 共通的输入框装饰风格提取
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary),
      filled: true,
      fillColor: AppTheme.backgroundLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.warningRed, width: 1.5),
      ),
    );
  }
}
