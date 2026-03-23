# VitalSense — Complete Setup & Run Guide
# Hackathon Edition 🚀

## 🗂️ Project Structure
```
vitalsense/
├── flutter_app/          ← Flutter frontend
│   └── lib/
│       ├── main.dart
│       ├── theme/
│       ├── models/
│       ├── screens/
│       ├── widgets/
│       ├── services/
│       └── providers/
└── backend/              ← FastAPI + ML backend
    ├── main.py
    ├── routers/
    ├── services/
    └── requirements.txt
```

---

## ⚙️ BACKEND SETUP (Person 1)

```bash
cd vitalsense/backend

# Create virtual environment
python -m venv venv
source venv/bin/activate        # Mac/Linux
# venv\Scripts\activate         # Windows

# Install dependencies
pip install -r requirements.txt

# Create .env file
echo "GOOGLE_MAPS_KEY=YOUR_KEY_HERE" > .env

# Start server
python main.py
# → Runs at http://0.0.0.0:8000
# → WebSocket at ws://YOUR_IP:8000/ws/vitals/{user_id}
```

**Get your local IP:**
```bash
# Mac/Linux:
ifconfig | grep "inet " | grep -v 127.0.0.1
# Windows:
ipconfig | findstr "IPv4"
```

---

## 📱 FLUTTER SETUP (Person 2)

### 1. Replace placeholders in code:
```
In websocket_service.dart:
  'YOUR_SERVER_IP' → your laptop's actual IP (e.g., 192.168.1.5)

In ai_chat_screen.dart:
  'YOUR_CLAUDE_API_KEY' → your Anthropic API key

In android/app/src/main/AndroidManifest.xml:
  Add: <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_GOOGLE_MAPS_KEY"/>
```

### 2. Firebase setup:
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli
flutterfire configure   # select your Firebase project
```

### 3. Android permissions in AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

### 4. Run the app:
```bash
cd vitalsense/flutter_app
flutter pub get
flutter run
```

---

## 🔥 Firebase Firestore Rules (paste in Firebase Console):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;  // doctors can read patients
    }
    match /vitals/{docId} {
      allow read, write: if request.auth != null;
    }
    match /alerts/{docId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 🧪 Testing the API (in browser or Postman):
```
GET  http://localhost:8000/             → Health check
POST http://localhost:8000/predict/phi  → PHI score
POST http://localhost:8000/predict/full → Full analysis
POST http://localhost:8000/xai/explain  → XAI explanation
POST http://localhost:8000/reports/analyze-text → Report analysis
GET  http://localhost:8000/hospitals/nearby?lat=13.0827&lng=80.2707 → Hospitals

WebSocket test:
ws://localhost:8000/ws/vitals/test_user_123
Send: {"type":"vitals","heartRate":88,"spo2":97,"temperature":36.8}
```

---

## 📊 Feature Demo Flow (for judges):
1. Open app → Splash screen with ECG animation
2. Sign up → Profile setup (shows BMI auto-calc, period tracker for female)
3. Home dashboard → PHI score gauge, 4 vital cards
4. Face Scan (rPPG) → Start scan, 30 second countdown, shows live BPM
5. AI Chat → Type or hold mic → Claude responds with voice
6. Hold SOS button → Bluetooth mesh alert + voice narration
7. Doctor War Room → All patients color-coded
8. Generate PDF → Share report
9. Alerts page → XAI explanation for each alert

---

## 🏆 Key Differentiators to Highlight:
- ✅ Real rPPG face scan (no hardware needed for demo)
- ✅ XAI explains WHY each alert was triggered
- ✅ PHI Score — single holistic metric
- ✅ STT + TTS — fully accessible for disabled users
- ✅ Bluetooth mesh SOS (works without internet!)
- ✅ Offline mode — cached vitals when no connection
- ✅ Doctor War Room — real-time multi-patient view
- ✅ Period tracker with cycle phase visualization
- ✅ Background notifications with WorkManager
