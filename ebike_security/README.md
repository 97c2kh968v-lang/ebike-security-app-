# 深远GT1电动车防盗控制器 - 终极交付说明

> 生成日期：2026-05-05 | 设计者：小码 for 大哥良

---

## 一、APP安装包

### 安卓APK（三选一）

#### 方案A：GitHub Actions云端构建（推荐，5分钟搞定）

**不需要安装任何软件，全程浏览器操作：**

1. 打开 https://github.com ，登录（免费注册）
2. 点击右上角 **"+"** → **"New repository"**
3. 仓库名：`ebike-security-app`（私有）
4. 创建后，进入仓库 → **"Add file"** → **"Upload files"**
5. 把 `ebike_security/app/` 整个文件夹拖入上传区
6. 同时上传 `ebike_security/.github/` 文件夹
7. 点击 **"Commit changes"**
8. 进入仓库 → **Actions** 标签 → 看到自动运行的workflow
9. 等3-5分钟，workflow完成后 → 点击构建任务 → **Artifacts** → 下载 `ebike-security-app-release-apk`
10. 把APK传到手机，安装

> GitHub免费额度：每月2000分钟构建时间，绰绰有余。

#### 方案B：本地Flutter构建

1. 安装Flutter SDK：
   - 下载：https://flutter.dev （需要梯子）
   - 国内镜像：https://flutter.cn
   - 解压到 `C:\flutter`，添加 `C:\flutter\bin` 到系统PATH

2. 构建APK：
   ```
   cd ebike_security\app
   flutter pub get
   flutter build apk --release
   ```
   输出：`app\build\app\outputs\flutter-apk\app-release.apk`

3. 安装到手机：APK传到手机 → 设置允许安装未知应用 → 安装

#### 方案C：直接用双击脚本（最简单的方案）

运行 `build_apk_批处理.bat`，按提示操作。

---

### iOS APP（需要Mac电脑）

**iOS无法在Windows上构建，必须用Mac：**

1. 在Mac上安装Flutter：`brew install flutter`
2. 把 `ebike_security/app/` 拷贝到Mac
3. 进入目录：`cd app`
4. 生成iOS项目：`flutter create --platforms=ios .`
5. 打开Xcode：`open ios/Runner.xcworkspace`
6. 在Xcode中配置签名（需要Apple开发者账号，免费即可）
7. 连接iPhone，点击运行，或 **Product → Archive → Distribute** 导出IPA

**注意：** 没有Mac的话，可以：
- 借朋友的Mac用一次
- 去网吧（如果有Mac电脑）
- 使用Codegic、AppCenter等云构建服务

---

## 二、PCB原理图（嘉立创可直接打开）

### 快速开始（10分钟完成原理图）

1. 打开浏览器，访问：**https://lceda.cn** （嘉立创EDA，免费在线版）
2. 注册登录后，点击 **"标准版"**
3. **"新建工程"** → 名称：`深远GT1防盗控制器`

#### 步骤1：导入BOM（自动放置元件）
- 顶部菜单 → **"设计"** → **"导入BOM"**
- 上传文件：`ebike_security/schematics/BOM嘉立创.csv`
- 点击"开始导入"，所有元件自动放置！

#### 步骤2：照着原理图连线
- 用浏览器打开：`ebike_security/schematics/ebike_security_schematic.svg`
- 对照SVG原理图，在嘉立创EDA中点击引脚拖线连接
- 关键连线（参考SVG）：
  - **48V电源** → 保险丝 → TVS → MP2307输入
  - **MP2307输出(12V)** → LM2596输入
  - **LM2596输出(5V)** → AMS1117输入
  - **AMS1117输出(3.3V)** → ESP32的3V3引脚
  - **ESP32 GPIO4** → PC817光耦 → 继电器(门锁)
  - **ESP32 GPIO5** → PC817光耦 → 继电器(座桶)
  - **ESP32 GPIO18/19/21** → MAX98357A(I2S)
  - **MAX98357A** → 4Ω喇叭
  - **原车报警信号** → ESP32 GPIO12(震动中断)
  - **ESP32 GPIO41/42** → SIM7600(4G/GPS预留)

