from pydantic import BaseModel, Field, model_validator
from typing import Optional
from datetime import datetime
from decimal import Decimal


class ReferralResponse(BaseModel):
    id: int
    referrer_id: int
    referred_user_id: int
    referred_email: Optional[str] = None
    deposit_amount: Decimal
    bonus_amount: Decimal
    status: str
    created_at: datetime

    class Config:
        from_attributes = True


class ReferralStatsResponse(BaseModel):
    total_referrals: int
    qualified_referrals: int
    total_bonus_earned: Decimal
    invite_code: Optional[str] = None


class NotificationResponse(BaseModel):
    id: int
    title: str
    message: str
    type: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


class MarkNotificationsReadRequest(BaseModel):
    notification_ids: list[int] = Field(default=[])
    mark_all: bool = False


class CreateNotificationRequest(BaseModel):
    user_id: Optional[int] = None  # None = broadcast to all
    title: str = Field(..., max_length=500)
    message: str
    type: str = Field(default="system", pattern="^(system|signal|referral|support)$")


class AnnouncementResponse(BaseModel):
    id: int
    title: str
    message: str
    is_active: bool
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True


class CreateAnnouncementRequest(BaseModel):
    title: str = Field(..., max_length=500)
    message: str
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None


class SupportMessageResponse(BaseModel):
    id: int
    user_id: int
    sender_type: str
    message: str
    created_at: datetime

    class Config:
        from_attributes = True


class SendSupportMessageRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)


class AdminSupportReplyRequest(BaseModel):
    user_id: Optional[int] = None
    chat_id: Optional[int] = None
    message: str = Field(..., min_length=1, max_length=2000)

    @model_validator(mode="after")
    def validate_target(self):
        # Frontend may send either user_id or chat_id (chat_id maps to user_id).
        if self.user_id is None and self.chat_id is None:
            raise ValueError("Either user_id or chat_id is required")
        if self.user_id is None:
            self.user_id = self.chat_id
        return self


class ReportResponse(BaseModel):
    total_users: int
    active_users: int
    total_deposits: Decimal
    total_withdrawals: Decimal
    pending_deposits: int
    pending_withdrawals: int
    total_signals: int
    active_signals: int
    total_wallet_balance: Decimal
