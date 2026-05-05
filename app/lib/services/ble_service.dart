import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import '../utils/constants.dart';
import '../models/device_model.dart';
import '../models/settings_model.dart';

// BLE服务Provider
final bleServiceProvider = Provider<BleService>((ref) {
  return BleService(ref);
});

// 蓝牙状态Provider
final bluetoothStateProvider = StateNotifierProvider<BleStateNotifier, BleState>((ref) {
  return BleStateNotifier(ref.watch(bleServiceProvider));
});

// 已连接设备Provider
final connectedDeviceProvider = StateProvider<DeviceModel?>((ref) => null);

// 设备状态Provider
final deviceStatusProvider = StateProvider<DeviceStatus>((ref) => DeviceStatus());

class BleService {
  final ProviderRef _ref;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _lockChar;
  BluetoothCharacteristic? _modeChar;
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _soundChar;
  BluetoothCharacteristic? _seatChar;

  BleService(this._ref);

  Future<void> initialize() async {
    // 监听蓝牙适配器状态
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        // 蓝牙已开启，尝试自动连接
        autoConnect();
      }
    });

    // 监听扫描结果
    FlutterBluePlus.scanResults.listen((results) {
      // 处理扫描到的设备
      for (var result in results) {
        if (result.device.platformName.contains('深远GT1')) {
          // 发现目标设备
          _ref.read(bluetoothStateProvider.notifier).foundDevice(result.device);
        }
      }
    });

    // 监听连接状态
    FlutterBluePlus.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _ref.read(bluetoothStateProvider.notifier).disconnected();
      }
    });
  }

  Future<void> startScan({int duration = 10}) async {
    if (await FlutterBluePlus.adapterState == BluetoothAdapterState.on) {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: duration));
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;
      await _discoverServices();
      _ref.read(bluetoothStateProvider.notifier).connected(device);
      return true;
    } catch (e) {
      print('连接失败: $e');
      return false;
    }
  }

  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;

    var services = await _connectedDevice!.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == BleUUID.SERVICE) {
        for (var char in service.characteristics) {
          switch (char.uuid.toString().toLowerCase()) {
            case BleUUID.CHAR_LOCK:
              _lockChar = char;
              break;
            case BleUUID.CHAR_MODE:
              _modeChar = char;
              break;
            case BleUUID.CHAR_STATUS:
              _statusChar = char;
              await char.setNotifyValue(true);
              char.onValueReceived.listen(_handleStatusNotification);
              break;
            case BleUUID.CHAR_SOUND:
              _soundChar = char;
              break;
            case BleUUID.CHAR_SEAT:
              _seatChar = char;
              break;
          }
        }
      }
    }
  }

  void _handleStatusNotification(List<int> value) {
    if (value.length >= 6) {
      var status = DeviceStatus(
        isLocked: value[0] == 0x01,
        isAutoMode: value[1] == 0x01,
        btConnectedCount: value[2],
        isAlarming: value[3] == 0x01,
        currentSoundEffect: value[4],
        keyDetected: value[5] == 0x01,
      );
      _ref.read(deviceStatusProvider.notifier).state = status;
    }
  }

  Future<void> autoConnect() async {
    // 从本地存储读取已配对设备，尝试自动连接
    // 实现自动重连逻辑
  }

  // 发送锁控制命令
  Future<void> setLock(bool locked) async {
    if (_lockChar != null) {
      await _lockChar!.write([locked ? 0x01 : 0x02]);
    }
  }

  // 发送模式切换命令
  Future<void> setMode(bool autoMode) async {
    if (_modeChar != null) {
      await _modeChar!.write([autoMode ? 0x01 : 0x02]);
    }
  }

  // 发送音效选择命令
  Future<void> setSoundEffect(int effectIndex) async {
    if (_soundChar != null) {
      await _soundChar!.write([effectIndex]);
    }
  }

  // 发送座桶开启命令
  Future<void> openSeatBox() async {
    if (_seatChar != null) {
      await _seatChar!.write([0x01]);
    }
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _lockChar = null;
    _modeChar = null;
    _statusChar = null;
    _soundChar = null;
    _seatChar = null;
  }
}

class BleStateNotifier extends StateNotifier<BleState> {
  final BleService _service;

  BleStateNotifier(this._service) : super(BleState.initial());

  void foundDevice(BluetoothDevice device) {
    state = state.copyWith(
      scanning: false,
      foundDevice: device,
    );
  }

  Future<void> connected(BluetoothDevice device) async {
    state = state.copyWith(
      isConnected: true,
      connectedDevice: device,
      scanning: false,
      error: null,
    );
  }

  void disconnected() {
    state = state.copyWith(
      isConnected: false,
      connectedDevice: null,
    );
  }

  void setScanning(bool scanning) {
    state = state.copyWith(scanning: scanning);
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }
}