#### 步骤3：检查并转为PCB
- 点击 **"工具"** → **"检查DRC"**（检查错误）
- 修复无误后 → **"设计"** → **"转为PCB"**
- 建议PCB尺寸：**80mm × 60mm**，双面板，1.6mm厚

#### 步骤4：下单生产
- 完成PCB布局后 → **"下单"**
- 选择 **SMT贴片**（自动焊接，告别手工焊接）
- 上传Gerber文件（嘉立创EDA自动生成）
- 支付，等待3-5天收货

**参考文件清单：**
| 文件 | 用途 |
|------|------|
| `schematics/ebike_security_schematic.svg` | 原理图参考（浏览器打开） |
| `schematics/BOM嘉立创.csv` | BOM清单（可直接导入嘉立创EDA） |
| `schematics/netlist.csv` | 网表（连线清单，导入到EDA工具） |
| `schematics/ebike_security_lceda_import.json` | 嘉立创EDA可直接导入的JSON |
| `BOM清单.md` | 详细BOM说明 |
| `嘉立创下单操作指引.md` | 下单详细截图说明 |
| `嘉立创EDA快速绘图指南.md` | 嘉立创EDA使用步骤 |

---

## 三、固件（ESP32代码）

文件夹：`ebike_security/firmware/`

用Arduino IDE打开 `ebike_security.ino`，按以下步骤烧录：

1. Arduino IDE安装ESP32板支持：
   - 文件 → 首选项 → 附加开发板管理器URL：
   ```
   https://dl.espressif.com/dl/package_esp32_index.json
   ```
   - 工具 → 开发板 → 开发板管理器 → 搜索"ESP32" → 安装

2. 烧录：
   - 工具 → 开发板 → **ESP32 Arduino** → **ESP32 Wrover Module**
   - 工具 → Flash Size → **8MB Flash + 8MB PSRAM**
   - 工具 → Upload Speed → **115200**
   - 烧录按钮（→）

3. BLE的Service UUID：`12345678-1234-1234-1234-123456789abc`

---

## 四、技术支持

| 问题 | 解决方案 |
|------|---------|
| APK构建失败 | 使用方案A（GitHub Actions），自动构建 |
| 嘉立创EDA不会用 | 看 `嘉立创EDA快速绘图指南.md`，或B站搜"嘉立创EDA教程" |
| 蓝牙连不上APP | 检查ESP32固件是否烧录，确认UUID一致 |
| 元件买不到 | BOM中有LCSC编号，直接在立创商城搜索编号下单 |
| 不会焊接 | 下单时选择SMT贴片服务，嘉立创自动焊接 |

---

## 五、文件总览

```
ebike_security/
├── firmware/
│   └── ebike_security.ino          # ESP32 Arduino固件
├── app/                            # Flutter APP（安卓+iOS）
│   ├── lib/
│   │   ├── main.dart               # APP入口
│   │   ├── screens/                # 4个页面
│   │   ├── services/               # 蓝牙服务
│   │   ├── models/                 # 数据模型
│   │   └── utils/                 # 常量定义
│   ├── ios/                        # iOS项目配置
│   │   ├── Runner/Info.plist       # iOS权限配置（蓝牙）
│   │   └── Podfile                 # iOS依赖
│   └── pubspec.yaml                # Flutter依赖
├── schematics/
│   ├── ebike_security_schematic.svg    # 原理图（SVG矢量图）
│   ├── BOM嘉立创.csv                   # BOM（嘉立创可导入）
│   ├── netlist.csv                    # 网表（连线清单）
│   └── ebike_security_lceda_import.json  # 嘉立创EDA导入文件
├── .github/workflows/
│   └── build-android-apk.yml       # GitHub Actions云端构建APK
├── build_apk_批处理.bat             # Windows一键构建APK脚本
├── BOM清单.md                      # 详细物料清单
├── APP构建指南.md                  # APP构建说明
├── 嘉立创下单操作指引.md            # 嘉立创下单教程
└── 嘉立创EDA快速绘图指南.md         # 嘉立创EDA使用教程
```

---

**祝你DIY顺利！有问题随时找我。** ⚙️
