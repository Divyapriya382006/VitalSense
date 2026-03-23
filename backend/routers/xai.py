from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional
import numpy as np

router = APIRouter()


class XAIRequest(BaseModel):
    heart_rate: float
    spo2: float
    temperature: float
    systolic_bp: Optional[float] = 120
    diastolic_bp: Optional[float] = 80
    phi_score: Optional[float] = None


@router.post("/explain")
async def explain_vitals(req: XAIRequest):
    """
    XAI endpoint: explains which vitals are affecting the PHI score most.
    Uses rule-based attribution (SHAP-style weights) for hackathon demo.
    In production: use shap.TreeExplainer on the actual model.
    """
    contributions = {}
    flags = []

    # HR contribution
    hr = req.heart_rate
    if 60 <= hr <= 100:
        contributions["heart_rate"] = +25
        flags.append({"vital": "Heart Rate", "value": f"{int(hr)} BPM", "impact": "positive", "detail": "Within normal resting range"})
    elif 50 <= hr < 60 or 100 < hr <= 110:
        contributions["heart_rate"] = -10
        flags.append({"vital": "Heart Rate", "value": f"{int(hr)} BPM", "impact": "negative", "detail": "Slightly outside normal range"})
    else:
        contributions["heart_rate"] = -25
        flags.append({"vital": "Heart Rate", "value": f"{int(hr)} BPM", "impact": "critical", "detail": "Significantly abnormal — requires attention"})

    # SpO2 contribution
    spo2 = req.spo2
    if spo2 >= 95:
        contributions["spo2"] = +30
        flags.append({"vital": "SpO₂", "value": f"{int(spo2)}%", "impact": "positive", "detail": "Oxygen saturation is healthy"})
    elif spo2 >= 92:
        contributions["spo2"] = -15
        flags.append({"vital": "SpO₂", "value": f"{int(spo2)}%", "impact": "negative", "detail": "Slightly low — get some fresh air"})
    else:
        contributions["spo2"] = -30
        flags.append({"vital": "SpO₂", "value": f"{int(spo2)}%", "impact": "critical", "detail": "Critically low oxygen — seek help immediately"})

    # Temp contribution
    temp = req.temperature
    if 36.0 <= temp <= 37.5:
        contributions["temperature"] = +20
        flags.append({"vital": "Temperature", "value": f"{temp:.1f}°C", "impact": "positive", "detail": "Normal body temperature"})
    elif 37.5 < temp <= 38.5:
        contributions["temperature"] = -10
        flags.append({"vital": "Temperature", "value": f"{temp:.1f}°C", "impact": "negative", "detail": "Low-grade fever detected"})
    else:
        contributions["temperature"] = -20
        flags.append({"vital": "Temperature", "value": f"{temp:.1f}°C", "impact": "critical", "detail": "High fever or hypothermia — act now"})

    # BP contribution
    sys = req.systolic_bp or 120
    dia = req.diastolic_bp or 80
    if sys <= 130 and dia <= 85:
        contributions["blood_pressure"] = +15
        flags.append({"vital": "Blood Pressure", "value": f"{int(sys)}/{int(dia)} mmHg", "impact": "positive", "detail": "Blood pressure within healthy range"})
    elif sys <= 140:
        contributions["blood_pressure"] = -8
        flags.append({"vital": "Blood Pressure", "value": f"{int(sys)}/{int(dia)} mmHg", "impact": "negative", "detail": "Slightly elevated blood pressure"})
    else:
        contributions["blood_pressure"] = -15
        flags.append({"vital": "Blood Pressure", "value": f"{int(sys)}/{int(dia)} mmHg", "impact": "critical", "detail": "High blood pressure detected"})

    total_contribution = sum(contributions.values())
    base_score = 60
    computed_phi = max(0, min(100, base_score + total_contribution))

    # Sort by absolute impact
    flags.sort(key=lambda x: {"critical": 0, "negative": 1, "positive": 2}[x["impact"]])

    return {
        "phi_score": req.phi_score or computed_phi,
        "factor_contributions": contributions,
        "explanation_flags": flags,
        "dominant_factor": max(contributions, key=lambda k: abs(contributions[k])),
        "summary": _build_summary(flags, req.phi_score or computed_phi),
    }


def _build_summary(flags, phi):
    critical = [f for f in flags if f["impact"] == "critical"]
    negative = [f for f in flags if f["impact"] == "negative"]

    if critical:
        vitals_str = ", ".join([f["vital"] for f in critical])
        return f"⚠️ {vitals_str} {'is' if len(critical)==1 else 'are'} critically abnormal and pulling your PHI score down significantly. Immediate attention needed."
    elif negative:
        vitals_str = ", ".join([f["vital"] for f in negative])
        return f"Your {vitals_str} {'is' if len(negative)==1 else 'are'} slightly outside normal ranges. Monitor closely and follow recommendations."
    else:
        return f"All vitals are contributing positively to your PHI score of {phi:.0f}. Keep maintaining your healthy habits!"
