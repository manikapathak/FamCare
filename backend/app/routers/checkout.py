from fastapi import APIRouter
from fastapi import Depends
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.checkout_schema import CheckoutRequest
from app.services.booking_service import process_checkout

router = APIRouter()


@router.post("/checkout")
def checkout(
    request: CheckoutRequest,
    db: Session = Depends(get_db)
):

    try:


        booking_group_id = process_checkout(

            db,
            request.patient_id,
            request.items

        )

        return {

            "success": True,

            "booking_group_id":
            booking_group_id
        }

    except Exception as e:

        print(str(e))

        raise HTTPException(

            status_code=400,

            detail=str(e)
        )