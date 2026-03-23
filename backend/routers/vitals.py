from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

router = APIRouter()


class VitalPayload(BaseModel):
    user_id: str
    heart_rate: float
    spo2: float
    temperature: float
    ecg_value: Optional[float] = None
    systolic_bp: Optional[float] = 120
    diastolic_bp: Optional[float] = 80
    source: Optional[str] = "sensor"
    timestamp: Optional[str] = None


@router.post("/record")
async def record_vital(payload: VitalPayload):
    """Record a vital reading (REST fallback if WebSocket not available)."""
    from services.ml_service import MLService
    ml = MLService()
    data = payload.dict()
    phi = ml.calculate_phi(data)
    hrv = ml.estimate_hrv(payload.heart_rate)
    stress = ml.calculate_stress(hrv)
    xai = ml.explain_prediction(data, phi)

    return {
        "status": "recorded",
        "phi_score": phi,
        "hrv": hrv,
        "stress_level": stress,
        "explanation": xai,
        "timestamp": payload.timestamp or datetime.utcnow().isoformat(),
    }


@router.get("/history/{user_id}")
async def get_vital_history(user_id: str, limit: int = 50):
    """Get vital history for a user (from Firebase via backend)."""
    # In production: query Firebase Admin SDK
    return {"user_id": user_id, "readings": [], "message": "Query Firebase directly from Flutter for real-time data"}


@router.get("/summary/{user_id}")
async def get_vital_summary(user_id: str):
    """Get summary stats for a user."""
    return {
        "user_id": user_id,
        "message": "Use Firebase Firestore directly for real-time summary data",
    }
