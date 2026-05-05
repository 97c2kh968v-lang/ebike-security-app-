# 深远GT1防盗控制器APP - 构建指南

## 方案一：GitHub Actions 云端构建（推荐，免安装）

### 步骤
1. 在GitHub新建私有仓库（如 `ebike-security-app`）
2. 将 `ebike_security/app/` 目录推送到仓库
3. GitHub Actions 自动运行，约5-8分钟完成构建
4. 进入仓库 **Actions** 标签页 → 最新构建 → **Artifacts** → 下载 `ebike-security-app-release-apk`

### 推送命令
```bash
cd ebike_security/app
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/你的用户名/ebike-security-app.git
git push -u origin main
```

### 注意
- GitHub Actions 免费额度：2000分钟/月（足够用）
- 构建工作流文件已生成：`.github/workflows/build-android-apk.yml`
- 需将整个项目目录（含 `.github/` ）推送到仓库根目录

---

## 方案二：本地构建（需要安装Flutter）

### Android APK 本地构建

#### Windows
```bash
# 1. 安装Flutter SDK
# 下载：https://flutter.dev/docs/get-started/install/windows
# 解压到 C:\flutter，并添加 C:\flutter\bin 到系统PATH

# 2. 验证安装
flutter doctor

# 3. 进入项目目录
cd ebike_security\app

# 4. 获取依赖
flutter pub get

# 5. 构建Release APK
flutter build apk --release

# 输出路径：app\build\app\outputs\flutter-apk\app-release.apk
```

#### macOS / Linux
```bash
# 1. 安装Flutter
git clone https://github.com/flutter/flutter.git -b stable ~/flutter
export PATH="$PATH:$HOME/flutter/bin"

# 2. 验证
flutter doctor

# 3. 构建
cd ebike_security/app
flutter pub get && flutter build apk --release
```

#### APK安装到手机
1. 将 `app-release.apk` 传到安卓手机
2. 手机设置 → 安全 → 允许安装未知来源应用
3. 点击APK文件安装

---

### iOS IPA 本地构建（需要Mac）

#### 环境要求
- macOS 系统
- Xcode 15+（App Store下载）
- Apple开发者账号（免费即可，测试用）
- Flutter SDK

#### 构建步骤
```bash
# 1. 进入项目目录
cd ebike_security/app

# 2. 获取依赖
flutter pub get

# 3. 生成iOS项目文件
flutter create --platforms=ios .

# 4. 打开Xcode项目
open ios/Runner.xcworkspace

# 5. 在Xcode中配置：
#    - Signing & Capabilities → Team（选择你的开发者账号）
#    - Bundle Identifier（改为唯一ID，如 com.yourname.ebike-security）
#    - Deployment Target → iOS 13.0+

# 6. 连接iPhone，点击Xcode "运行"按钮安装
#    或归档（Archive）→ 导出IPA文件

# 命令行构建（无签名，需手动签名）
flutter build ios --release --no-codesign
# 输出：app/build/ios/iphoneos/Runner.app
```

#### 真机调试（推荐）
1. iPhone连接Mac，信任电脑
2. Xcode → Window → Devices and Simulators → 选择设备
3. 点击"运行"，自动安装到iPhone

#### IPA分发
- **Ad Hoc**（限100台设备）：需添加设备UDID到开发者账号
- **TestFlight**：上架TestFlight，无需审查，限10000测试员
- **企业签名**：需$299/年企业账号

---

## 故障排除

### Flutter doctor 报错
```bash
# Android许可未接受
flutter doctor --android-licenses

# Android SDK未找到
# 安装Android Studio，然后在设置中安装Android SDK
```

### iOS构建报错
```bash
# CocoaPods未安装
sudo gem install cocoapods
cd ios && pod install

# 蓝牙权限报错
# 检查 ios/Runner/Info.plist 是否包含 NSBluetoothAlwaysUsageDescription
```

### APK安装失败
- 确保手机允许"未知来源"安装
- APK架构不匹配：重新构建 `flutter build apk --release --split-per-abi`

---

## 文件清单

| 文件 | 说明 |
|------|------|
| `build-apk-批处理.bat` | Windows一键构建脚本 |
| `.github/workflows/build-android-apk.yml` | GitHub Actions云端构建配置 |
| `app/ios/Runner/Info.plist` | iOS权限配置文件（已配置蓝牙权限） |
| `app/ios/Podfile` | iOS依赖配置（已配置） |
| `app/pubspec.yaml` | Flutter项目依赖定义 |
| `schematics/ebike_security_schematic.svg` | 原理图（SVG矢量图） |
| `schematics/BOM嘉立创.csv` | 嘉立创BOM清单（含LCSC编号） |
| `嘉立创下单操作指引.md` | 嘉立创下单完整指引 |

---

## 快速验证

安装APP后，确保ESP32固件已烧录并运行：
1. 打开APP，点击"扫描设备"
2. 找到 "EBIKE_SECURITY" 设备，点击连接
3. 进入主页，查看连接状态
4. 测试门锁、座桶、音效功能

如无法连接：
- 确认ESP32已通电，蓝灯闪烁（等待连接状态）
- 手机蓝牙已开启
- APP已授予蓝牙权限（系统设置中检查）
