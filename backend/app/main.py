from fastapi import FastAPI
from app.database import engine, Base

# import models
from app.models.service import Service
from app.models.caregiver import Caregiver
from app.models.patient import Patient
from app.models.booking import Booking

#import routers
from app.routers.services import router as services_router
from app.routers.slots import router as slots_router
from app.routers.checkout import router as checkout_router

app = FastAPI()

app.include_router(services_router, prefix="/services")
app.include_router(slots_router, prefix="/slots", tags=["slots"])
app.include_router(checkout_router, prefix='/cart', tags=["checkout"])


Base.metadata.create_all(bind=engine)


@app.get("/")
def home():

    return {
        "message":"Backend running"
    }