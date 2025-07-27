from pydantic import BaseModel
from datetime import datetime


class MessageBase(BaseModel):
    content: str
    username: str


class MessageCreate(MessageBase):
    pass


class Message(MessageBase):
    id: int
    content: str
    username: str
    timestamp: datetime

    class Config:
        from_attributes = True  # pydantic v2以降ではこちらを使用
