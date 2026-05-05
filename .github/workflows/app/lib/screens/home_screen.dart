import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ble_service.dart';
import '../models/device_model.dart';
import '../utils/constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bluetoothStateProvider);
    final deviceStatus = ref.watch(deviceStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('深远GT1防盗器'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              bleState.isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: bleState.isConnected ? Colors.blue : Colors.grey,
            ),
            onPressed: () {
              // 跳转到设备页面
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 状态卡片
              _buildStatusCard(context, bleState, deviceStatus, ref),
              const SizedBox(height: 20),
              
              // 锁控制按钮
              _buildLockButton(context, bleState, deviceStatus, ref),
              const SizedBox(height: 20),
              
              // 快捷操作区
              _buildQuickActions(context, bleState, ref),
              const Spacer(),
              
              // 底部状态栏
              _buildBottomStatusBar(context, bleState, deviceStatus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, BleState bleState, DeviceStatus status, WidgetRef ref) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!bleState.isConnected) {
      statusColor = Colors.grey;
      statusText = '设备未连接';
      statusIcon = Icons.bluetooth_disabled;
    } else if (status.isAlarming) {
      statusColor = Colors.red;
      statusText = '报警中!';
      statusIcon = Icons.warning;
    } else if (status.isLocked) {
      statusColor = Colors.green;
      statusText = '车辆已上锁';
      statusIcon = Icons.lock;
    } else {
      statusColor = Colors.orange;
      statusText = '车辆已解锁';
      statusIcon = Icons.lock_open;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // 状态图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusIcon,
                size: 40,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // 状态文字
            Text(
              statusText,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            
            // 模式显示
            Text(
              bleState.isConnected ? status.modeText : '等待连接...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // 状态详情
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusItem(
                  icon: Icons.bluetooth,
                  label: '蓝牙',
                  value: '${status.btConnectedCount}/2',
                  isActive: bleState.isConnected,
                ),
                _buildStatusItem(
                  icon: Icons.vibration,
                  label: '报警',
                  value: status.isAlarming ? '触发' : '正常',
                  isActive: status.isAlarming,
                ),
                _buildStatusItem(
                  icon: Icons.key,
                  label: '钥匙',
                  value: status.keyDetected ? 'ON' : 'OFF',
                  isActive: status.keyDetected,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isActive,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isActive ? Colors.green : Colors.grey,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLockButton(BuildContext context, BleState bleState, DeviceStatus status, WidgetRef ref) {
    final bleService = ref.read(bleServiceProvider);
    final bool isLocked = status.isLocked;
    
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton(
        onPressed: bleState.isConnected
            ? () async {
                if (isLocked) {
                  await bleService.setLock(false);
                } else {
                  await bleService.setLock(true);
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLocked ? Colors.green : Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLocked ? Icons.lock : Icons.lock_open,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              isLocked ? '点击解锁' : '点击上锁',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, BleState bleState, WidgetRef ref) {
    final bleService = ref.read(bleServiceProvider);
    final deviceStatus = ref.watch(deviceStatusProvider);

    return Row(
      children: [
        // 模式切换
        Expanded(
          child: _buildActionCard(
            context: context,
            icon: Icons.auto_mode,
            label: deviceStatus.isAutoMode ? '自动模式' : '手动模式',
            subtitle: '点击切换',
            color: deviceStatus.isAutoMode ? Colors.blue : Colors.grey,
            onTap: bleState.isConnected
                ? () async {
                    await bleService.setMode(!deviceStatus.isAutoMode);
                  }
                : null,
          ),
        ),
        const SizedBox(width: 12),
        
        // 座桶开启
        Expanded(
          child: _buildActionCard(
            context: context,
            icon: Icons.inventory_2,
            label: '座桶',
            subtitle: '一键开启',
            color: Colors.purple,
            onTap: bleState.isConnected
                ? () async {
                    await bleService.openSeatBox();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('座桶已开启'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomStatusBar(BuildContext context, BleState bleState, DeviceStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                bleState.isConnected ? Icons.cloud_done : Icons.cloud_off,
                size: 16,
                color: bleState.isConnected ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                bleState.isConnected ? '设备在线' : '设备离线',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          Text(
            'v1.0.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// BLE状态类
class BleState {
  final bool isConnected;
  final bool scanning;
  final dynamic connectedDevice;
  final dynamic foundDevice;
  final String? error;

  BleState({
    this.isConnected = false,
    this.scanning = false,
    this.connectedDevice,
    this.foundDevice,
    this.error,
  });

  factory BleState.initial() => BleState();

  BleState copyWith({
    bool? isConnected,
    bool? scanning,
    dynamic connectedDevice,
    dynamic foundDevice,
    String? error,
  }) {
    return BleState(
      isConnected: isConnected ?? this.isConnected,
      scanning: scanning ?? this.scanning,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      foundDevice: foundDevice ?? this.foundDevice,
      error: error,
    );
  }
}
