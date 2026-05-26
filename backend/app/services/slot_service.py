from datetime import datetime, timedelta
from app.utils.slot_generator import generate_slots


def filter_available_slots(
    date,
    service_duration
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


        available.append(
            slot
        )


    return available