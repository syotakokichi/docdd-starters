"""Example モジュールで利用するスキーマ例。"""

from pydantic import BaseModel


class PingResponse(BaseModel):
    message: str
