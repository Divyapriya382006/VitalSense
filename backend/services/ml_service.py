import numpy as np
from sklearn.ensemble import RandomForestClassifier, GradientBoostingRegressor
from sklearn.preprocessing import StandardScaler
import joblib
import os
from typing import Dict, Any, Optional
import math

MODEL_DIR = os.path.join(os.path.dirname(__file__), "..", "models", "saved")


class MLService:
    _instance = None
    _phi_model = None
    _condition_model = None
    _scaler = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._load_or_train_models()
        return cls._instance

    def _load_or_train_models(self):
        """Load pre-trained models or train from synthetic data."""
        os.makedirs(MODEL_DIR, exist_ok=True)
        phi_path = os.path.join(MODEL_DIR, "phi_model.pkl")
        scaler_path = os.path.join(MODEL_DIR, "scaler.pkl")
        cond_path = os.path.join(MODEL_DIR, "condition_model.pkl")

        if os.path.exists(phi_path):
            self._phi_model = joblib.load(phi_path)
            self._scaler = joblib.load(scaler_path)
            self._condition_model = joblib.load(cond_path)
        else:
            self._train_models()
            joblib.dump(self._phi_model, phi_path)
            joblib.dump(self._scaler, scaler_path)
            joblib.dump(self._condition_model, cond_path)

    def _train_models(self):
        """Train on synthetic physiologically valid data."""
        np.random.seed(42)
        n = 5000

        # Generate synthetic training data
        hr = np.random.normal(75, 15, n).clip(35, 180)
        spo2 = np.random.normal(97, 2, n).clip(80, 100)
        temp = np.random.normal(36.8, 0.5, n).clip(34, 41)
        systolic = np.random.normal(120, 15, n).clip(80, 200)
        diastolic = np.random.normal(80, 10, n).clip(50, 130)
        hrv = np.random.normal(50, 20, n).clip(5, 150)

        X = np.column_stack([hr, spo2, temp, systolic, diastolic, hrv])

        # PHI score: weighted multi-factor score
        phi_scores = self._compute_phi_from_features(hr, spo2, temp, systolic, diastolic, hrv)

        # Condition labels (0=normal, 1=tachycardia, 2=bradycardia, 3=hypoxia, 4=fever, 5=hypertension)
        conditions = np.zeros(n, dtype=int)
        conditions[hr > 100] = 1
        conditions[hr < 55] = 2
        conditions[spo2 < 93] = 3
        conditions[temp > 38.2] = 4
        conditions[systolic > 140] = 5

        self._scaler = StandardScaler()
        X_scaled = self._scaler.fit_transform(X)

        self._phi_model = GradientBoostingRegressor(n_estimators=100, max_depth=4, random_state=42)
        self._phi_model.fit(X_scaled, phi_scores)

        self._condition_model = RandomForestClassifier(n_estimators=100, random_state=42)
        self._condition_model.fit(X_scaled, conditions)

    def _compute_phi_from_features(self, hr, spo2, temp, sys_bp, dia_bp, hrv):
        """Physiologically grounded PHI calculation."""
        # HR score (peak at 65-85 BPM)
        hr_score = np.where(
            (hr >= 60) & (hr <= 100), 100,
            np.where((hr >= 50) & (hr < 60), 70,
            np.where((hr > 100) & (hr <= 110), 70,
            np.where((hr > 110) & (hr <= 130), 40, 10)))
        )

        # SpO2 score
        spo2_score = np.where(spo2 >= 95, 100,
                     np.where(spo2 >= 92, 70,
                     np.where(spo2 >= 88, 40, 10)))

        # Temp score
        temp_score = np.where(
            (temp >= 36.1) & (temp <= 37.5), 100,
            np.where((temp >= 35.5) & (temp < 36.1), 75,
            np.where((temp > 37.5) & (temp <= 38.5), 60,
            np.where((temp > 38.5) & (temp <= 39.5), 30, 5)))
        )

        # BP score
        bp_score = np.where(
            (sys_bp >= 90) & (sys_bp <= 130) & (dia_bp >= 60) & (dia_bp <= 85), 100,
            np.where((sys_bp <= 140) & (dia_bp <= 90), 75,
            np.where((sys_bp <= 160), 50, 20))
        )

        # HRV score (higher HRV = less stress = better)
        hrv_score = np.where(hrv >= 60, 100,
                    np.where(hrv >= 40, 80,
                    np.where(hrv >= 20, 55, 30)))

        # Weighted PHI
        phi = (
            hr_score * 0.25 +
            spo2_score * 0.30 +
            temp_score * 0.20 +
            bp_score * 0.15 +
            hrv_score * 0.10
        )
        return phi.clip(0, 100)

    def _extract_features(self, vitals: Dict) -> np.ndarray:
        hr = float(vitals.get("heart_rate", 72))
        spo2 = float(vitals.get("spo2", 98))
        temp = float(vitals.get("temperature", 36.8))
        sys_bp = float(vitals.get("systolic_bp", 120))
        dia_bp = float(vitals.get("diastolic_bp", 80))
        hrv_est = self.estimate_hrv(hr)
        return np.array([[hr, spo2, temp, sys_bp, dia_bp, hrv_est]])

    def calculate_phi(self, vitals: Dict) -> float:
        """Calculate Personal Health Index (0-100)."""
        try:
            X = self._extract_features(vitals)
            X_scaled = self._scaler.transform(X)
            phi = float(self._phi_model.predict(X_scaled)[0])
            return round(max(0, min(100, phi)), 1)
        except Exception as e:
            print(f"PHI calc error: {e}")
            return self._rule_based_phi(vitals)

    def _rule_based_phi(self, vitals: Dict) -> float:
        hr = float(vitals.get("heart_rate", 72))
        spo2 = float(vitals.get("spo2", 98))
        temp = float(vitals.get("temperature", 36.8))
        score = 100.0
        if not (60 <= hr <= 100): score -= 25
        if spo2 < 95: score -= 30
        if not (36.0 <= temp <= 37.5): score -= 20
        return max(0, round(score, 1))

    def estimate_hrv(self, heart_rate: float) -> float:
        """Estimate HRV from heart rate using RMSSD approximation."""
        rr_interval = 60000 / max(heart_rate, 1)  # ms
        # Natural HRV variation (simplified)
        variation = rr_interval * 0.04
        return round(variation + np.random.normal(0, 2), 1)

    def calculate_stress(self, hrv: float) -> float:
        """Calculate stress level from HRV (0-100, higher = more stress)."""
        if hrv >= 80: return 10.0
        if hrv >= 60: return 25.0
        if hrv >= 40: return 45.0
        if hrv >= 20: return 65.0
        return 85.0

    def predict_conditions(self, vitals: Dict) -> Dict:
        """Predict potential health conditions."""
        condition_names = {
            0: "Normal", 1: "Tachycardia", 2: "Bradycardia",
            3: "Hypoxia", 4: "Fever / Hyperthermia", 5: "Hypertension"
        }
        try:
            X = self._extract_features(vitals)
            X_scaled = self._scaler.transform(X)
            pred = int(self._condition_model.predict(X_scaled)[0])
            proba = self._condition_model.predict_proba(X_scaled)[0]
            
            return {
                "primary_condition": condition_names.get(pred, "Unknown"),
                "confidence": round(float(proba[pred]) * 100, 1),
                "all_probabilities": {
                    condition_names[i]: round(float(p) * 100, 1)
                    for i, p in enumerate(proba)
                },
            }
        except Exception as e:
            return {"primary_condition": "Unable to predict", "confidence": 0, "error": str(e)}

    def explain_prediction(self, vitals: Dict, phi: float) -> Dict:
        """XAI — explain why the PHI score is what it is."""
        hr = float(vitals.get("heart_rate", 72))
        spo2 = float(vitals.get("spo2", 98))
        temp = float(vitals.get("temperature", 36.8))
        factors = []
        recommendations = []

        if hr > 110:
            factors.append(f"Heart rate is elevated at {int(hr)} BPM (normal: 60–100)")
            recommendations.append("Rest, avoid caffeine, and practice deep breathing")
        elif hr < 50:
            factors.append(f"Heart rate is low at {int(hr)} BPM")
            recommendations.append("Stay hydrated and avoid prolonged inactivity")
        else:
            factors.append(f"Heart rate is within normal range at {int(hr)} BPM ✓")

        if spo2 < 90:
            factors.append(f"SpO₂ is critically low at {int(spo2)}% (normal: ≥95%)")
            recommendations.append("Move to fresh air immediately. Seek emergency help.")
        elif spo2 < 95:
            factors.append(f"SpO₂ is below normal at {int(spo2)}%")
            recommendations.append("Take slow deep breaths and get fresh air")
        else:
            factors.append(f"SpO₂ is healthy at {int(spo2)}% ✓")

        if temp > 38.5:
            factors.append(f"Temperature is elevated at {temp:.1f}°C (fever)")
            recommendations.append("Stay hydrated and consider taking a fever reducer")
        elif temp < 36.0:
            factors.append(f"Temperature is low at {temp:.1f}°C")
            recommendations.append("Warm up gradually, stay indoors")
        else:
            factors.append(f"Temperature is normal at {temp:.1f}°C ✓")

        summary = (
            f"Your PHI score is {phi:.0f}/100. "
            + ("Your vitals look great overall." if phi >= 75 
               else "Some vitals need attention." if phi >= 50 
               else "Several vitals are concerning. Please seek medical advice.")
        )

        return {
            "summary": summary,
            "factors": factors,
            "recommendations": recommendations,
            "phi": phi,
        }

    def analyze_trend(self, readings: list) -> Dict:
        """Analyze trends over a list of readings."""
        if len(readings) < 2:
            return {"trend": "insufficient_data"}

        hrs = [r.get("heart_rate", 0) for r in readings]
        spo2s = [r.get("spo2", 0) for r in readings]
        temps = [r.get("temperature", 0) for r in readings]
        phis = [r.get("phi_score", 0) for r in readings]

        def trend_dir(values):
            if len(values) < 2: return "stable"
            slope = (values[-1] - values[0]) / len(values)
            if slope > 0.5: return "increasing"
            if slope < -0.5: return "decreasing"
            return "stable"

        return {
            "heart_rate_trend": trend_dir(hrs),
            "spo2_trend": trend_dir(spo2s),
            "temperature_trend": trend_dir(temps),
            "phi_trend": trend_dir(phis),
            "avg_phi": round(sum(phis) / len(phis), 1),
            "avg_hr": round(sum(hrs) / len(hrs), 1),
            "avg_spo2": round(sum(spo2s) / len(spo2s), 1),
        }
