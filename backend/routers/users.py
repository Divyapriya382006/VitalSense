from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List

router = APIRouter()


class UserProfilePayload(BaseModel):
    uid: str
    name: str
    email: str
    role: str
    age: Optional[int] = None
    blood_group: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    is_gym_person: Optional[bool] = False
    is_athletic: Optional[bool] = False
    is_female: Optional[bool] = False
    emergency_contacts: Optional[List[str]] = []


@router.get("/{uid}")
async def get_user(uid: str):
    """Get user profile (use Firebase directly from Flutter for auth'd calls)."""
    return {"uid": uid, "message": "Query Firebase Firestore directly from Flutter client"}


@router.post("/notify-emergency")
async def notify_emergency(payload: dict):
    """Notify emergency contacts via SMS (integrate with Twilio in production)."""
    user_id = payload.get("user_id")
    contacts = payload.get("contacts", [])
    message = payload.get("message", "Emergency health alert from VitalSense")

    # TODO: Integrate Twilio SMS here
    # from twilio.rest import Client
    # client = Client(TWILIO_SID, TWILIO_TOKEN)
    # for contact in contacts:
    #     client.messages.create(body=message, from_='+1234567890', to=contact)

    return {
        "status": "notified",
        "contacts_alerted": len(contacts),
        "message": f"Emergency notification sent to {len(contacts)} contacts (Twilio integration pending)",
    }


@router.get("/doctors/list")
async def list_doctors():
    """List all registered doctors (query Firebase directly in production)."""
    return {"doctors": [], "message": "Query Firebase Firestore with role='doctor' filter"}
