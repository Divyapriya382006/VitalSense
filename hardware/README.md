# Hardware Integration — VitalSense

This directory documents the real-time hardware layer for VitalSense.

## Components

| Component | Model | Interface |
|-----------|-------|-----------|
| Pulse Oximeter | MAX30102 | I²C — SDA: GPIO21, SCL: GPIO22 |
| Body Temperature | DS18B20 | 1-Wire — GPIO4 + 4.7 kΩ pull-up to 3.3 V |
| Ambient Humidity | DHT11 | GPIO15 + 4.7 kΩ pull-up to 3.3 V |
| Microcontroller | ESP32 (30-pin) | Wi-Fi 2.4 GHz |

## Flashing the ESP32 Firmware

1. Install [Arduino IDE 2.x](https://www.arduino.cc/en/software).
2. Add ESP32 board support: **File → Preferences → Additional boards manager URLs**  
   `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
3. Install required libraries via **Tools → Manage Libraries**:
   - `MAX30105` (SparkFun)
   - `DallasTemperature`
   - `OneWire`
   - `DHT sensor library` (Adafruit)
   - `ArduinoJson` (Benoit Blanchon)
4. Open `VitalSense_hardware_integration.ino` (repo root).
5. Edit the WiFi credentials if on a different network:
   ```cpp
   const char* ssid = "YOUR_SSID";
   const char* password = "YOUR_PASSWORD";
   ```
6. Select **Tools → Board → ESP32 Dev Module**, choose the correct COM port.
7. Click **Upload**.
8. Open **Serial Monitor** at 115200 baud — the ESP32 IP address will be printed on boot.

## ESP32 HTTP API Endpoints

| Endpoint | Method | Response | Description |
|----------|--------|----------|-------------|
| `/json`  | GET | JSON | Latest readings + status |
| `/history` | GET | JSON | Last 20 readings ring buffer |
| `/pulse` | GET | Plain text int | Raw IR ADC value |
| `/bpm`   | GET | Plain text int | Heart rate |
| `/vitals` | GET | CSV string | `hr,spo2,temp` |

### Example `/json` response
```json
{
  "hr": 78,
  "spo2": 98,
  "bodyTemp": 36.8,
  "fingerDetected": true,
  "status": "Normal",
  "statusLevel": 0,
  "uptime": 12345
}
```

## Connecting from the Flutter App

1. Ensure your phone/tablet and the ESP32 are on the **same WiFi network**.
2. Launch VitalSense → any portal → Config tab.
3. Enter the ESP32's IP address (shown in Arduino Serial Monitor).
4. Toggle **Demo → Real-Time** or tap **Connect**.
5. Place a finger on the MAX30102 sensor — vitals will appear within ~4 seconds.

## `ecg_monitor.py` — Desktop ECG Viewer

`ecg_monitor.py` is a standalone [Kivy](https://kivy.org/) desktop application that:
- Connects to the ESP32 `/pulse` endpoint via HTTP.
- Renders a real-time scrolling ECG waveform.
- Detects peaks and calculates heart rate.

### Running the Desktop Viewer
```bash
pip install kivy requests
python ecg_monitor.py
```

> **Note:** This is a standalone reference tool and is **not** embedded in the Flutter app.
> The Flutter app's ECG screen generates a Lead-II morphology waveform driven by the real HR value from the `/json` endpoint.

## Caching Behaviour

When the ESP32 is disconnected or no finger is detected, the Flutter app:
- Displays the **last known good values** with a `CACHED` badge.
- Keeps the history ring buffer intact for trend charts and reports.
- Shows the time elapsed since the last valid reading.
