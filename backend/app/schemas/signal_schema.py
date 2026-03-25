from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from decimal import Decimal


# --- Signal Schemas ---


class SignalResponse(BaseModel):
    id: int
    asset: str
    direction: str
    profit_percent: float
    duration_hours: int
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


class CreateSignalRequest(BaseModel):
    asset: str = Field(..., max_length=20)
    direction: str = Field(..., pattern="^(long|short)$")
    profit_percent: float = Field(..., gt=0)
    duration_hours: int = Field(..., gt=0)


class UpdateSignalRequest(BaseModel):
    asset: Optional[str] = Field(None, max_length=20)
    direction: Optional[str] = Field(None, pattern="^(long|short)$")
    profit_percent: Optional[float] = Field(None, gt=0)
    duration_hours: Optional[int] = Field(None, gt=0)
    status: Optional[str] = Field(None, pattern="^(active|expired|completed)$")


class ActivateSignalRequest(BaseModel):
    signal_code: str = Field(..., max_length=50)


class SignalCodeResponse(BaseModel):
    id: int
    signal_id: int
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
    signal_id: int
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
