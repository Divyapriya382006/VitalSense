from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from services.ml_service import MLService

router = APIRouter()
ml = MLService()


class VitalsInput(BaseModel):
    heart_rate: float
    spo2: float
    temperature: float
    ecg_value: Optional[float] = None
    systolic_bp: Optional[float] = 120
    diastolic_bp: Optional[float] = 80
    user_id: Optional[str] = None


class TrendInput(BaseModel):
    readings: List[dict]


@router.post("/phi")
async def predict_phi(vitals: VitalsInput):
    """Calculate PHI (Personal Health Index) score."""
    data = vitals.dict()
    phi = ml.calculate_phi(data)
    hrv = ml.estimate_hrv(vitals.heart_rate)
    stress = ml.calculate_stress(hrv)
    xai = ml.explain_prediction(data, phi)

    return {
        "phi_score": phi,
        "hrv": hrv,
        "stress_level": stress,
        "explanation": xai,
        "status": "excellent" if phi >= 85 else "good" if phi >= 70 else "fair" if phi >= 50 else "poor",
    }


@router.post("/conditions")
async def predict_conditions(vitals: VitalsInput):
    """Predict potential health conditions."""
    result = ml.predict_conditions(vitals.dict())
    return result


@router.post("/trend")
async def analyze_trend(data: TrendInput):
    """Analyze vital trends over time."""
    result = ml.analyze_trend(data.readings)
    return result


@router.post("/full")
async def full_prediction(vitals: VitalsInput):
    """Full prediction: PHI + conditions + XAI in one call."""
    data = vitals.dict()
    phi = ml.calculate_phi(data)
    hrv = ml.estimate_hrv(vitals.heart_rate)
    stress = ml.calculate_stress(hrv)
    conditions = ml.predict_conditions(data)
    xai = ml.explain_prediction(data, phi)

    # Determine alert level
    alert_level = "none"
    if phi < 40 or vitals.spo2 < 90 or vitals.heart_rate > 140 or vitals.heart_rate < 40:
        alert_level = "critical"
    elif phi < 60 or vitals.spo2 < 94 or vitals.heart_rate > 110:
        alert_level = "warning"
    elif phi < 75:
        alert_level = "caution"

    return {
        "phi_score": phi,
        "hrv": hrv,
        "stress_level": stress,
        "conditions": conditions,
        "explanation": xai,
        "alert_level": alert_level,
        "recommendations": xai.get("recommendations", []),
    }
