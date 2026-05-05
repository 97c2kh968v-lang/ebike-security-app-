# 深远GT1防盗控制器 — APP开发文档

## 技术栈

| 项目 | 选型 | 版本 | 说明 |
|------|------|------|------|
| 框架 | Flutter | 3.19+ | 跨平台，一套代码安卓+iOS |
| 蓝牙通信 | flutter_blue_plus | ^1.32.0 | BLE通信，稳定可靠 |
| 状态管理 | riverpod | ^2.4.0 | 轻量状态管理 |
| 本地存储 | shared_preferences | ^2.2.0 | 保存配对设备、设置 |
| 权限管理 | permission_handler | ^11.0.0 | 蓝牙/定位权限申请 |

## 功能模块

### 1. 蓝牙设备管理
- 扫描周围BLE设备
- 配对/解绑设备（最多2个）
- 自动重连

### 2. 锁控制
- 自动模式：蓝牙连上自动解锁，断开自动上锁
- 手动模式：APP按钮控制开关锁
- 显示当前锁状态

### 3. 震动报警
- 显示报警状态
- 报警灵敏度设置（预留）
- 报警记录查询

### 4. 音效管理
- 预设音效列表（警笛、喇叭、自定义...）
- 上传自定义音效（MP3/WAV）
- 选择当前音效

### 5. 座桶控制
- APP一键开启座桶

### 6. 4G/GPS预留
- 车辆定位（地图显示）
- 电子围栏（预留）

## 项目结构

```
ebike_app/
├── lib/
│   ├── main.dart                 # 入口
│   ├── models/                  # 数据模型
│   │   ├── device_model.dart
│   │   └── settings_model.dart
│   ├── providers/               # 状态管理
│   │   ├── bluetooth_provider.dart
│   │   ├── device_provider.dart
│   │   └── settings_provider.dart
│   ├── services/               # 服务层
│   │   ├── ble_service.dart     # 蓝牙通信服务
│   │   └── storage_service.dart # 本地存储
│   ├── screens/                 # 页面
│   │   ├── home_screen.dart     # 主页
│   │   ├── device_screen.dart   # 设备管理
│   │   ├── settings_screen.dart # 设置页
│   │   └── sound_screen.dart   # 音效管理
│   ├── widgets/                 # 组件
│   │   ├── lock_button.dart
│   │   ├── status_card.dart
│   │   └── device_list_tile.dart
│   └── utils/                   # 工具
│       ├── constants.dart        # UUID常量
│       └── converters.dart
├── assets/
│   └── sounds/                 # 预设音效文件
└── pubspec.yaml
```

## UUID定义（需与ESP32固件一致）

```dart
// lib/utils/constants.dart
class BleUUID {
  static const String SERVICE = "12345678-1234-1234-1234-123456789abc";
  static const String CHAR_LOCK = "12345678-1234-1234-1234-123456789abd";
  static const String CHAR_MODE = "12345678-1234-1234-1234-123456789abe";
  static const String CHAR_STATUS = "12345678-1234-1234-1234-123456789abf";
  static const String CHAR_SOUND = "12345678-1234-1234-1234-123456789ac0";
  static const String CHAR_SEAT = "12345678-1234-1234-1234-123456789ac1";
  static const String CHAR_BT_PAIR = "12345678-1234-1234-1234-123456789ac2";
}
```

## 通信协议

### 写指令（APP → ESP32）

| 特征 | 命令 | 数据 | 说明 |
|------|------|------|------|
| LOCK | 0x01 | 1字节 | 上锁 |
| LOCK | 0x02 | 1字节 | 解锁 |
| MODE | 0x01 | 1字节 | 切换到自动模式 |
| MODE | 0x02 | 1字节 | 切换到手动模式 |
| SOUND | 0x00-0x04 | 1字节 | 选择音效0-4 |
| SEAT | 0x01 | 1字节 | 开启座桶 |

### 通知数据（ESP32 → APP）

8字节状态包：
```
[0]: 锁状态 (0x00=解锁, 0x01=上锁)
[1]: 工作模式 (0x00=手动, 0x01=自动)
[2]: 蓝牙连接数 (0x00-0x02)
[3]: 报警状态 (0x00=正常, 0x01=报警中)
[4]: 当前音效编号 (0x00-0x04)
[5]: 钥匙检测 (0x00=OFF, 0x01=ON)
[6]: 4G信号强度 (0x00-0x64, 预留)
[7]: GPS定位状态 (0x00=未定位, 0x01=已定位, 预留)
```
