from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import asyncio
import json
import uvicorn
from contextlib import asynccontextmanager
from routers import vitals, predict, xai, reports, hospitals, users
from services.connection_manager import ConnectionManager

manager = ConnectionManager()

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("🚀 VitalSense Backend Starting...")
    yield
    print("🛑 VitalSense Backend Shutting down...")

app = FastAPI(
    title="VitalSense API",
    description="AI-Based Vital Analysis & Health Prediction System",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(vitals.router, prefix="/vitals", tags=["Vitals"])
app.include_router(predict.router, prefix="/predict", tags=["Prediction"])
app.include_router(xai.router, prefix="/xai", tags=["Explainability"])
app.include_router(reports.router, prefix="/reports", tags=["Reports"])
app.include_router(hospitals.router, prefix="/hospitals", tags=["Hospitals"])
app.include_router(users.router, prefix="/users", tags=["Users"])


@app.get("/")
async def root():
    return {"status": "VitalSense API running", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.websocket("/ws/vitals/{user_id}")
async def websocket_vitals(websocket: WebSocket, user_id: str):
    """
    Real-time vitals WebSocket endpoint.
    Receives vitals from hardware/rPPG and broadcasts to connected clients (doctors).
    """
    await manager.connect(websocket, user_id)
    try:
        while True:
            # Receive data from sensor/app
            raw = await websocket.receive_text()
            data = json.loads(raw)

            msg_type = data.get("type", "vitals")

            if msg_type in ("vitals", "rppg", "manual_input"):
                # Run ML prediction
                from services.ml_service import MLService
                ml = MLService()

                vitals_data = {
                    "heart_rate": data.get("heartRate", data.get("heart_rate", 72)),
                    "spo2": data.get("spo2", 98),
                    "temperature": data.get("temperature", 36.8),
                    "ecg_value": data.get("ecgValue", data.get("ecg_value", 0)),
                    "systolic_bp": data.get("systolicBP", 120),
                    "diastolic_bp": data.get("diastolicBP", 80),
                    "user_id": user_id,
                    "source": msg_type,
                }

                # Calculate PHI and HRV
                phi = ml.calculate_phi(vitals_data)
                hrv = ml.estimate_hrv(vitals_data["heart_rate"])
                stress = ml.calculate_stress(hrv)
                xai_explanation = ml.explain_prediction(vitals_data, phi)

                enriched = {
                    **vitals_data,
                    "phiScore": phi,
                    "hrv": hrv,
                    "stressLevel": stress,
                    "xaiExplanation": xai_explanation,
                    "timestamp": data.get("timestamp"),
                    "id": data.get("id", f"{user_id}_{asyncio.get_event_loop().time()}"),
                    "isSynced": True,
                }

                # Send back to patient
                await manager.send_personal(json.dumps(enriched), websocket)

                # Broadcast to doctor if critical
                if phi < 50 or enriched.get("heartRate", 72) > 120:
                    await manager.broadcast_to_doctors(
                        json.dumps({"type": "patient_alert", "userId": user_id, "vitals": enriched})
                    )

    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)
    except Exception as e:
        print(f"WS error for {user_id}: {e}")
        manager.disconnect(websocket, user_id)


@app.websocket("/ws/doctor/{doctor_id}")
async def websocket_doctor(websocket: WebSocket, doctor_id: str):
    """Doctor war room WebSocket — receives alerts from all patients."""
    await manager.connect_doctor(websocket, doctor_id)
    try:
        while True:
            await websocket.receive_text()  # Keep alive
    except WebSocketDisconnect:
        manager.disconnect_doctor(websocket, doctor_id)


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
