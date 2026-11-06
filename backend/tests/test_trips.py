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


def test_trips_require_login(client):
    assert client.get("/api/trips").status_code == 401
    assert client.put("/api/trips/a", json=make_trip()).status_code == 401
    assert client.delete("/api/trips/a").status_code == 401


def test_list_empty(client, auth):
    response = client.get("/api/trips", headers=auth)
    assert response.status_code == 200
    assert response.json() == []


def test_create_then_list_uses_camel_case(client, auth):
    assert client.put("/api/trips/a", json=make_trip(), headers=auth).status_code == 200
    body = client.get("/api/trips", headers=auth).json()
    assert len(body) == 1
    assert body[0]["id"] == "a"
    assert body[0]["arriveBy"].startswith("2026-10-03T12:00:00")
    assert body[0]["optionLabel"] == "Taksi online"
    assert "arrive_by" not in body[0]
    assert "userId" not in body[0]


def test_unicode_title_round_trips(client, auth):
    client.put("/api/trips/a", json=make_trip(title="Tebet → Bandara"), headers=auth)
    assert client.get("/api/trips/a", headers=auth).json()["title"] == "Tebet → Bandara"


def test_put_replaces_existing_trip(client, auth):
    client.put("/api/trips/a", json=make_trip(), headers=auth)
    client.put("/api/trips/a", json=make_trip(title="Ke bandara siang"), headers=auth)
    body = client.get("/api/trips", headers=auth).json()
    assert len(body) == 1
    assert body[0]["title"] == "Ke bandara siang"


def test_list_is_newest_first(client, auth):
    client.put("/api/trips/a", json=make_trip("a", createdAt="2026-10-01T00:00:00.000"), headers=auth)
    client.put("/api/trips/b", json=make_trip("b", createdAt="2026-10-02T00:00:00.000"), headers=auth)
    assert [t["id"] for t in client.get("/api/trips", headers=auth).json()] == ["b", "a"]


def test_null_depart_at_is_kept(client, auth):
    client.put("/api/trips/a", json=make_trip(departAt=None, optionLabel=""), headers=auth)
    assert client.get("/api/trips/a", headers=auth).json()["departAt"] is None


def test_delete_removes_only_target(client, auth):
    client.put("/api/trips/a", json=make_trip("a"), headers=auth)
    client.put("/api/trips/b", json=make_trip("b"), headers=auth)
    assert client.delete("/api/trips/a", headers=auth).status_code == 204
    assert [t["id"] for t in client.get("/api/trips", headers=auth).json()] == ["b"]


def test_delete_unknown_returns_404(client, auth):
    assert client.delete("/api/trips/zzz", headers=auth).status_code == 404


def test_get_unknown_returns_404(client, auth):
    assert client.get("/api/trips/zzz", headers=auth).status_code == 404


def test_id_mismatch_returns_400(client, auth):
    assert client.put("/api/trips/x", json=make_trip("a"), headers=auth).status_code == 400


def test_empty_title_returns_422(client, auth):
    assert client.put("/api/trips/a", json=make_trip(title=""), headers=auth).status_code == 422


def test_same_origin_and_destination_returns_422(client, auth):
    response = client.put("/api/trips/a", json=make_trip(destination="tebet"), headers=auth)
    assert response.status_code == 422


def test_note_too_long_returns_422(client, auth):
    assert client.put("/api/trips/a", json=make_trip(note="x" * 201), headers=auth).status_code == 422


def test_users_only_see_their_own_trips(client, auth, auth_b):
    client.put("/api/trips/a", json=make_trip("a"), headers=auth)
    assert client.get("/api/trips", headers=auth_b).json() == []
    assert client.get("/api/trips/a", headers=auth_b).status_code == 404


def test_same_trip_id_for_two_users_does_not_collide(client, auth, auth_b):
    client.put("/api/trips/a", json=make_trip("a", title="Milik David"), headers=auth)
    client.put("/api/trips/a", json=make_trip("a", title="Milik Lain"), headers=auth_b)
    assert client.get("/api/trips/a", headers=auth).json()["title"] == "Milik David"
    assert client.get("/api/trips/a", headers=auth_b).json()["title"] == "Milik Lain"


def test_user_cannot_delete_another_users_trip(client, auth, auth_b):
    client.put("/api/trips/a", json=make_trip("a"), headers=auth)
    assert client.delete("/api/trips/a", headers=auth_b).status_code == 404
    assert client.get("/api/trips/a", headers=auth).status_code == 200
