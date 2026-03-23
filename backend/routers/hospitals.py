from fastapi import APIRouter, HTTPException
import httpx
import os

router = APIRouter()

GOOGLE_MAPS_KEY = os.getenv("GOOGLE_MAPS_KEY", "YOUR_GOOGLE_MAPS_KEY")


@router.get("/nearby")
async def get_nearby_hospitals(lat: float, lng: float, radius: int = 5000):
    """Get nearby hospitals using Google Places API."""
    url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    params = {
        "location": f"{lat},{lng}",
        "radius": radius,
        "type": "hospital",
        "key": GOOGLE_MAPS_KEY,
    }

    async with httpx.AsyncClient() as client:
        response = await client.get(url, params=params)

    if response.status_code != 200:
        raise HTTPException(status_code=502, detail="Google Maps API error")

    data = response.json()
    results = data.get("results", [])

    hospitals = []
    for place in results[:10]:
        geometry = place.get("geometry", {}).get("location", {})
        hospitals.append({
            "name": place.get("name"),
            "address": place.get("vicinity"),
            "lat": geometry.get("lat"),
            "lng": geometry.get("lng"),
            "rating": place.get("rating"),
            "open_now": place.get("opening_hours", {}).get("open_now"),
            "place_id": place.get("place_id"),
        })

    return {"hospitals": hospitals, "count": len(hospitals)}
