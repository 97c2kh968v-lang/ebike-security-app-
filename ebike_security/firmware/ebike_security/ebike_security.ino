/**
 * 深远GT1防盗控制器 - ESP32固件
 * 功能：蓝牙门锁、震动报警、音效播放、座桶控制、4G/GPS预留
 * 框架：Arduino ESP32
 * 作者：小码 for 大哥良
 * 日期：2026-05-05
 */

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <driver/i2s.h>
#include <Preferences.h>
#include <EEPROM.h>

// ==================== GPIO 定义 ====================
#define PIN_LOCK_RELAY   4   // 电门锁继电器（高电平锁车）
#define PIN_SEAT_RELAY   5   // 座桶继电器（脉冲触发）
#define PIN_VIBE_INT    12   // 震动报警信号输入（下降沿触发）
#define PIN_KEY_DETECT   13  // 原车钥匙信号检测（高电平=ACC ON）
#define PIN_LED_STATUS   2   // 状态LED
#define PIN_LED_BT       15  // 蓝牙状态LED

// I2S 音频引脚
#define I2S_BCK_PIN     18
#define I2S_WS_PIN      19
#define I2S_DATA_PIN    21
#define I2S_MCK_PIN     -1  // MAX98357A 不需要MCLK

// 4G/GPS 预留 UART
#define GPS_RX_PIN      16
#define GPS_TX_PIN      17

// ==================== BLE UUID 定义 ====================
#define SERVICE_UUID        "12345678-1234-1234-1234-123456789abc"
#define CHAR_LOCK_UUID      "12345678-1234-1234-1234-123456789abd"  // 锁控制
#define CHAR_MODE_UUID      "12345678-1234-1234-1234-123456789abe"  // 模式切换
#define CHAR_STATUS_UUID    "12345678-1234-1234-1234-123456789abf"  // 状态上报
#define CHAR_SOUND_UUID     "12345678-1234-1234-1234-123456789ac0"  // 音效选择
#define CHAR_SEAT_UUID      "12345678-1234-1234-1234-123456789ac1"  // 座桶开启
#define CHAR_BT_PAIR_UUID   "12345678-1234-1234-1234-123456789ac2"  // 蓝牙配对管理

// ==================== 全局状态 ====================
Preferences prefs;

// 工作模式
enum WorkMode {
  MODE_AUTO = 0,    // 自动模式：蓝牙连上解锁，断开上锁
  MODE_MANUAL = 1    // 手动模式：APP控制开关锁
};
WorkMode currentMode = MODE_AUTO;

// 锁状态
enum LockState {
  LOCKED = 0,
  UNLOCKED = 1
};
LockState lockState = LOCKED;

// 蓝牙配对MAC地址（最多2个）
uint8_t pairedMAC[2][6];
bool btConnected[2] = {false, false};
int connectedCount = 0;

// 震动报警
volatile bool vibeTriggered = false;
unsigned long lastVibeTime = 0;
const unsigned long VIBE_DEBOUNCE = 1000;  // 震动去抖1秒
bool alarmActive = false;
int currentSoundEffect = 0;  // 0-4 音效编号

// ==================== BLE 特征指针 ====================
BLECharacteristic *pLockChar;
BLECharacteristic *pModeChar;
BLECharacteristic *pStatusChar;
BLECharacteristic *pSoundChar;
BLECharacteristic *pSeatChar;
BLECharacteristic *pBtPairChar;

// ==================== I2S 音频 ====================
const i2s_port_t I2S_PORT = I2S_NUM_0;

// 内置音效数据（简化版，实际应从SPIFFS/LittleFS读取）
// 音效0：普通"滴滴"声
// 音效1：警笛声
// 音效2：摩托车轰鸣声
// 音效3：自定义上传音效（预留）
// 音效4：静音

// ==================== 函数声明 ====================
void IRAM_ATTR vibeInterruptHandler();
void loadPreferences();
void savePreferences();
void setLockState(LockState state);
void triggerAlarm();
void playSoundEffect(int effect);
void i2sInit();
void bleInit();
void notifyStatus();
void checkAutoMode();
void pulseSeatRelay();

// ==================== 震动中断处理 ====================
void IRAM_ATTR vibeInterruptHandler() {
  unsigned long now = millis();
  if (now - lastVibeTime > VIBE_DEBOUNCE) {
    vibeTriggered = true;
    lastVibeTime = now;
  }
}

