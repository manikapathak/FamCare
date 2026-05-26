from sqlalchemy import Column, Integer, String
from app.database import Base

class Caregiver(Base):

    __tablename__="caregivers"

    id=Column(Integer,primary_key=True,index=True)

    name=Column(String)