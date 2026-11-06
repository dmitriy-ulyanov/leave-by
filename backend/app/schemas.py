import re
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator
from pydantic.alias_generators import to_camel


class CamelModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, from_attributes=True)


class TripIn(CamelModel):
    id: str = Field(min_length=1, max_length=64)
    title: str = Field(min_length=1, max_length=60)
    origin: str = Field(min_length=1, max_length=100)
    destination: str = Field(min_length=1, max_length=100)
    arrive_by: datetime
    option_label: str = Field(default="", max_length=100)
    depart_at: Optional[datetime] = None
    note: str = Field(default="", max_length=200)
    created_at: datetime

    @model_validator(mode="after")
    def places_must_differ(self):
        if self.origin.strip().lower() == self.destination.strip().lower():
            raise ValueError("Tujuan harus berbeda dari asal")
        return self


class TripOut(CamelModel):
    id: str
    title: str
    origin: str
    destination: str
    arrive_by: datetime
    option_label: str
    depart_at: Optional[datetime]
    note: str
    created_at: datetime


EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def _clean_email(value: str) -> str:
    value = value.strip().lower()
    if len(value) > 254 or not EMAIL_PATTERN.fullmatch(value):
        raise ValueError("Format email tidak valid")
    return value


class RegisterIn(BaseModel):
    name: str = Field(min_length=1, max_length=60)
    email: str
    password: str = Field(min_length=8, max_length=128)

    @field_validator("email")
    @classmethod
    def email_must_be_valid(cls, value: str) -> str:
        return _clean_email(value)

    @field_validator("name")
    @classmethod
    def name_must_not_be_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("Nama wajib diisi")
        return value.strip()


class LoginIn(BaseModel):
    email: str = Field(min_length=1, max_length=254)
    password: str = Field(min_length=1, max_length=128)


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    email: str
    name: str


class AuthOut(BaseModel):
    token: str
    user: UserOut