// ==================== 设置 ====================
void setup() {
  Serial.begin(115200);
  Serial.println("=== 深远GT1防盗控制器启动 ===");

  // GPIO初始化
  pinMode(PIN_LOCK_RELAY, OUTPUT);
  pinMode(PIN_SEAT_RELAY, OUTPUT);
  pinMode(PIN_LED_STATUS, OUTPUT);
  pinMode(PIN_LED_BT, OUTPUT);
  pinMode(PIN_KEY_DETECT, INPUT_PULLDOWN);
  pinMode(PIN_VIBE_INT, INPUT_PULLUP);

  digitalWrite(PIN_LOCK_RELAY, LOW);
  digitalWrite(PIN_SEAT_RELAY, LOW);
  digitalWrite(PIN_LED_STATUS, LOW);
  digitalWrite(PIN_LED_BT, LOW);

  // 中断附加
  attachInterrupt(digitalPinToInterrupt(PIN_VIBE_INT), vibeInterruptHandler, FALLING);

  // 加载偏好设置
  loadPreferences();

  // I2S音频初始化
  i2sInit();

  // BLE初始化
  bleInit();

  Serial.println("系统初始化完成！");
  digitalWrite(PIN_LED_STATUS, HIGH);
}

// ==================== 主循环 ====================
void loop() {
  // 1. 检查自动模式
  if (currentMode == MODE_AUTO) {
    checkAutoMode();
  }

  // 2. 检查震动报警
  if (vibeTriggered && !alarmActive) {
    vibeTriggered = false;
    Serial.println("震动报警触发！");
    triggerAlarm();
  }

  // 3. 检查原车钥匙信号（钥匙打开时强制解锁）
  if (digitalRead(PIN_KEY_DETECT) == HIGH) {
    if (lockState == LOCKED) {
      Serial.println("检测到钥匙信号，强制解锁");
      setLockState(UNLOCKED);
    }
  }

  // 4. 报警播放中...
  if (alarmActive) {
    // 报警持续10秒后停止
    static unsigned long alarmStartTime = 0;
    if (alarmStartTime == 0) alarmStartTime = millis();
    if (millis() - alarmStartTime > 10000) {
      alarmActive = false;
      alarmStartTime = 0;
      Serial.println("报警结束");
      // TODO: 停止音频播放
    }
  }

  delay(50);
}

// ==================== 锁控制 ====================
void setLockState(LockState state) {
  lockState = state;
  if (state == LOCKED) {
    digitalWrite(PIN_LOCK_RELAY, HIGH);  // 高电平锁车（根据实际接线调整）
    Serial.println("已上锁");
  } else {
    digitalWrite(PIN_LOCK_RELAY, LOW);
    Serial.println("已解锁");
  }
  notifyStatus();
}

// ==================== 自动模式检查 ====================
void checkAutoMode() {
  bool anyConnected = (connectedCount > 0);
  
  if (anyConnected && lockState == LOCKED) {
    Serial.println("蓝牙已连接（自动模式），自动解锁");
    setLockState(UNLOCKED);
  } else if (!anyConnected && lockState == UNLOCKED) {
    // 延迟5秒后上锁（避免短暂断连）
    static unsigned long disconnectTime = 0;
    if (disconnectTime == 0) disconnectTime = millis();
    if (millis() - disconnectTime > 5000) {
      Serial.println("蓝牙已断开（自动模式），自动上锁");
      setLockState(LOCKED);
      disconnectTime = 0;
    }
  } else {
    // 重置计时器
  }
}

// ==================== 震动报警 ====================
void triggerAlarm() {
  alarmActive = true;
  playSoundEffect(currentSoundEffect);
  notifyStatus();  // 通知APP报警触发
}

// ==================== 座桶开启 ====================
void pulseSeatRelay() {
  digitalWrite(PIN_SEAT_RELAY, HIGH);
  delay(100);  // 100ms脉冲
  digitalWrite(PIN_SEAT_RELAY, LOW);
  Serial.println("座桶已开启");
}

// ==================== 音频播放 ====================
void i2sInit() {
  i2s_config_t i2s_config = {
    .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX),
    .sample_rate = 44100,
    .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT,
    .channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT,
    .communication_format = I2S_COMM_FORMAT_I2S_MSB,
    .intr_alloc_flags = 0,
    .dma_buf_count = 8,
    .dma_buf_len = 1024,
    .use_apll = false,
    .tx_desc_auto_clear = true
  };

  i2s_pin_config_t pin_config = {
    .bck_io_num = I2S_BCK_PIN,
    .ws_io_num = I2S_WS_PIN,
    .data_out_num = I2S_DATA_PIN,
    .data_in_num = I2S_PIN_NO_CHANGE
  };

  i2s_driver_install(I2S_PORT, &i2s_config, 0, NULL);
  i2s_set_pin(I2S_PORT, &pin_config);
  i2s_zero_dma_buffer(I2S_PORT);
}

void playSoundEffect(int effect) {
  Serial.print("播放音效: ");
  Serial.println(effect);
  // TODO: 根据实际音效数据通过I2S发送音频数据
  // 可以从SPIFFS读取预存的WAV/MP3文件，或生成合成音效
  // 参考：使用audio_pipeline或直接I2S写数据
}

