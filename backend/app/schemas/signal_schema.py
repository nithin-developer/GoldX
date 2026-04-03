from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import datetime
from decimal import Decimal


# --- Signal Schemas ---


class SignalResponse(BaseModel):
    id: str = Field(validation_alias="public_id")
    asset: str
    direction: str
    profit_percent: float
    duration_hours: int
    status: str
    vip_only: bool = False
    created_at: datetime

    class Config:
        from_attributes = True


class CreateSignalRequest(BaseModel):
    asset: str = Field(..., max_length=20)
    direction: str = Field(..., pattern="^(long|short)$")
    profit_percent: float = Field(..., gt=0)
    duration_hours: int = Field(..., gt=0)
    vip_only: bool = False

    @field_validator("direction", mode="before")
    @classmethod
    def normalize_direction(cls, value: str) -> str:
        normalized = str(value).strip().lower()
        alias_map = {
            "buy": "long",
            "sell": "short",
            "long": "long",
            "short": "short",
        }
        mapped = alias_map.get(normalized)
        if mapped is None:
            raise ValueError("direction must be one of: long, short, buy, sell")
        return mapped


class UpdateSignalRequest(BaseModel):
    asset: Optional[str] = Field(None, max_length=20)
    direction: Optional[str] = Field(None, pattern="^(long|short)$")
    profit_percent: Optional[float] = Field(None, gt=0)
    duration_hours: Optional[int] = Field(None, gt=0)
    status: Optional[str] = Field(None, pattern="^(active|expired|completed)$")
    vip_only: Optional[bool] = None

    @field_validator("direction", mode="before")
    @classmethod
    def normalize_direction(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None

        normalized = str(value).strip().lower()
        alias_map = {
            "buy": "long",
            "sell": "short",
            "long": "long",
            "short": "short",
        }
        mapped = alias_map.get(normalized)
        if mapped is None:
            raise ValueError("direction must be one of: long, short, buy, sell")
        return mapped


class ActivateSignalRequest(BaseModel):
    signal_code: str = Field(..., max_length=50)


class SignalCodeResponse(BaseModel):
    id: int
    signal_id: str = Field(validation_alias="signal_public_id")
    code: str
    expires_at: datetime
    used: bool
    created_at: datetime

    class Config:
        from_attributes = True


class GenerateCodeRequest(BaseModel):
    expires_in_hours: int = Field(default=24, gt=0, le=720)  # max 30 days
    count: int = Field(default=1, gt=0, le=100)


class UserSignalEntryResponse(BaseModel):
    id: int
    user_id: int
    signal_id: str = Field(validation_alias="signal_public_id")
    entry_balance: Decimal
    participation_amount: Decimal
    profit_percent: float
    profit_amount: Decimal
    status: str
    started_at: datetime
    ends_at: datetime
    completed_at: Optional[datetime] = None
    signal: Optional[SignalResponse] = None

    class Config:
        from_attributes = True
