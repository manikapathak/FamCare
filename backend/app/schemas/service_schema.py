from pydantic import BaseModel


class ServiceResponse(BaseModel):

    id: int
    name: str
    duration_minutes: int
    price: float

    class Config:
        from_attributes=True