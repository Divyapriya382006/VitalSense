#include <WiFi.h>
#include <WebServer.h>
#include <Wire.h>
#include "MAX30105.h"
#include "spo2_algorithm.h"
#include <OneWire.h>
#include <DallasTemperature.h>
#include <ArduinoJson.h>

const char* ssid     = "VITC-EVENT";
const char* password = "Eve$23&24#%";

#define DS18B20_PIN 4

WebServer         server(80);
MAX30105          particleSensor;
OneWire           oneWire(DS18B20_PIN);
DallasTemperature sensors(&oneWire);

#define BUFFER_SIZE 100
uint32_t irBuffer[BUFFER_SIZE];
uint32_t redBuffer[BUFFER_SIZE];
uint32_t pulseSignal = 0;

int32_t heartRate      = 0;
int8_t  validHeartRate = 0;
int32_t spo2           = 0;
int8_t  validSpO2      = 0;
float   bodyTemp       = 0.0;
String  patientStatus  = "Normal";
int     statusLevel    = 0;

int lowSpo2Count    = 0;
int abnormalHrCount = 0;

unsigned long lastCalc = 0;

#define HIST_SIZE 20
struct VitalRecord { int32_t hr; int32_t spo2; float bodyTemp; unsigned long ts; };
VitalRecord history[HIST_SIZE];
int histIndex = 0;
int histCount = 0;

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);

  Serial.println("Initializing sensors...");

  if (!particleSensor.begin(Wire, I2C_SPEED_STANDARD)) {
    Serial.println("MAX30102 not found");
    while (1);
  }
  Serial.println("MAX30102 detected");
  particleSensor.setup();
  particleSensor.setPulseAmplitudeRed(0x0A);
  particleSensor.setPulseAmplitudeGreen(0);

  sensors.begin();

  WiFi.begin(ssid, password);
  Serial.println("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");
  Serial.print("Open browser: http://");
  Serial.println(WiFi.localIP());
  Serial.println("==============================================");
  Serial.print("Give this IP to the Flutter app: ");
  Serial.println(WiFi.localIP());
  Serial.println("==============================================");

  server.on("/",        handle_Root);
  server.on("/json",    handle_JSON);
  server.on("/pulse",   handle_Pulse);
  server.on("/bpm",     handle_BPM);
  server.on("/vitals",  handle_Vitals);
  server.on("/history", handle_History);
  server.onNotFound([]() { server.send(404, "text/plain", "Not found"); });

  server.begin();
  Serial.println("HTTP server started");
}

void loop() {
  server.handleClient();

  particleSensor.check();
  if (particleSensor.available()) {
    pulseSignal = particleSensor.getIR();
    particleSensor.nextSample();
  }

  if (millis() - lastCalc > 2000) {

    for (byte i = 0; i < BUFFER_SIZE; i++) {
      while (!particleSensor.available()) particleSensor.check();
      redBuffer[i] = particleSensor.getRed();
      irBuffer[i]  = particleSensor.getIR();
      particleSensor.nextSample();
    }

    maxim_heart_rate_and_oxygen_saturation(
      irBuffer, BUFFER_SIZE, redBuffer,
      &spo2, &validSpO2,
      &heartRate, &validHeartRate
    );

    sensors.requestTemperatures();
    bodyTemp = sensors.getTempCByIndex(0);

    Serial.print("BPM: ");       Serial.println(heartRate);
    Serial.print("SpO2: ");      Serial.println(spo2);
    Serial.print("Body Temp: "); Serial.println(bodyTemp);
    Serial.println("---------------------");

    statusLevel   = 0;
    patientStatus = "Normal";

    if ((validSpO2 && spo2 < 92) ||
        (validHeartRate && (heartRate < 50 || heartRate > 120))) {
      patientStatus = "Warning";
      statusLevel   = 1;
    }
    if ((validSpO2 && spo2 < 88) ||
        (validHeartRate && (heartRate < 40 || heartRate > 140))) {
      patientStatus = "Critical";
      statusLevel   = 2;
    }

    if (validSpO2 && spo2 < 92 && spo2 > 0) lowSpo2Count++;
    else lowSpo2Count = 0;
    if (lowSpo2Count >= 7) {
      Serial.println("[ALERT] Low SpO2 sustained!");
      lowSpo2Count = 0;
    }

    if (validHeartRate && (heartRate < 45 || heartRate > 130)) abnormalHrCount++;
    else abnormalHrCount = 0;
    if (abnormalHrCount >= 7) {
      Serial.println("[ALERT] Abnormal HR sustained!");
      abnormalHrCount = 0;
    }

    history[histIndex] = { heartRate, spo2, bodyTemp, millis() };
    histIndex = (histIndex + 1) % HIST_SIZE;
    if (histCount < HIST_SIZE) histCount++;

    lastCalc = millis();
  }
}

void handle_JSON() {
  StaticJsonDocument<256> doc;
  doc["hr"]             = validHeartRate ? heartRate : 0;
  doc["spo2"]           = validSpO2      ? spo2      : 0;
  doc["bodyTemp"]       = String(bodyTemp, 1).toFloat();
  doc["status"]         = patientStatus;
  doc["statusLevel"]    = statusLevel;
  doc["fingerDetected"] = (bool)(validHeartRate && validSpO2);
  doc["uptime"]         = millis() / 1000;
  String out;
  serializeJson(doc, out);
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", out);
}

void handle_History() {
  StaticJsonDocument<2048> doc;
  JsonArray arr = doc.createNestedArray("readings");
  int start = (histCount < HIST_SIZE) ? 0 : histIndex;
  for (int i = 0; i < histCount; i++) {
    int idx = (start + i) % HIST_SIZE;
    JsonObject r = arr.createNestedObject();
    r["hr"]       = history[idx].hr;
    r["spo2"]     = history[idx].spo2;
    r["bodyTemp"] = history[idx].bodyTemp;
    r["ts"]       = history[idx].ts;
  }
  doc["count"] = histCount;
  String out;
  serializeJson(doc, out);
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", out);
}

void handle_Pulse() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "text/plain", String(pulseSignal));
}

void handle_BPM() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "text/plain", String(heartRate));
}

void handle_Vitals() {
  String csv = String(heartRate) + "," + String(spo2) + "," + String(bodyTemp, 1);
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "text/plain", csv);
}

void handle_Root() {
  String html = "<!DOCTYPE html><html><head>";
  html += "<meta charset='UTF-8'><meta name='viewport' content='width=device-width,initial-scale=1'>";
  html += "<title>VitalSense</title>";
  html += "<style>body{background:#060d14;color:#c8dae8;font-family:monospace;margin:0;padding:24px;}";
  html += "h1{color:#00e5ff;letter-spacing:3px;}.v{font-size:28px;font-weight:700;margin:8px 0;}";
  html += ".hr{color:#ff5252;}.sp{color:#ce93d8;}.bt{color:#ffcc02;}";
  html += ".tip{margin-top:24px;color:#4a6478;font-size:12px;}</style></head><body>";
  html += "<h1>VITALSENSE</h1>";
  html += "<p class='v hr'>HR: " + String(heartRate) + " BPM</p>";
  html += "<p class='v sp'>SpO2: " + String(spo2) + " %</p>";
  html += "<p class='v bt'>Temp: " + String(bodyTemp, 1) + " °C</p>";
  html += "<p>Status: " + patientStatus + "</p>";
  html += "<div class='tip'>Flutter app IP: <b style='color:#00e5ff'>" + WiFi.localIP().toString() + "</b></div>";
  html += "<script>setTimeout(()=>location.reload(),2000)</script></body></html>";
  server.send(200, "text/html", html);
}
