class DeviceModel {
  final String id;
  final String name;
  final String macAddress;
  final bool isConnected;
  final DateTime? lastConnected;

  DeviceModel({
    required this.id,
    required this.name,
    required this.macAddress,
    this.isConnected = false,
    this.lastConnected,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      macAddress: json['macAddress'] ?? '',
      isConnected: json['isConnected'] ?? false,
      lastConnected: json['lastConnected'] != null 
          ? DateTime.parse(json['lastConnected']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'macAddress': macAddress,
      'isConnected': isConnected,
      'lastConnected': lastConnected?.toIso8601String(),
    };
  }

  DeviceModel copyWith({
    String? id,
    String? name,
    String? macAddress,
    bool? isConnected,
    DateTime? lastConnected,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      isConnected: isConnected ?? this.isConnected,
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }
}

class DeviceStatus {
  final bool isLocked;
  final bool isAutoMode;
  final int btConnectedCount;
  final bool isAlarming;
  final int currentSoundEffect;
  final bool keyDetected;
  final int signalStrength; // 4G信号强度
  final bool gpsFixed; // GPS是否已定位

  DeviceStatus({
    this.isLocked = true,
    this.isAutoMode = true,
    this.btConnectedCount = 0,
    this.isAlarming = false,
    this.currentSoundEffect = 0,
    this.keyDetected = false,
    this.signalStrength = 0,
    this.gpsFixed = false,
  });

  factory DeviceStatus.fromBytes(List<int> bytes) {
    if (bytes.length < 8) return DeviceStatus();
    return DeviceStatus(
      isLocked: bytes[0] == 0x01,
      isAutoMode: bytes[1] == 0x01,
      btConnectedCount: bytes[2],
      isAlarming: bytes[3] == 0x01,
      currentSoundEffect: bytes[4],
      keyDetected: bytes[5] == 0x01,
      signalStrength: bytes[6],
      gpsFixed: bytes[7] == 0x01,
    );
  }

  DeviceStatus copyWith({
    bool? isLocked,
    bool? isAutoMode,
    int? btConnectedCount,
    bool? isAlarming,
    int? currentSoundEffect,
    bool? keyDetected,
    int? signalStrength,
    bool? gpsFixed,
  }) {
    return DeviceStatus(
      isLocked: isLocked ?? this.isLocked,
      isAutoMode: isAutoMode ?? this.isAutoMode,
      btConnectedCount: btConnectedCount ?? this.btConnectedCount,
      isAlarming: isAlarming ?? this.isAlarming,
      currentSoundEffect: currentSoundEffect ?? this.currentSoundEffect,
      keyDetected: keyDetected ?? this.keyDetected,
      signalStrength: signalStrength ?? this.signalStrength,
      gpsFixed: gpsFixed ?? this.gpsFixed,
    );
  }

  String get statusText {
    if (isAlarming) return '报警中!';
    if (isLocked) return '已上锁';
    return '已解锁';
  }

  String get modeText {
    return isAutoMode ? '自动模式' : '手动模式';
  }
}
