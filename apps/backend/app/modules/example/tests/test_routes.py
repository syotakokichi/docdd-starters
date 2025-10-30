"""Example モジュールの API テスト例。"""

import pytest
from fastapi.testclient import TestClient

from app.kernel import create_app


@pytest.fixture(scope="module")
def test_client() -> TestClient:
    app = create_app()
    return TestClient(app)


def test_ping_endpoint(test_client: TestClient) -> None:
    response = test_client.get("/example/ping")
    assert response.status_code == 200
    assert response.json() == {"message": "pong"}
