import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db import Base, get_session
from app.main import app


@pytest.fixture()
def client():
    engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    Base.metadata.create_all(engine)
    TestingSession = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)

    def override_session():
        session = TestingSession()
        try:
            yield session
        finally:
            session.close()

    app.dependency_overrides[get_session] = override_session
    yield TestClient(app)
    app.dependency_overrides.clear()


def make_trip(trip_id="a", **overrides):
    trip = {
        "id": trip_id,
        "title": "Ke bandara pagi",
        "origin": "Tebet",
        "destination": "Bandara Soekarno-Hatta",
        "arriveBy": "2026-10-03T12:00:00.000",
        "optionLabel": "Taksi online",
        "departAt": "2026-10-03T10:40:00.000",
        "note": "",
        "createdAt": "2026-10-01T00:00:00.000",
    }
    trip.update(overrides)
    return trip


def test_health(client):
    assert client.get("/health").json() == {"status": "ok"}


def test_list_empty(client):
    response = client.get("/api/trips")
    assert response.status_code == 200
    assert response.json() == []


def test_create_then_list_uses_camel_case(client):
    response = client.put("/api/trips/a", json=make_trip())
    assert response.status_code == 200
    body = client.get("/api/trips").json()
    assert len(body) == 1
    assert body[0]["id"] == "a"
    assert body[0]["arriveBy"].startswith("2026-10-03T12:00:00")
    assert body[0]["optionLabel"] == "Taksi online"
    assert "arrive_by" not in body[0]


def test_put_replaces_existing_trip(client):
    client.put("/api/trips/a", json=make_trip())
    client.put("/api/trips/a", json=make_trip(title="Ke bandara siang"))
    body = client.get("/api/trips").json()
    assert len(body) == 1
    assert body[0]["title"] == "Ke bandara siang"


def test_list_is_newest_first(client):
    client.put("/api/trips/a", json=make_trip("a", createdAt="2026-10-01T00:00:00.000"))
    client.put("/api/trips/b", json=make_trip("b", createdAt="2026-10-02T00:00:00.000"))
    assert [t["id"] for t in client.get("/api/trips").json()] == ["b", "a"]


def test_null_depart_at_is_kept(client):
    client.put("/api/trips/a", json=make_trip(departAt=None, optionLabel=""))
    assert client.get("/api/trips/a").json()["departAt"] is None


def test_delete_removes_only_target(client):
    client.put("/api/trips/a", json=make_trip("a"))
    client.put("/api/trips/b", json=make_trip("b"))
    assert client.delete("/api/trips/a").status_code == 204
    assert [t["id"] for t in client.get("/api/trips").json()] == ["b"]


def test_delete_unknown_returns_404(client):
    assert client.delete("/api/trips/zzz").status_code == 404


def test_get_unknown_returns_404(client):
    assert client.get("/api/trips/zzz").status_code == 404


def test_id_mismatch_returns_400(client):
    assert client.put("/api/trips/x", json=make_trip("a")).status_code == 400


def test_empty_title_returns_422(client):
    assert client.put("/api/trips/a", json=make_trip(title="")).status_code == 422


def test_same_origin_and_destination_returns_422(client):
    response = client.put("/api/trips/a", json=make_trip(destination="tebet"))
    assert response.status_code == 422


def test_note_too_long_returns_422(client):
    assert client.put("/api/trips/a", json=make_trip(note="x" * 201)).status_code == 422
