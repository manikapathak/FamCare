from app.models.booking import Booking
from app.models.caregiver import Caregiver


WORKING_HOURS_START = 9  # 9 AM
WORKING_HOURS_END = 18   # 6 PM (18:00)


def has_conflict(
    db,
    patient_id,
    caregiver_id,
    new_start,
    new_end
):

    caregiver_conflict=db.query(
        Booking
    ).filter(

        Booking.caregiver_id==caregiver_id,

        Booking.start_time < new_end,

        Booking.end_time > new_start

    ).first()


    if caregiver_conflict:

        return "Caregiver already booked"


    patient_conflict=db.query(
        Booking
    ).filter(

        Booking.patient_id==patient_id,

        Booking.start_time < new_end,

        Booking.end_time > new_start

    ).first()


    if patient_conflict:

        return "Patient already has booking"


    return None


def find_available_caregiver(db, new_start, new_end):
    """Find first available caregiver for the given time slot"""

    if new_start.hour < WORKING_HOURS_START or new_end.hour > WORKING_HOURS_END:
        raise Exception(f"Requested time is outside working hours ({WORKING_HOURS_START}:00 - {WORKING_HOURS_END}:00)")

    booked_caregivers = db.query(
        Booking.caregiver_id
    ).filter(
        Booking.start_time < new_end,
        Booking.end_time > new_start
    ).all()

    booked_caregiver_ids = [row[0] for row in booked_caregivers]

    available_caregiver = db.query(
        Caregiver
    ).filter(
        ~Caregiver.id.in_(booked_caregiver_ids) if booked_caregiver_ids else True
    ).order_by(Caregiver.id).first()

    return available_caregiver
