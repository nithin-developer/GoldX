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
    capital_balance: Decimal = Decimal("0")
    signal_profit_balance: Decimal = Decimal("0")
    reward_balance: Decimal = Decimal("0")
    withdrawable_balance: Decimal = Decimal("0")
    locked_capital_balance: Decimal = Decimal("0")
    capital_lock_active: bool = False
    capital_lock_ends_at: Optional[datetime] = None
    capital_lock_days_remaining: int = 0
    vip_level: int
    has_withdrawal_password: bool = False
    verification_status: str = "not_submitted"
    verification_submitted_at: Optional[datetime] = None
    verification_reviewed_at: Optional[datetime] = None
    verification_rejection_reason: Optional[str] = None
    verification_id_document_url: Optional[str] = None
    verification_selfie_document_url: Optional[str] = None
    verification_address_document_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class UpdateProfileRequest(BaseModel):
    full_name: Optional[str] = Field(None, max_length=255)
    phone: Optional[str] = Field(None, max_length=50)


class DashboardResponse(BaseModel):
    balance: Decimal
    capital_balance: Decimal = Decimal("0")
    signal_profit_balance: Decimal = Decimal("0")
    reward_balance: Decimal = Decimal("0")
    withdrawable_balance: Decimal = Decimal("0")
    locked_capital_balance: Decimal = Decimal("0")
    capital_lock_active: bool = False
    capital_lock_ends_at: Optional[datetime] = None
    capital_lock_days_remaining: int = 0
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
    capital_balance: Decimal = Decimal("0")
    signal_profit_balance: Decimal = Decimal("0")
    reward_balance: Decimal = Decimal("0")
    withdrawable_balance: Decimal = Decimal("0")
    locked_capital_balance: Decimal = Decimal("0")
    capital_lock_active: bool = False
    capital_lock_ends_at: Optional[datetime] = None
    capital_lock_days_remaining: int = 0
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
    capital_balance: Optional[Decimal] = None
    signal_profit_balance: Optional[Decimal] = None
    reward_balance: Optional[Decimal] = None


class UserListResponse(BaseModel):
    id: int
    email: str
    full_name: Optional[str] = None
    role: str
    is_active: bool
    wallet_balance: Decimal
    capital_balance: Decimal = Decimal("0")
    signal_profit_balance: Decimal = Decimal("0")
    reward_balance: Decimal = Decimal("0")
    withdrawable_balance: Decimal = Decimal("0")
    locked_capital_balance: Decimal = Decimal("0")
    capital_lock_active: bool = False
    capital_lock_ends_at: Optional[datetime] = None
    capital_lock_days_remaining: int = 0
    vip_level: int
    wallet_address: Optional[str] = None
    referral_count: int = 0
    referral_total_deposits: Decimal = Decimal("0")
    verification_status: str = "not_submitted"
    verification_submitted_at: Optional[datetime] = None
    verification_reviewed_at: Optional[datetime] = None
    verification_rejection_reason: Optional[str] = None
    verification_id_document_url: Optional[str] = None
    verification_selfie_document_url: Optional[str] = None
    verification_address_document_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class AdminUserReferralItemResponse(BaseModel):
    referral_id: int
    referred_user_id: int
    referred_email: Optional[str] = None
    referred_full_name: Optional[str] = None
    deposit_amount: Decimal = Decimal("0")
    bonus_amount: Decimal = Decimal("0")
    status: str
    created_at: datetime
