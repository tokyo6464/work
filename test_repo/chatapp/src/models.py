from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from db import Base


class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    content = Column(String(1000))
    username = Column(String(50))
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
