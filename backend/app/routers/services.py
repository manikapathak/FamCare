from fastapi import APIRouter
from fastapi import Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.service import Service


router=APIRouter()


@router.get("/")
def get_services(
    db:Session=Depends(get_db)
):

    services=db.query(Service).all()

    return services