class BleUUID {
  // 主服务UUID
  static const String SERVICE = "12345678-1234-1234-1234-123456789abc";
  
  // 特征UUID
  static const String CHAR_LOCK = "12345678-1234-1234-1234-123456789abd";
  static const String CHAR_MODE = "12345678-1234-1234-1234-123456789abe";
  static const String CHAR_STATUS = "12345678-1234-1234-1234-123456789abf";
  static const String CHAR_SOUND = "12345678-1234-1234-1234-123456789ac0";
  static const String CHAR_SEAT = "12345678-1234-1234-1234-123456789ac1";
  static const String CHAR_BT_PAIR = "12345678-1234-1234-1234-123456789ac2";
  
  // 设备名称前缀
  static const String DEVICE_NAME_PREFIX = "深远GT1";
}

class BleCommands {
  // 锁控制
  static const int LOCK = 0x01;
  static const int UNLOCK = 0x02;
  
  // 模式切换
  static const int MODE_AUTO = 0x01;
  static const int MODE_MANUAL = 0x02;
  
  // 座桶开启
  static const int SEAT_OPEN = 0x01;
}

class BleStatus {
  // 锁状态
  static const int LOCKED = 0x01;
  static const int UNLOCKED = 0x00;
  
  // 模式状态
  static const int AUTO_MODE = 0x01;
  static const int MANUAL_MODE = 0x00;
  
  // 报警状态
  static const int ALARMING = 0x01;
  static const int NORMAL = 0x00;
  
  // 钥匙检测
  static const int KEY_ON = 0x01;
  static const int KEY_OFF = 0x00;
  
  // GPS状态
  static const int GPS_FIXED = 0x01;
  static const int GPS_NOT_FIXED = 0x00;
}

class AppConstants {
  // 最大配对设备数
  static const int MAX_PAIRED_DEVICES = 2;
  
  // 断开连接后自动上锁延迟（毫秒）
  static const int AUTO_LOCK_DELAY = 5000;
  
  // 报警持续时间（毫秒）
  static const int ALARM_DURATION = 10000;
  
  // 座桶继电器脉冲宽度（毫秒）
  static const int SEAT_PULSE_WIDTH = 100;
  
  // 震动去抖时间（毫秒）
  static const int VIBRATION_DEBOUNCE = 1000;
  
  // 蓝牙扫描超时（秒）
  static const int SCAN_TIMEOUT = 10;
  
  // 连接超时（秒）
  static const int CONNECT_TIMEOUT = 10;
}

class StorageKeys {
  static const String PAIRED_DEVICES = 'paired_devices';
  static const String LAST_CONNECTED_DEVICE = 'last_connected_device';
  static const String SETTINGS = 'app_settings';
  static const String SOUND_EFFECTS = 'sound_effects';
}
