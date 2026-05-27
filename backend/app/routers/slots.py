from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.service import Service
from app.services.slot_service import (
    filter_available_slots
)

router=APIRouter()


@router.get("/available")
def get_available_slots(
    service_id:int,
    date:str,
    db:Session=Depends(get_db)
):

    service=db.query(
        Service
    ).filter(
        Service.id==service_id
    ).first()

    if not service:

        return {
            "error":"Service not found"
        }


    slots=filter_available_slots(
        date,
        service.duration_minutes,
        db
    )

    return slots