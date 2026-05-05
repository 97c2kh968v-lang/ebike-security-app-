#!/usr/bin/env python3
"""
生成深远GT1防盗控制器完整原理图 - SVG矢量图
输出：ebike_security_schematic.svg（可在浏览器打开，嘉立创EDA可导入SVG参考）
"""

import math

SVG_WIDTH = 1200
SVG_HEIGHT = 1600

def svg_header(w, h, title):
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">
<style>
  .comp-title {{ font: bold 14px sans-serif; fill: #1a1a1a; }}
  .pin-label {{ font: 10px monospace; fill: #333; }}
  .wire {{ stroke: #222; stroke-width: 2; fill: none; }}
  .wire-gnd {{ stroke: #228B22; stroke-width: 2; fill: none; }}
  .wire-pwr {{ stroke: #DC143C; stroke-width: 2.5; fill: none; }}
  .wire-sig {{ stroke: #1E90FF; stroke-width: 1.5; fill: none; }}
  .box {{ fill: #f0f4ff; stroke: #4040a0; stroke-width: 2; rx: 6; }}
  .box-esp {{ fill: #e8f5e9; stroke: #2e7d32; stroke-width: 2.5; rx: 8; }}
  .box-power {{ fill: #fff3e0; stroke: #e65100; stroke-width: 2; rx: 6; }}
  .box-relay {{ fill: #fce4ec; stroke: #c62828; stroke-width: 2; rx: 6; }}
  .pin-dot {{ fill: #333; }}
  .label {{ font: 11px sans-serif; fill: #1a1a1a; }}
  .net-label {{ font: bold 10px monospace; fill: #000; }}
  .title {{ font: bold 18px sans-serif; fill: #1a1a1a; }}
  .subtitle {{ font: 13px sans-serif; fill: #444; }}
  .gnd-sym {{ stroke: #228B22; stroke-width: 2; fill: none; }}
  .pwr-sym {{ stroke: #DC143C; stroke-width: 2; fill: none; }}
</style>
<!-- {title} -->
'''

def draw_rect(x, y, w, h, cls="box"):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" class="{cls}"/>'

def draw_text(x, y, text, cls="label", anchor="middle"):
    return f'<text x="{x}" y="{y}" class="{cls}" text-anchor="{anchor}">{text}</text>'

def draw_pin(x, y, label, side="left", pin_type="io"):
    """Draw a pin dot and label"""
    color = {"pwr": "#DC143C", "gnd": "#228B22", "io": "#1E90FF"}.get(pin_type, "#333")
    s = f'<circle cx="{x}" cy="{y}" r="3" fill="{color}"/>'
    if side == "left":
        s += f'<text x="{x-8}" y="{y+4}" class="pin-label" text-anchor="end">{label}</text>'
    else:
        s += f'<text x="{x+8}" y="{y+4}" class="pin-label" text-anchor="start">{label}</text>'
    return s

def draw_wire(x1, y1, x2, y2, cls="wire"):
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" class="{cls}"/>'

def draw_wire_3pt(x1, y1, x2, y2, mid_x=None, cls="wire"):
    """Draw wire with optional right-angle bend"""
    if mid_x is None:
        mid_x = (x1 + x2) // 2
    return f'<path d="M{x1},{y1} L{mid_x},{y1} L{mid_x},{y2} L{x2},{y2}" class="{cls}"/>'

def draw_component_box(x, y, w, h, title, pins_left, pins_right, cls="box"):
    """Draw a component as a box with pins"""
    s = draw_rect(x, y, w, h, cls)
    # Title in center
    s += draw_text(x + w//2, y + h//2 + 5, title, "comp-title")
    # Left pins
    n = len(pins_left)
    for i, (pname, ptype) in enumerate(pins_left):
        py = y + 20 + i * (h - 40) // max(n-1, 1)
        s += f'<circle cx="{x}" cy="{py}" r="3" fill="{"#DC143C" if ptype=="pwr" else ("#228B22" if ptype=="gnd" else "#1E90FF")}"/>'
        s += f'<text x="{x+10}" y="{py+4}" class="pin-label">{pname}</text>'
    # Right pins
    n = len(pins_right)
    for i, (pname, ptype) in enumerate(pins_right):
        py = y + 20 + i * (h - 40) // max(n-1, 1)
        s += f'<circle cx="{x+w}" cy="{py}" r="3" fill="{"#DC143C" if ptype=="pwr" else ("#228B22" if ptype=="gnd" else "#1E90FF")}"/>'
        s += f'<text x="{x+w-10}" y="{py+4}" class="pin-label" text-anchor="end">{pname}</text>'
    return s

def generate_svg():
    parts = []
    parts.append(svg_header(SVG_WIDTH, SVG_HEIGHT, "深远GT1防盗控制器原理图"))
    
    # Title
    parts.append(draw_text(600, 40, "深远GT1 电动车防盗控制器 - 电路原理图 v1.0", "title"))
    parts.append(draw_text(600, 65, "ESP32-WROVER-E主控 | 48V电动车电源 | 蓝牙门锁+震动报警+座桶控制", "subtitle"))
    
    # === Power Section (Left side) ===
    # XT60 Input
    x_xt60 = 30
    y_xt60 = 100
    parts.append(draw_rect(x_xt60, y_xt60, 120, 60, "box-power"))
    parts.append(draw_text(x_xt60 + 60, y_xt60 + 35, "XT60 48V输入", "comp-title"))
    parts.append(draw_text(x_xt60 + 15, y_xt60 + 55, "+48V", "pin-label"))
    parts.append(draw_text(x_xt60 + 105, y_xt60 + 55, "GND", "pin-label"))
    
    # Fuse
    x_fuse = 30
    y_fuse = 190
    parts.append(draw_rect(x_fuse, y_fuse, 120, 50, "box-power"))
    parts.append(draw_text(x_fuse + 60, y_fuse + 30, "30A保险丝", "comp-title"))
    
    # TVS Diode
    x_tvs = 30
    y_tvs = 265
    parts.append(draw_rect(x_tvs, y_tvs, 120, 50, "box-power"))
    parts.append(draw_text(x_tvs + 60, y_tvs + 30, "SMBJ58A TVS", "comp-title"))
    
    # MP2307: 48V->12V
    x_mp = 30
    y_mp = 350
    parts.append(draw_rect(x_mp, y_mp, 140, 70, "box-power"))
    parts.append(draw_text(x_mp + 70, y_mp + 40, "MP2307\A48V→12V 3A", "comp-title"))
    parts.append(draw_text(x_mp + 10, y_mp + 20, "VIN+", "pin-label"))
    parts.append(draw_text(x_mp + 10, y_mp + 50, "VIN-", "pin-label"))
    parts.append(draw_text(x_mp + 130, y_mp + 20, "VOUT+ 12V", "pin-label"))
    parts.append(draw_text(x_mp + 130, y_mp + 50, "VOUT-", "pin-label"))
    
    # LM2596: 12V->5V
    x_lm = 30
    y_lm = 460
    parts.append(draw_rect(x_lm, y_lm, 140, 70, "box-power"))
    parts.append(draw_text(x_lm + 70, y_lm + 40, "LM2596\A12V→5V 2A", "comp-title"))
    parts.append(draw_text(x_lm + 10, y_lm + 20, "VIN", "pin-label"))
    parts.append(draw_text(x_lm + 10, y_lm + 50, "GND", "pin-label"))
    parts.append(draw_text(x_lm + 130, y_lm + 20, "VOUT 5V", "pin-label"))
    parts.append(draw_text(x_lm + 130, y_lm + 50, "GND", "pin-label"))
    
    # AMS1117: 5V->3.3V
    x_ams = 30
    y_ams = 570
    parts.append(draw_rect(x_ams, y_ams, 140, 60, "box-power"))
    parts.append(draw_text(x_ams + 70, y_ams + 35, "AMS1117-3.3\A5V→3.3V", "comp-title"))
    parts.append(draw_text(x_ams + 10, y_ams + 20, "VIN 5V", "pin-label"))
    parts.append(draw_text(x_ams + 10, y_ams + 45, "GND", "pin-label"))
    parts.append(draw_text(x_ams + 130, y_ams + 35, "VOUT 3.3V", "pin-label"))
    
    # === ESP32 (Center) ===
    x_esp = 350
    y_esp = 200
    esp_w = 200
    esp_h = 500
    parts.append(draw_rect(x_esp, y_esp, esp_w, esp_h, "box-esp"))
    parts.append(draw_text(x_esp + esp_w//2, y_esp + 30, "ESP32-WROVER-E", "comp-title"))
    parts.append(draw_text(x_esp + esp_w//2, y_esp + 50, "WiFi + BLE + 双核240MHz", "subtitle"))
    
    # ESP32 Left Pins
    esp_left_pins = [
        ("GND", "gnd"), ("3V3", "pwr"), ("EN", "io"), ("GPIO0", "io"),
        ("TX0", "io"), ("RX0", "io"), ("GPIO4", "io"), ("GPIO5", "io"),
        ("GPIO12", "io"), ("GPIO13", "io"), ("GPIO14", "io"), ("GPIO15", "io"),
        ("GND", "gnd"),
    ]
    for i, (name, ptype) in enumerate(esp_left_pins):
        py = y_esp + 70 + i * (esp_h - 100) // max(len(esp_left_pins)-1, 1)
        parts.append(f'<circle cx="{x_esp}" cy="{py}" r="4" fill="{"#DC143C" if ptype=="pwr" else ("#228B22" if ptype=="gnd" else "#1E90FF")}"/>')
        parts.append(f'<text x="{x_esp+12}" y="{py+4}" class="pin-label">{name}</text>')
    
    # ESP32 Right Pins
    esp_right_pins = [
        ("GPIO25", "io"), ("GPIO26", "io"), ("GPIO27", "io"), ("GPIO32", "io"),
        ("GPIO33", "io"), ("GPIO34", "in"), ("GPIO35", "in"), ("GPIO36", "in"),
        ("I2S_BCK", "io"), ("I2S_WS", "io"), ("I2S_DIN", "io"),
        ("UART_RX2", "io"), ("UART_TX2", "io"),
        ("3V3", "pwr"), ("GND", "gnd"),
    ]
    for i, (name, ptype) in enumerate(esp_right_pins):
        py = y_esp + 70 + i * (esp_h - 100) // max(len(esp_right_pins)-1, 1)
        parts.append(f'<circle cx="{x_esp+esp_w}" cy="{py}" r="4" fill="{"#DC143C" if ptype=="pwr" else ("#228B22" if ptype=="gnd" else "#1E90FF")}"/>')
        parts.append(f'<text x="{x_esp+esp_w-12}" y="{py+4}" class="pin-label" text-anchor="end">{name}</text>')
    
    # === Relays (Right side) ===
    # Relay 1: Door Lock
    x_r1 = 850
    y_r1 = 150
    parts.append(draw_rect(x_r1, y_r1, 140, 80, "box-relay"))
    parts.append(draw_text(x_r1 + 70, y_r1 + 45, "门锁继电器\ASRD-12VDC", "comp-title"))
    parts.append(draw_text(x_r1 + 10, y_r1 + 20, "COIL+", "pin-label"))
    parts.append(draw_text(x_r1 + 10, y_r1 + 65, "COIL-", "pin-label"))
    parts.append(draw_text(x_r1 + 130, y_r1 + 20, "COM", "pin-label"))
    parts.append(draw_text(x_r1 + 130, y_r1 + 65, "NO", "pin-label"))
    
    # PC817 Optocoupler 1 (drives Relay 1)
    x_pc1 = 700
    y_pc1 = 150
    parts.append(draw_rect(x_pc1, y_pc1, 120, 80, "box"))
    parts.append(draw_text(x_pc1 + 60, y_pc1 + 45, "PC817\A光耦隔离", "comp-title"))
    parts.append(draw_text(x_pc1 + 10, y_pc1 + 20, "A(GPIO4)", "pin-label"))
    parts.append(draw_text(x_pc1 + 10, y_pc1 + 65, "K(GND)", "pin-label"))
    parts.append(draw_text(x_pc1 + 110, y_pc1 + 45, "C→Relay", "pin-label"))
    
    # Relay 2: Seat Lock
    x_r2 = 850
    y_r2 = 300
    parts.append(draw_rect(x_r2, y_r2, 140, 80, "box-relay"))
    parts.append(draw_text(x_r2 + 70, y_r2 + 45, "座桶继电器\ASRD-12VDC", "comp-title"))
    parts.append(draw_text(x_r2 + 10, y_r2 + 20, "COIL+", "pin-label"))
    parts.append(draw_text(x_r2 + 10, y_r2 + 65, "COIL-", "pin-label"))
    parts.append(draw_text(x_r2 + 130, y_r2 + 20, "COM", "pin-label"))
    parts.append(draw_text(x_r2 + 130, y_r2 + 65, "NO→Pulse", "pin-label"))
    
    # PC817 Optocoupler 2
    x_pc2 = 700
    y_pc2 = 300
    parts.append(draw_rect(x_pc2, y_pc2, 120, 80, "box"))
    parts.append(draw_text(x_pc2 + 60, y_pc2 + 45, "PC817\A光耦隔离", "comp-title"))
    parts.append(draw_text(x_pc2 + 10, y_pc2 + 20, "A(GPIO5)", "pin-label"))
    
    # === I2S Audio (Bottom center) ===
    x_audio = 350
    y_audio = 800
    parts.append(draw_rect(x_audio, y_audio, 200, 100, "box"))
    parts.append(draw_text(x_audio + 100, y_audio + 55, "MAX98357A\AI2S DAC + 功放", "comp-title"))
    parts.append(draw_text(x_audio + 10, y_audio + 25, "VDD", "pin-label"))
    parts.append(draw_text(x_audio + 10, y_audio + 75, "BCLK/WS/DIN", "pin-label"))
    parts.append(draw_text(x_audio + 190, y_audio + 55, "OUT+/-→喇叭", "pin-label"))
    
    # Speaker
    x_sp = 350
    y_sp = 950
    parts.append(draw_rect(x_sp, y_sp, 200, 60, "box"))
    parts.append(draw_text(x_sp + 100, y_sp + 35, "4Ω 3W 喇叭", "comp-title"))
    
    # === Vibration Sensor ===
    x_vibe = 600
    y_vibe = 800
    parts.append(draw_rect(x_vibe, y_vibe, 150, 60, "box"))
    parts.append(draw_text(x_vibe + 75, y_vibe + 35, "震动传感器\A（接原车报警信号）", "comp-title"))
    
    # === 4G/GPS (Reserved) ===
    x_4g = 600
    y_4g = 950
    parts.append(draw_rect(x_4g, y_4g, 150, 60, "box"))
    parts.append(draw_text(x_4g + 75, y_4g + 35, "SIM7600 4G/GPS\A（预留UART2）", "comp-title"))
    
    # === Power Rails (Bus bars) ===
    # 48V rail
    parts.append(f'<line x1="170" y1="130" x2="340" y2="130" class="wire-pwr"/>')
    parts.append(draw_text(340, 125, "48V", "net-label"))
    # 12V rail
    parts.append(f'<line x1="170" y1="{350+35}" x2="340" y2="{350+35}" class="wire-pwr"/>')
    parts.append(draw_text(340, 385, "12V", "net-label"))
    # 5V rail
    parts.append(f'<line x1="170" y1="{460+35}" x2="340" y2="{460+35}" class="wire-pwr"/>')
    parts.append(draw_text(480, 495, "5V", "net-label"))
    # 3.3V rail
    parts.append(f'<line x1="170" y1="{570+30}" x2="340" y2="{570+30}" class="wire-pwr"/>')
    parts.append(draw_text(480, 605, "3.3V", "net-label"))
    # GND rail
    parts.append(f'<line x1="170" y1="750" x2="1000" y2="750" class="wire-gnd"/>')
    parts.append(draw_text(800, 745, "GND", "net-label"))
    
    # === Connection Wires (simplified) ===
    # XT60 -> Fuse -> TVS -> MP2307
    parts.append(draw_wire(150, 130, 170, 130, "wire-pwr"))
    parts.append(draw_wire(170, 215, 170, 130, "wire-pwr"))
    parts.append(draw_wire(170, 290, 170, 215, "wire-pwr"))
    parts.append(draw_wire(170, 350+35, 170, 290, "wire-pwr"))
    
    # MP2307 12V out -> LM2596
    parts.append(draw_wire(x_mp + 140, y_mp + 35, x_lm + 0, y_lm + 35, "wire-pwr"))
    
    # LM2596 5V out -> AMS1117
    parts.append(draw_wire(x_lm + 140, y_lm + 35, x_ams + 0, y_ams + 30, "wire-pwr"))
    
    # AMS1117 3.3V -> ESP32
    parts.append(draw_wire(x_ams + 140, y_ams + 35, x_esp + 0, y_esp + 85, "wire-pwr"))  # to ESP32 3V3
    
    # ESP32 GPIO4 -> PC817 -> Relay1
    parts.append(draw_wire(x_esp + 0, y_esp + 160, x_pc1 + 0, y_pc1 + 20, "wire-sig"))
    parts.append(draw_wire(x_pc1 + 120, y_pc1 + 45, x_r1 + 0, y_r1 + 20, "wire-sig"))
    
    # ESP32 GPIO5 -> PC817 -> Relay2
    parts.append(draw_wire(x_esp + 0, y_esp + 190, x_pc2 + 0, y_pc2 + 20, "wire-sig"))
    
    # ESP32 I2S -> MAX98357A
    esp_i2s_y = y_esp + 370
    parts.append(draw_wire(x_esp + esp_w, esp_i2s_y, x_audio + 0, y_audio + 75, "wire-sig"))
    
    # MAX98357A -> Speaker
    parts.append(draw_wire(x_audio + esp_w, y_audio + 55, x_sp + 100, y_sp + 30, "wire-sig"))
    
    # Vibration sensor -> ESP32 GPIO12
    vibe_y = y_vibe + 35
    esp_vibe_y = y_esp + 250
    parts.append(draw_wire(x_vibe + 0, vibe_y, x_esp + 0, esp_vibe_y, "wire-sig"))
    
    # === Notes ===
    notes_y = 1100
    notes = [
        "连接说明：",
        "1. 电源：48V电动车电池 → XT60 → 30A保险丝 → TVS浪涌保护 → MP2307(48V→12V) → LM2596(12V→5V) → AMS1117(5V→3.3V)",
        "2. 门锁控制：ESP32 GPIO4 → PC817光耦 → 12V继电器 → 原车电门锁信号线（并联）",
        "3. 座桶控制：ESP32 GPIO5 → PC817光耦 → 12V继电器（脉冲触发100ms） → 座桶锁电机",
        "4. 震动报警：原车报警器信号 → GPIO12（下降沿中断） → 触发MAX98357A播放音效",
        "5. 蓝牙：ESP32 BLE，UUID: 12345678-1234-1234-1234-123456789abc",
        "6. 4G/GPS：预留UART2接口（GPIO41/RX2, GPIO42/TX2），可接SIM7600模块",
        "7. 所有12V/48V信号均通过PC817光耦隔离，保护ESP32",
        "",
        "嘉立创下单：",
        "- 将BOM嘉立创.csv导入嘉立创EDA，自动匹配元件",
        "- PCB尺寸建议：80mm x 60mm，双面板，1.6mm厚度",
        "- SMT贴片：选择BOM中所有贴片元件，省去手工焊接",
    ]
    for i, note in enumerate(notes):
        cls = "comp-title" if i == 0 else "label"
        parts.append(draw_text(30, notes_y + i * 25, note, cls, "start"))
    
    # Close SVG
    parts.append("</svg>")
    
    return "\n".join(parts)

def main():
    svg_content = generate_svg()
    output_path = r"c:\Users\liang\WorkBuddy\20260409160048\ebike_security\schematics\ebike_security_schematic.svg"
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(svg_content)
    print(f"✅ SVG原理图已生成：{output_path}")
    print(f"   用浏览器打开即可查看，可缩放，矢量格式不模糊")
    print()
    
    # Also generate a simplified netlist CSV for import into any EDA tool
    netlist_path = r"c:\Users\liang\WorkBuddy\20260409160048\ebike_security\schematics\netlist.csv"
    with open(netlist_path, 'w', encoding='utf-8') as f:
        f.write("From,From Pin,To,To Pin,Net Name,Signal Type\n")
        connections = [
            ("XT60", "+", "FUSE", "IN", "48V", "power"),
            ("FUSE", "OUT", "TVS", "A", "48V", "power"),
            ("TVS", "K", "MP2307", "VIN+", "48V", "power"),
            ("MP2307", "VOUT+", "LM2596", "VIN", "12V", "power"),
            ("LM2596", "VOUT", "AMS1117", "VIN", "5V", "power"),
            ("AMS1117", "VOUT", "ESP32", "3V3", "3.3V", "power"),
            ("ESP32", "GPIO4", "PC817_1", "A", "LOCK_SIG", "signal"),
            ("PC817_1", "C", "RELAY1", "COIL+", "RLY1_DRV", "signal"),
            ("ESP32", "GPIO5", "PC817_2", "A", "SEAT_SIG", "signal"),
            ("ESP32", "GPIO18", "MAX98357A", "BCLK", "I2S_BCK", "signal"),
            ("ESP32", "GPIO19", "MAX98357A", "LRCLK", "I2S_WS", "signal"),
            ("ESP32", "GPIO21", "MAX98357A", "DIN", "I2S_DIN", "signal"),
            ("ESP32", "GPIO12", "VIBE_SENSOR", "OUT", "VIBE_INT", "signal"),
            ("ESP32", "GPIO41", "SIM7600", "RX", "UART2_TX", "signal"),
            ("ESP32", "GPIO42", "SIM7600", "TX", "UART2_RX", "signal"),
        ]
        for c in connections:
            f.write(f"{c[0]},{c[1]},{c[2]},{c[3]},{c[4]},{c[5]}\n")
    print(f"✅ 网表已生成：{netlist_path}")
    print(f"   可导入嘉立创EDA或其他EDA工具")

if __name__ == "__main__":
    main()
