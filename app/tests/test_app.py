import pytest

from app import app


@pytest.fixture()
def client():
    # flask test client позволяет CI запускать unit-тесты без отдельного
    # поднятия web-сервера и без занятого сетевого порта
    return app.test_client()


def test_health_returns_ok(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_products_returns_product_list(client):
    response = client.get("/products")

    assert response.status_code == 200
    assert isinstance(response.get_json(), list)
    assert len(response.get_json()) >= 3


def test_existing_product_returns_product(client):
    response = client.get("/products/1")

    assert response.status_code == 200
    assert response.get_json()["id"] == 1


def test_missing_product_returns_404(client):
    response = client.get("/products/999")

    assert response.status_code == 404
    assert response.get_json() == {"error": "product not found"}
