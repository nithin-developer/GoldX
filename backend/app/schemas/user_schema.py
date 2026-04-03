from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime
from decimal import Decimal


class UserProfileResponse(BaseModel):
    id: int
    email: str
    full_name: Optional[str] = None
    phone: Optional[str] = None
    role: str
    is_active: bool
    invite_code: Optional[str] = None
    wallet_balance: Decimal
    vip_level: int
    has_withdrawal_password: bool = False
    created_at: datetime

    class Config:
        from_attributes = True


class UpdateProfileRequest(BaseModel):
    full_name: Optional[str] = Field(None, max_length=255)
    phone: Optional[str] = Field(None, max_length=50)


class DashboardResponse(BaseModel):
    balance: Decimal
    active_signals: int
    total_profit: Decimal
    vip_level: int
    total_referrals: int
    announcements: list = []


class HomeRecentActivityResponse(BaseModel):
    id: str
    type: str
    title: str
    subtitle: Optional[str] = None
    amount: Optional[Decimal] = None
    is_positive: Optional[bool] = None
    tag: str
    created_at: datetime


class HomeDashboardResponse(BaseModel):
    balance: Decimal
    today_profit: Decimal
    total_profit: Decimal
    active_signals: int
    vip_level: int
    total_referrals: int
    announcements: list = []
    active_signal_alerts: list[str] = []
    recent_activities: list[HomeRecentActivityResponse] = []


class AdminUserUpdate(BaseModel):
    full_name: Optional[str] = None
    phone: Optional[str] = None
    is_active: Optional[bool] = None
    vip_level: Optional[int] = None
    role: Optional[str] = None
    wallet_balance: Optional[Decimal] = None


class UserListResponse(BaseModel):
    id: int
    email: str
    full_name: Optional[str] = None
    role: str
    is_active: bool
    wallet_balance: Decimal
    vip_level: int
    created_at: datetime

    class Config:
        from_attributes = True
