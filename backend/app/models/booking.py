from sqlalchemy import Column,Integer,DateTime,ForeignKey,String
from app.database import Base


class Booking(Base):

    __tablename__="bookings"

    id=Column(Integer,primary_key=True,index=True)

    patient_id=Column(
        Integer,
        ForeignKey("patients.id")
    )

    service_id=Column(
        Integer,
        ForeignKey("services.id")
    )

    caregiver_id=Column(
        Integer,
        ForeignKey("caregivers.id")
    )

    start_time=Column(DateTime)

    end_time=Column(DateTime)

    booking_group_id=Column(String)