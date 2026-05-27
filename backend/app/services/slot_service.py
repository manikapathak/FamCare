from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.utils.slot_generator import generate_slots
from app.services.conflict_service import find_available_caregiver


def filter_available_slots(
    date,
    service_duration,
    db: Session
):

    available = []

    all_slots = generate_slots()

    now = datetime.now()

    today = now.date()

    selected_date = datetime.strptime(
        date,
        "%Y-%m-%d"
    ).date()


    # --------------------------
    # PAST DATE:
    # No slots allowed
    # --------------------------

    if selected_date < today:

        return []


    # --------------------------
    # AFTER 6 PM:
    # No same-day slot booking allowed
    # --------------------------

    if now.hour >= 18:

        if selected_date == today:

            return []


    for slot in all_slots:

        slot_start = datetime.strptime(
            f"{date} {slot}",
            "%Y-%m-%d %H:%M"
        )


        # --------------------------
        # TODAY ONLY:
        # Hide past slots
        # --------------------------

        if selected_date == today:

            if slot_start <= now:
                continue


        # --------------------------
        # CHECK CAREGIVER AVAILABILITY:
        # Only show slot if at least one caregiver is free
        # --------------------------

        slot_end = slot_start + timedelta(minutes=service_duration)

        available_caregiver = find_available_caregiver(db, slot_start, slot_end)

        if available_caregiver:
            available.append(slot)


    return available
