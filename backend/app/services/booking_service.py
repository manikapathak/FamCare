from datetime import datetime,timedelta
import uuid

from app.models.service import Service
from app.models.booking import Booking
from app.services.conflict_service import find_available_caregiver


def process_checkout(
    db,
    patient_id,
    items
):

    booking_group_id = str(uuid.uuid4())
    assignments = []

    try:
        # First pass: validate and find available caregivers for all items
        for item in items:

            service = db.query(
                Service
            ).filter(
                Service.id == item.service_id
            ).first()

            if not service:
                raise Exception(f"Service {item.service_id} not found")

            start = datetime.strptime(
                f"{item.date} {item.start_time}",
                "%Y-%m-%d %H:%M"
            )

            end = start + timedelta(
                minutes=service.duration_minutes
            )

            # Check patient conflict with existing bookings
            patient_conflict = db.query(
                Booking
            ).filter(
                Booking.patient_id == patient_id,
                Booking.start_time < end,
                Booking.end_time > start
            ).first()

            if patient_conflict:
                raise Exception(f"Patient already has a booking for {service.name} at {item.start_time}")

            # Check patient conflict with other items in this checkout
            for existing_assignment in assignments:
                if (existing_assignment["start"] < end and
                    existing_assignment["end"] > start):
                    raise Exception(f"Patient cannot book {service.name} at {item.start_time} - conflicts with {existing_assignment['service_name']}")

            # Find available caregiver
            caregiver = find_available_caregiver(db, start, end)

            if not caregiver:
                raise Exception(f"No caregiver available for {service.name} on {item.date} at {item.start_time}")

            assignments.append({
                "service_id": item.service_id,
                "service_name": service.name,
                "caregiver_id": caregiver.id,
                "start": start,
                "end": end
            })

        # Second pass: create all bookings (atomicity - all or nothing)
        for assignment in assignments:

            booking = Booking(
                patient_id=patient_id,
                service_id=assignment["service_id"],
                caregiver_id=assignment["caregiver_id"],
                start_time=assignment["start"],
                end_time=assignment["end"],
                booking_group_id=booking_group_id
            )

            db.add(booking)

        db.commit()

        return booking_group_id

    except Exception as e:
        db.rollback()
        raise Exception(str(e))
