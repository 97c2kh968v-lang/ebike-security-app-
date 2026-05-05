import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ble_service.dart';
import '../models/settings_model.dart';

// 设置Provider
final settingsProvider = StateProvider<AppSettings>((ref) => AppSettings());

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 自动连接设置
          _buildSectionHeader('连接设置'),
          _buildSwitchTile(
            title: '自动连接',
            subtitle: '启动时自动连接上次设备',
            value: settings.autoConnect,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).state = 
                  settings.copyWith(autoConnect: value);
            },
          ),
          
          const Divider(height: 32),
          
          // 报警设置
          _buildSectionHeader('报警设置'),
          _buildSliderTile(
            title: '报警持续时间',
            subtitle: '${settings.alarmDuration} 秒',
            value: settings.alarmDuration.toDouble(),
            min: 5,
            max: 30,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).state = 
                  settings.copyWith(alarmDuration: value.toInt());
            },
          ),
          _buildSliderTile(
            title: '断开自动上锁延迟',
            subtitle: '${settings.disconnectDelay} 秒',
            value: settings.disconnectDelay.toDouble(),
            min: 3,
            max: 30,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).state = 
                  settings.copyWith(disconnectDelay: value.toInt());
            },
          ),
          
          const Divider(height: 32),
          
          // 通知设置
          _buildSectionHeader('通知设置'),
          _buildSwitchTile(
            title: '推送通知',
            subtitle: '接收报警和状态变更通知',
            value: settings.notifications,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).state = 
                  settings.copyWith(notifications: value);
            },
          ),
          
          const Divider(height: 32),
          
          // 4G/GPS预留功能
          _buildSectionHeader('4G/GPS功能（预留）'),
          _buildInfoTile(
            title: '车辆定位',
            subtitle: '通过GPS实时查看车辆位置',
            trailing: const Chip(
              label: Text('敬请期待', style: TextStyle(fontSize: 12)),
              backgroundColor: Colors.grey,
            ),
          ),
          _buildInfoTile(
            title: '电子围栏',
            subtitle: '设置车辆活动范围，越界提醒',
            trailing: const Chip(
              label: Text('敬请期待', style: TextStyle(fontSize: 12)),
              backgroundColor: Colors.grey,
            ),
          ),
          _buildInfoTile(
            title: '历史轨迹',
            subtitle: '查看车辆行驶轨迹记录',
            trailing: const Chip(
              label: Text('敬请期待', style: TextStyle(fontSize: 12)),
              backgroundColor: Colors.grey,
            ),
          ),
          
          const Divider(height: 32),
          
          // 关于
          _buildSectionHeader('关于'),
          _buildInfoTile(
            title: 'APP版本',
            subtitle: 'v1.0.0',
          ),
          _buildInfoTile(
            title: '固件版本',
            subtitle: 'v1.0.0',
          ),
          _buildInfoTile(
            title: '技术支持',
            subtitle: '小码 WorkBuddy',
          ),
          
          const SizedBox(height: 24),
          
          // 清除配对数据按钮
          OutlinedButton.icon(
            onPressed: () {
              _showClearDataDialog(context, ref);
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text(
              '清除配对数据',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除配对数据'),
        content: const Text(
          '确定要清除所有配对设备数据吗？清除后需要重新配对设备。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: 实现清除配对数据
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('配对数据已清除')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定清除'),
          ),
        ],
      ),
    );
  }
}
