from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select
from sqlalchemy.orm import Session

from .db import Base, engine, get_session
from .models import Trip
from .schemas import TripIn, TripOut


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(engine)
    yield


app = FastAPI(title="Leave By API", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/api/trips", response_model=list[TripOut])
def list_trips(session: Session = Depends(get_session)):
    return session.scalars(select(Trip).order_by(Trip.created_at.desc(), Trip.id)).all()


@app.get("/api/trips/{trip_id}", response_model=TripOut)
def get_trip(trip_id: str, session: Session = Depends(get_session)):
    trip = session.get(Trip, trip_id)
    if trip is None:
        raise HTTPException(status_code=404, detail="Perjalanan tidak ditemukan")
    return trip


@app.put("/api/trips/{trip_id}", response_model=TripOut)
def upsert_trip(trip_id: str, payload: TripIn, session: Session = Depends(get_session)):
    if payload.id != trip_id:
        raise HTTPException(status_code=400, detail="Id pada path dan body harus sama")
    data = payload.model_dump()
    trip = session.get(Trip, trip_id)
    if trip is None:
        trip = Trip(**data)
        session.add(trip)
    else:
        for key, value in data.items():
            setattr(trip, key, value)
    session.commit()
    return trip


@app.delete("/api/trips/{trip_id}", status_code=204)
def delete_trip(trip_id: str, session: Session = Depends(get_session)):
    trip = session.get(Trip, trip_id)
    if trip is None:
        raise HTTPException(status_code=404, detail="Perjalanan tidak ditemukan")
    session.delete(trip)
    session.commit()
    return Response(status_code=204)
