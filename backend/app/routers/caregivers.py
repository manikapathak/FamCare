from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.caregiver import Caregiver

router = APIRouter()

@router.get("/caregivers")
def get_caregivers(
    service_id: int,
    db: Session = Depends(get_db)
):

    caregivers = db.query(Caregiver).all()

    return [
        {
            "id": c.id,
            "name": c.name
        }
        for c in caregivers
    ]