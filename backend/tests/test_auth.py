import jwt

from app.security import JWT_ALGORITHM, JWT_SECRET, hash_password, verify_password


def test_register_returns_token_and_user(client):
    response = client.post(
        "/api/auth/register", json={"name": "David", "email": "David@Contoh.com ", "password": "rahasia123"}
    )
    assert response.status_code == 201
    body = response.json()
    assert body["token"]
    assert body["user"]["email"] == "david@contoh.com"
    assert body["user"]["name"] == "David"
    assert "password" not in str(body)


def test_register_duplicate_email_returns_409(client):
    payload = {"name": "David", "email": "david@contoh.com", "password": "rahasia123"}
    client.post("/api/auth/register", json=payload)
    response = client.post("/api/auth/register", json={**payload, "email": "DAVID@contoh.com"})
    assert response.status_code == 409
    assert response.json()["detail"] == "Email sudah terdaftar"


def test_register_short_password_returns_422(client):
    response = client.post(
        "/api/auth/register", json={"name": "David", "email": "d@contoh.com", "password": "pendek"}
    )
    assert response.status_code == 422


def test_register_invalid_email_returns_422(client):
    response = client.post(
        "/api/auth/register", json={"name": "David", "email": "bukan-email", "password": "rahasia123"}
    )
    assert response.status_code == 422


def test_register_blank_name_returns_422(client):
    response = client.post(
        "/api/auth/register", json={"name": "   ", "email": "d@contoh.com", "password": "rahasia123"}
    )
    assert response.status_code == 422


def test_login_success(client):
    client.post("/api/auth/register", json={"name": "David", "email": "d@contoh.com", "password": "rahasia123"})
    response = client.post("/api/auth/login", json={"email": "D@contoh.com", "password": "rahasia123"})
    assert response.status_code == 200
    assert response.json()["user"]["name"] == "David"


def test_login_wrong_password_returns_401(client):
    client.post("/api/auth/register", json={"name": "David", "email": "d@contoh.com", "password": "rahasia123"})
    response = client.post("/api/auth/login", json={"email": "d@contoh.com", "password": "salah-salah"})
    assert response.status_code == 401
    assert response.json()["detail"] == "Email atau kata sandi salah"


def test_login_unknown_email_returns_same_401(client):
    response = client.post("/api/auth/login", json={"email": "tidak@ada.com", "password": "rahasia123"})
    assert response.status_code == 401
    assert response.json()["detail"] == "Email atau kata sandi salah"


def test_me_with_token(client, auth):
    response = client.get("/api/auth/me", headers=auth)
    assert response.status_code == 200
    assert response.json()["email"] == "david@contoh.com"


def test_me_without_token_returns_401(client):
    assert client.get("/api/auth/me").status_code == 401


def test_me_with_garbage_token_returns_401(client):
    response = client.get("/api/auth/me", headers={"Authorization": "Bearer ngawur"})
    assert response.status_code == 401


def test_me_with_expired_token_returns_401(client):
    user_id = client.post(
        "/api/auth/register", json={"name": "David", "email": "d@contoh.com", "password": "rahasia123"}
    ).json()["user"]["id"]
    expired = jwt.encode({"sub": user_id, "exp": 1}, JWT_SECRET, algorithm=JWT_ALGORITHM)
    response = client.get("/api/auth/me", headers={"Authorization": f"Bearer {expired}"})
    assert response.status_code == 401


def test_token_signed_with_other_secret_is_rejected(client):
    user_id = client.post(
        "/api/auth/register", json={"name": "David", "email": "d@contoh.com", "password": "rahasia123"}
    ).json()["user"]["id"]
    forged = jwt.encode({"sub": user_id, "exp": 9999999999}, "rahasia-lain-yang-cukup-panjang-123456", algorithm=JWT_ALGORITHM)
    response = client.get("/api/auth/me", headers={"Authorization": f"Bearer {forged}"})
    assert response.status_code == 401


def test_password_hash_is_salted_and_verifiable():
    first = hash_password("rahasia123")
    second = hash_password("rahasia123")
    assert first != second
    assert verify_password("rahasia123", first)
    assert not verify_password("salah", first)
    assert not verify_password("rahasia123", "bukan-hash")
