from typing import Optional

import jwt
from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .db import get_session
from .models import User
from .schemas import AuthOut, LoginIn, RegisterIn, UserOut
from .security import DUMMY_HASH, create_token, decode_token, hash_password, verify_password

router = APIRouter(prefix="/api/auth", tags=["auth"])


def current_user(
    authorization: Optional[str] = Header(default=None),
    session: Session = Depends(get_session),
) -> User:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(status_code=401, detail="Belum masuk. Silakan masuk terlebih dahulu.")
    token = authorization[7:].strip()
    try:
        payload = decode_token(token)
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Sesi tidak valid atau sudah berakhir.")
    user = session.get(User, payload["sub"])
    if user is None:
        raise HTTPException(status_code=401, detail="Sesi tidak valid atau sudah berakhir.")
    return user


@router.post("/register", response_model=AuthOut, status_code=201)
def register(payload: RegisterIn, session: Session = Depends(get_session)):
    if session.scalar(select(User).where(User.email == payload.email)) is not None:
        raise HTTPException(status_code=409, detail="Email sudah terdaftar")
    user = User(email=payload.email, name=payload.name, password_hash=hash_password(payload.password))
    session.add(user)
    try:
        session.commit()
    except IntegrityError:
        session.rollback()
        raise HTTPException(status_code=409, detail="Email sudah terdaftar")
    return AuthOut(token=create_token(user.id), user=UserOut.model_validate(user))


@router.post("/login", response_model=AuthOut)
def login(payload: LoginIn, session: Session = Depends(get_session)):
    user = session.scalar(select(User).where(User.email == payload.email.strip().lower()))
    stored_hash = user.password_hash if user is not None else DUMMY_HASH
    password_ok = verify_password(payload.password, stored_hash)
    if user is None or not password_ok:
        raise HTTPException(status_code=401, detail="Email atau kata sandi salah")
    return AuthOut(token=create_token(user.id), user=UserOut.model_validate(user))


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(current_user)):
    return user
