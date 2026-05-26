from pydantic import BaseModel
from typing import List


class BookingItem(BaseModel):

    service_id:int
    date:str
    start_time:str


class CheckoutRequest(BaseModel):

    patient_id:int
    items:List[BookingItem]