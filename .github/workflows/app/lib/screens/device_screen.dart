import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../models/device_model.dart';

class DeviceScreen extends ConsumerStatefulWidget {
  const DeviceScreen({super.key});

  @override
  ConsumerState<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends ConsumerState<DeviceScreen> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bluetoothStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设备管理'),
        centerTitle: true,
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScan,
            ),
        ],
      ),
      body: Column(
        children: [
          // 已连接设备
          if (bleState.isConnected && bleState.connectedDevice != null)
            _buildConnectedDeviceCard(bleState.connectedDevice),
          
          // 扫描列表
          Expanded(
            child: _buildDeviceList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedDeviceCard(dynamic device) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.green.shade50,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.bluetooth_connected, color: Colors.green.shade700),
        ),
        title: Text(
          device.platformName ?? '未知设备',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('已连接'),
        trailing: OutlinedButton(
          onPressed: () async {
            await ref.read(bleServiceProvider).disconnect();
          },
          child: const Text('断开'),
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_isScanning && _scanResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '正在扫描设备...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_scanResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '点击右上角刷新按钮开始扫描',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        final device = result.device;
        
        // 过滤目标设备
        if (!device.platformName.contains('深远GT1')) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.bluetooth, color: Colors.blue.shade700),
            ),
            title: Text(
              device.platformName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('信号: ${result.rssi} dBm'),
            trailing: ElevatedButton(
              onPressed: () => _connectDevice(device),
              child: const Text('连接'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    try {
      // 检查蓝牙是否开启
      if (await FlutterBluePlus.adapterState != BluetoothAdapterState.on) {
        _showSnackBar('请先开启蓝牙');
        return;
      }

      // 开始扫描
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // 监听扫描结果
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          _scanResults = results;
        });
      });

      // 等待扫描结束
      await Future.delayed(const Duration(seconds: 10));
    } catch (e) {
      _showSnackBar('扫描失败: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    try {
      _showSnackBar('正在连接...');
      
      final success = await ref.read(bleServiceProvider).connect(device);
      
      if (success) {
        _showSnackBar('连接成功');
      } else {
        _showSnackBar('连接失败');
      }
    } catch (e) {
      _showSnackBar('连接错误: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
