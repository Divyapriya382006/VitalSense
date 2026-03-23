from fastapi import APIRouter, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import Optional
import re

router = APIRouter()


def extract_vitals_from_text(text: str) -> dict:
    """Extract vital values from medical report text using regex."""
    text_lower = text.lower()
    result = {}

    # Heart rate patterns
    hr_patterns = [
        r'heart rate[:\s]+(\d+)', r'pulse[:\s]+(\d+)',
        r'hr[:\s]+(\d+)', r'(\d+)\s*bpm'
    ]
    for p in hr_patterns:
        m = re.search(p, text_lower)
        if m:
            result["heart_rate"] = int(m.group(1))
            break

    # SpO2 patterns
    spo2_patterns = [
        r'spo2[:\s]+(\d+)', r'oxygen saturation[:\s]+(\d+)',
        r'o2 sat[:\s]+(\d+)', r'spO2[:\s]+(\d+)%?'
    ]
    for p in spo2_patterns:
        m = re.search(p, text_lower)
        if m:
            result["spo2"] = float(m.group(1))
            break

    # Temperature
    temp_patterns = [
        r'temperature[:\s]+([\d.]+)', r'temp[:\s]+([\d.]+)',
        r'([\d.]+)\s*°c', r'([\d.]+)\s*celsius'
    ]
    for p in temp_patterns:
        m = re.search(p, text_lower)
        if m:
            val = float(m.group(1))
            # Convert F to C if needed
            if val > 45:
                val = (val - 32) * 5 / 9
            result["temperature"] = round(val, 1)
            break

    # Blood pressure
    bp_m = re.search(r'(\d+)\s*/\s*(\d+)\s*mmhg', text_lower)
    if bp_m:
        result["systolic_bp"] = int(bp_m.group(1))
        result["diastolic_bp"] = int(bp_m.group(2))

    # Cholesterol
    chol_m = re.search(r'cholesterol[:\s]+([\d.]+)', text_lower)
    if chol_m:
        result["cholesterol"] = float(chol_m.group(1))

    # Blood sugar / glucose
    glucose_m = re.search(r'(?:glucose|blood sugar|fasting)[:\s]+([\d.]+)', text_lower)
    if glucose_m:
        result["blood_glucose"] = float(glucose_m.group(1))

    return result


def analyze_report_values(extracted: dict) -> dict:
    """Analyze extracted values and generate findings."""
    findings = []
    risk_level = "normal"

    hr = extracted.get("heart_rate")
    if hr:
        if hr > 100:
            findings.append({"parameter": "Heart Rate", "value": f"{hr} BPM", "status": "high", "note": "Tachycardia detected"})
            risk_level = "elevated"
        elif hr < 60:
            findings.append({"parameter": "Heart Rate", "value": f"{hr} BPM", "status": "low", "note": "Bradycardia detected"})
        else:
            findings.append({"parameter": "Heart Rate", "value": f"{hr} BPM", "status": "normal", "note": "Within normal range"})

    spo2 = extracted.get("spo2")
    if spo2:
        if spo2 < 90:
            findings.append({"parameter": "SpO₂", "value": f"{int(spo2)}%", "status": "critical", "note": "Critical hypoxia"})
            risk_level = "critical"
        elif spo2 < 95:
            findings.append({"parameter": "SpO₂", "value": f"{int(spo2)}%", "status": "low", "note": "Below normal oxygen saturation"})
            if risk_level == "normal": risk_level = "elevated"
        else:
            findings.append({"parameter": "SpO₂", "value": f"{int(spo2)}%", "status": "normal", "note": "Normal oxygen saturation"})

    sys_bp = extracted.get("systolic_bp")
    dia_bp = extracted.get("diastolic_bp")
    if sys_bp and dia_bp:
        if sys_bp > 140 or dia_bp > 90:
            findings.append({"parameter": "Blood Pressure", "value": f"{sys_bp}/{dia_bp} mmHg", "status": "high", "note": "Hypertension detected"})
            if risk_level == "normal": risk_level = "elevated"
        elif sys_bp < 90 or dia_bp < 60:
            findings.append({"parameter": "Blood Pressure", "value": f"{sys_bp}/{dia_bp} mmHg", "status": "low", "note": "Hypotension detected"})
        else:
            findings.append({"parameter": "Blood Pressure", "value": f"{sys_bp}/{dia_bp} mmHg", "status": "normal", "note": "Normal blood pressure"})

    glucose = extracted.get("blood_glucose")
    if glucose:
        if glucose > 126:
            findings.append({"parameter": "Blood Glucose", "value": f"{glucose} mg/dL", "status": "high", "note": "Possible diabetes range — consult doctor"})
            if risk_level == "normal": risk_level = "elevated"
        elif glucose > 100:
            findings.append({"parameter": "Blood Glucose", "value": f"{glucose} mg/dL", "status": "borderline", "note": "Pre-diabetic range"})
        else:
            findings.append({"parameter": "Blood Glucose", "value": f"{glucose} mg/dL", "status": "normal", "note": "Normal fasting glucose"})

    summary = (
        "All detected parameters are within normal ranges. Continue regular monitoring."
        if risk_level == "normal"
        else "Some parameters are outside normal ranges. Please consult your healthcare provider."
        if risk_level == "elevated"
        else "Critical values detected. Seek immediate medical attention."
    )

    return {
        "extracted_values": extracted,
        "findings": findings,
        "overall_risk": risk_level,
        "summary": summary,
        "disclaimer": "This analysis is AI-generated for informational purposes only. Always consult a qualified medical professional."
    }


@router.post("/analyze")
async def analyze_medical_report(file: Optional[UploadFile] = File(None)):
    """Analyze uploaded medical report (PDF/image text)."""
    if not file:
        raise HTTPException(status_code=400, detail="No file uploaded")

    content = await file.read()

    # Try to extract text
    text = ""
    if file.content_type == "application/pdf":
        try:
            import pdfplumber
            import io
            with pdfplumber.open(io.BytesIO(content)) as pdf:
                for page in pdf.pages:
                    text += page.extract_text() or ""
        except ImportError:
            # Fallback: treat as plain text
            text = content.decode("utf-8", errors="ignore")
    else:
        text = content.decode("utf-8", errors="ignore")

    if not text.strip():
        raise HTTPException(status_code=422, detail="Could not extract text from the uploaded file")

    extracted = extract_vitals_from_text(text)
    analysis = analyze_report_values(extracted)

    return {
        "filename": file.filename,
        "text_length": len(text),
        **analysis,
    }


@router.post("/analyze-text")
async def analyze_report_text(payload: dict):
    """Analyze medical report from raw text input."""
    text = payload.get("text", "")
    if not text:
        raise HTTPException(status_code=400, detail="No text provided")

    extracted = extract_vitals_from_text(text)
    analysis = analyze_report_values(extracted)
    return analysis
