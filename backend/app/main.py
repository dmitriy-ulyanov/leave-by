from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select
from sqlalchemy.orm import Session

from .auth import current_user
from .auth import router as auth_router
from .db import Base, engine, get_session
from .models import Trip, User
from .schemas import TripIn, TripOut


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(engine)
    yield


app = FastAPI(title="Leave By API", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
app.include_router(auth_router)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/api/trips", response_model=list[TripOut])
def list_trips(user: User = Depends(current_user), session: Session = Depends(get_session)):
    query = select(Trip).where(Trip.user_id == user.id).order_by(Trip.created_at.desc(), Trip.id)
    return session.scalars(query).all()


@app.get("/api/trips/{trip_id}", response_model=TripOut)
def get_trip(trip_id: str, user: User = Depends(current_user), session: Session = Depends(get_session)):
    trip = session.get(Trip, (user.id, trip_id))
    if trip is None:
        raise HTTPException(status_code=404, detail="Perjalanan tidak ditemukan")
    return trip


@app.put("/api/trips/{trip_id}", response_model=TripOut)
def upsert_trip(
    trip_id: str,
    payload: TripIn,
    user: User = Depends(current_user),
    session: Session = Depends(get_session),
):
    if payload.id != trip_id:
        raise HTTPException(status_code=400, detail="Id pada path dan body harus sama")
    data = payload.model_dump()
    trip = session.get(Trip, (user.id, trip_id))
    if trip is None:
        trip = Trip(user_id=user.id, **data)
        session.add(trip)
    else:
        for key, value in data.items():
            setattr(trip, key, value)
    session.commit()
    return trip


@app.delete("/api/trips/{trip_id}", status_code=204)
def delete_trip(trip_id: str, user: User = Depends(current_user), session: Session = Depends(get_session)):
    trip = session.get(Trip, (user.id, trip_id))
    if trip is None:
        raise HTTPException(status_code=404, detail="Perjalanan tidak ditemukan")
    session.delete(trip)
    session.commit()
    return Response(status_code=204)
