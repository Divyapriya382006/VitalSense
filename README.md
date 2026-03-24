# 🩺 VitalSense

**VitalSense** is an AI-powered, real-time health monitoring platform built using Flutter, designed to provide continuous vital tracking, intelligent insights, and emergency response capabilities.

It integrates hardware sensors, camera-based measurement (RPPG), AI/ML analysis, and real-time communication systems to deliver a comprehensive digital healthcare experience.

🌐 **Available on:** Android | iOS | Web

---

## 🚀 Features

### 🔐 Authentication & User Management
- Secure email/password login & registration
- Role-Based Access Control (RBAC):
  - **Admin**: Manage doctors & patients
  - **Doctor**: Monitor and manage assigned patients
  - **Patient**: Personal health tracking
- Demo accounts for testing
- Profile creation and management

---

### 👋 Onboarding
- Interactive app walkthrough
- Splash screen with initialization logic

---

### ❤️ Health Vitals Monitoring
- Real-time health dashboard
- ECG visualization with animated UI
- Tracks:
  - Heart Rate (BPM)
  - SpO₂ (Oxygen Saturation)
  - Body Temperature
  - Blood Pressure (Systolic/Diastolic)
  - Heart Rate Variability (HRV)
- **PHI Score (Personal Health Index)** with AI recommendations
- Real-time and demo modes

---

### 📱 Camera-Based Measurement (RPPG)
- Contactless heart rate detection via camera
- 30-second scan with live feedback
- Pulse waveform visualization
- Voice-guided instructions

---

### 🔌 Hardware Integration
- Real-time telemetry from wearable devices
- IP-based device connectivity
- Bluetooth Mesh networking support
- Connection status monitoring
- Local caching (last 30 readings)

---

### 📊 Analytics & Reports
- Historical health data tracking
- Filter by **specific date**
- Generate and export reports (PDF)
- Share health data securely
- **Yearly Heatmap Visualization**:
  - Displays critical health patterns similar to GitHub/LeetCode heatmaps

---

### 🤖 AI Health Assistant
- Conversational chatbot interface
- Voice-enabled interaction
- Personalized insights based on vitals

---

### ⚠️ Alerts & Emergency System
- Real-time alerts (warning & critical levels)
- Custom alert thresholds
- SOS emergency button
- Additional emergency button for external crises
- Emergency contact notification system
- Alert history tracking

---

### 🏥 Doctor & Hospital Integration
- Doctor dashboard for patient monitoring
- Multi-patient “War Room” view
- Assign patients to doctors
- Admin-visible doctor registry
- Nearby hospital locator (map-based)

---

### 👤 Profile Management
- Comprehensive user profile:
  - Age, DOB
  - Height, Weight
  - Blood Group
  - Allergies
  - Phone Number
  - Location/Area
- Emergency contacts setup (auto-alert on critical levels)
- Doctor selection & assignment (visible to admin)

---

### 📂 Medical Report Analysis (AI/ML)
- Upload medical reports (any format)
- AI/ML-based report analysis
- Automatic extraction of key insights
- Visualization using:
  - Graphs
  - Statistics
  - Dashboards
- Dedicated navigation section

---

### 🧠 Advanced Biometric Analysis
- Face Mesh using MediaPipe
- Facial landmark tracking
- Fatigue detection
- Stress analysis
- Hydration estimation

---

### 🩺 Women’s Health
- Menstrual cycle tracking
- Period prediction
- Medication reminders

---

### 🏋️ Wellness & Lifestyle
- Wellness scoring system
- Personalized health recommendations
- Fitness tracking

---

### ⚙️ Admin Panel
- Manage patients and doctors
- System monitoring and control
- Access to all registered users

---

### 🌐 Real-Time Data System
- API-key-less WebSocket integration
- Instant updates without refresh
- Live synchronization across devices

---

### 💾 Data Persistence & Offline Support
- Local storage using Hive
- Offline mode with caching
- Sync status tracking

---

### 🎨 UI/UX
- Dark mode / Light mode toggle
- Responsive UI design
- Animated dashboards and cards
- Centralized design system

---

## 🏗️ Architecture

Frontend: Flutter (Riverpod, GoRouter)  
Backend: Firebase + FastAPI  
Real-time: WebSockets  
AI/ML: Custom Models + MediaPipe  
Storage: Hive (local) + Cloud sync  
Networking: Bluetooth Mesh + IP devices  

---

## 📁 Project Structure

lib/  
├── models/  
├── providers/  
├── services/  
├── widgets/  
├── screens/  
│   ├── auth/  
│   ├── home/  
│   ├── vitals/  
│   ├── reports/  
│   ├── alerts/  
│   ├── ai_chat/  
│   ├── doctor/  
│   ├── admin/  
│   ├── wellness/  
│   ├── maps/  
│   ├── period_tracker/  
│   ├── profile/  
│   ├── face_mesh/  
│   ├── rppg/  
│   └── onboarding/  
└── main.dart  

---

## 🔧 Tech Stack

- Flutter  
- Riverpod  
- Go Router  
- Firebase  
- FastAPI  
- WebSockets  
- MediaPipe  
- Hive  
- Bluetooth Mesh
