import 'package:flutter/material.dart';

class AppSettings {
  final bool autoConnect;
  final bool notifications;
  final int alarmDuration; // 报警持续时间（秒）
  final int disconnectDelay; // 断开后延迟上锁时间（秒）
  final int soundEffectIndex; // 当前选中的音效
  final List<String> pairedDevicesMac; // 已配对设备MAC地址列表

  AppSettings({
    this.autoConnect = true,
    this.notifications = true,
    this.alarmDuration = 10,
    this.disconnectDelay = 5,
    this.soundEffectIndex = 0,
    this.pairedDevicesMac = const [],
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      autoConnect: json['autoConnect'] ?? true,
      notifications: json['notifications'] ?? true,
      alarmDuration: json['alarmDuration'] ?? 10,
      disconnectDelay: json['disconnectDelay'] ?? 5,
      soundEffectIndex: json['soundEffectIndex'] ?? 0,
      pairedDevicesMac: List<String>.from(json['pairedDevicesMac'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoConnect': autoConnect,
      'notifications': notifications,
      'alarmDuration': alarmDuration,
      'disconnectDelay': disconnectDelay,
      'soundEffectIndex': soundEffectIndex,
      'pairedDevicesMac': pairedDevicesMac,
    };
  }

  AppSettings copyWith({
    bool? autoConnect,
    bool? notifications,
    int? alarmDuration,
    int? disconnectDelay,
    int? soundEffectIndex,
    List<String>? pairedDevicesMac,
  }) {
    return AppSettings(
      autoConnect: autoConnect ?? this.autoConnect,
      notifications: notifications ?? this.notifications,
      alarmDuration: alarmDuration ?? this.alarmDuration,
      disconnectDelay: disconnectDelay ?? this.disconnectDelay,
      soundEffectIndex: soundEffectIndex ?? this.soundEffectIndex,
      pairedDevicesMac: pairedDevicesMac ?? this.pairedDevicesMac,
    );
  }
}

class SoundEffect {
  final int index;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const SoundEffect({
    required this.index,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const List<SoundEffect> presets = [
    SoundEffect(
      index: 0,
      name: '静音',
      description: '不播放任何声音',
      icon: Icons.volume_off,
      color: Colors.grey,
    ),
    SoundEffect(
      index: 1,
      name: '滴滴声',
      description: '简单的滴滴提示音',
      icon: Icons.notifications,
      color: Color(0xFF5361AB),
    ),
    SoundEffect(
      index: 2,
      name: '警笛声',
      description: '响亮的警报声',
      icon: Icons.warning,
      color: Colors.red,
    ),
    SoundEffect(
      index: 3,
      name: '摩托车声',
      description: '模拟摩托车引擎声',
      icon: Icons.two_wheeler,
      color: Colors.orange,
    ),
    SoundEffect(
      index: 4,
      name: '自定义',
      description: '上传自定义音效文件',
      icon: Icons.upload_file,
      color: Colors.green,
    ),
  ];
}
