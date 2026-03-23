from fastapi import WebSocket
from typing import Dict, List


class ConnectionManager:
    def __init__(self):
        # patient_id -> list of WebSocket connections
        self.active_patients: Dict[str, List[WebSocket]] = {}
        # doctor_id -> WebSocket
        self.active_doctors: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        if user_id not in self.active_patients:
            self.active_patients[user_id] = []
        self.active_patients[user_id].append(websocket)
        print(f"✅ Patient {user_id} connected. Total: {len(self.active_patients)}")

    def disconnect(self, websocket: WebSocket, user_id: str):
        if user_id in self.active_patients:
            self.active_patients[user_id].remove(websocket)
            if not self.active_patients[user_id]:
                del self.active_patients[user_id]
        print(f"❌ Patient {user_id} disconnected.")

    async def connect_doctor(self, websocket: WebSocket, doctor_id: str):
        await websocket.accept()
        self.active_doctors[doctor_id] = websocket
        print(f"🏥 Doctor {doctor_id} connected to war room.")

    def disconnect_doctor(self, websocket: WebSocket, doctor_id: str):
        if doctor_id in self.active_doctors:
            del self.active_doctors[doctor_id]

    async def send_personal(self, message: str, websocket: WebSocket):
        try:
            await websocket.send_text(message)
        except Exception:
            pass

    async def broadcast_to_doctors(self, message: str):
        disconnected = []
        for doc_id, ws in self.active_doctors.items():
            try:
                await ws.send_text(message)
            except Exception:
                disconnected.append(doc_id)
        for doc_id in disconnected:
            del self.active_doctors[doc_id]

    async def send_to_patient(self, user_id: str, message: str):
        if user_id in self.active_patients:
            for ws in self.active_patients[user_id]:
                try:
                    await ws.send_text(message)
                except Exception:
                    pass

    def get_online_patients(self) -> List[str]:
        return list(self.active_patients.keys())
