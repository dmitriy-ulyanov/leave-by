from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, model_validator
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
