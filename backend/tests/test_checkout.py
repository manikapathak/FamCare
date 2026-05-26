from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_successful_checkout():

    payload = {

        "patient_id":1,

        "items":[
            {
                "service_id":1,
                "caregiver_id":1,
                "date":"2026-06-01",
                "start_time":"09:00"
            }
        ]
    }

    response = client.post(
        "/cart/checkout",
        json=payload
    )

    assert response.status_code == 200

    assert response.json()["success"] == True