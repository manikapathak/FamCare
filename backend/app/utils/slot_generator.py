from datetime import datetime, timedelta


def generate_slots():

    slots = []

    current = datetime.strptime(
        "09:00",
        "%H:%M"
    )

    end = datetime.strptime(
        "18:00",
        "%H:%M"
    )

    while current < end:

        slots.append(
            current.strftime(
                "%H:%M"
            )
        )

        current += timedelta(
            minutes=15
        )

    return slots