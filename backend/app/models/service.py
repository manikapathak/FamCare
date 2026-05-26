from sqlalchemy import Column, Integer, String, Numeric
from app.database import Base

class Service(Base):
    __tablename__ = "services"

    id = Column(Integer, primary_key=True, index=True)

    name = Column(String)

    duration_minutes = Column(Integer)

    price = Column(Numeric)