// ==================== BLE 通信 ====================
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer, esp_ble_gatts_cb_param_t* param) {
    connectedCount++;
    Serial.println("BLE设备已连接");
    digitalWrite(PIN_LED_BT, HIGH);
    notifyStatus();
  }

  void onDisconnect(BLEServer* pServer) {
    connectedCount--;
    if (connectedCount < 0) connectedCount = 0;
    Serial.println("BLE设备已断开");
    if (connectedCount == 0) {
      digitalWrite(PIN_LED_BT, LOW);
    }
    notifyStatus();
  }
};

class LockCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    if (value.length() > 0) {
      int cmd = value[0];
      if (cmd == 0x01) {
        setLockState(LOCKED);
      } else if (cmd == 0x02) {
        setLockState(UNLOCKED);
      }
      Serial.print("APP锁控制命令: ");
      Serial.println(cmd);
    }
  }
};

class ModeCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    if (value.length() > 0) {
      currentMode = (value[0] == 0x01) ? MODE_AUTO : MODE_MANUAL;
      savePreferences();
      Serial.print("工作模式切换: ");
      Serial.println(currentMode == MODE_AUTO ? "自动" : "手动");
      notifyStatus();
    }
  }
};

class SoundCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    if (value.length() > 0) {
      currentSoundEffect = value[0];
      savePreferences();
      Serial.print("音效切换: ");
      Serial.println(currentSoundEffect);
    }
  }
};

class SeatCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    std::string value = pCharacteristic->getValue();
    if (value.length() > 0 && value[0] == 0x01) {
      pulseSeatRelay();
      notifyStatus();
    }
  }
};

void bleInit() {
  BLEDevice::init("深远GT1防盗器");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);

  // 锁控制特征
  pLockChar = pService->createCharacteristic(CHAR_LOCK_UUID, BLECharacteristic::PROPERTY_WRITE);
  pLockChar->setCallbacks(new LockCallbacks());
  pLockChar->addDescriptor(new BLE2902());

  // 模式切换特征
  pModeChar = pService->createCharacteristic(CHAR_MODE_UUID, BLECharacteristic::PROPERTY_WRITE);
  pModeChar->setCallbacks(new ModeCallbacks());
  pModeChar->addDescriptor(new BLE2902());

  // 状态上报特征（通知）
  pStatusChar = pService->createCharacteristic(CHAR_STATUS_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  pStatusChar->addDescriptor(new BLE2902());

  // 音效选择特征
  pSoundChar = pService->createCharacteristic(CHAR_SOUND_UUID, BLECharacteristic::PROPERTY_WRITE);
  pSoundChar->setCallbacks(new SoundCallbacks());
  pSoundChar->addDescriptor(new BLE2902());

  // 座桶开启特征
  pSeatChar = pService->createCharacteristic(CHAR_SEAT_UUID, BLECharacteristic::PROPERTY_WRITE);
  pSeatChar->setCallbacks(new SeatCallbacks());
  pSeatChar->addDescriptor(new BLE2902());

  // 蓝牙配对管理（预留）
  pBtPairChar = pService->createCharacteristic(CHAR_BT_PAIR_UUID, 
                BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_READ);
  pBtPairChar->addDescriptor(new BLE2902());

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  Serial.println("BLE初始化完成，等待连接...");
}

void notifyStatus() {
  if (pStatusChar == nullptr) return;
  
  uint8_t status[8];
  status[0] = (lockState == LOCKED) ? 0x01 : 0x00;
  status[1] = (currentMode == MODE_AUTO) ? 0x01 : 0x00;
  status[2] = connectedCount;
  status[3] = alarmActive ? 0x01 : 0x00;
  status[4] = currentSoundEffect;
  status[5] = digitalRead(PIN_KEY_DETECT);
  status[6] = 0x00;  // 预留：4G信号强度
  status[7] = 0x00;  // 预留：GPS定位状态

  pStatusChar->setValue(status, 8);
  pStatusChar->notify();
}

// ==================== 偏好设置存储 ====================
void loadPreferences() {
  prefs.begin("ebike_security", true);  // 只读模式
  currentMode = (WorkMode)prefs.getInt("work_mode", 0);
  currentSoundEffect = prefs.getInt("sound_fx", 0);
  
  // 读取配对的MAC地址
  String mac0 = prefs.getString("mac0", "");
  String mac1 = prefs.getString("mac1", "");
  // TODO: 将字符串MAC转换为6字节数组
  
  prefs.end();
  Serial.println("偏好设置已加载");
}

void savePreferences() {
  prefs.begin("ebike_security", false);  // 读写模式
  prefs.putInt("work_mode", (int)currentMode);
  prefs.putInt("sound_fx", currentSoundEffect);
  prefs.end();
  Serial.println("偏好设置已保存");
}
