from pydantic import BaseModel, Field, computed_field, model_validator
from typing import Optional
from datetime import datetime, timedelta, timezone
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
    user_id: Optional[int] = Field(None, ge=1000000, le=9999999)  # None = broadcast to all
    title: str = Field(..., max_length=500)
    message: str
    type: str = Field(default="system", pattern="^(system|signal|referral|support)$")


class AnnouncementResponse(BaseModel):
    id: int
    title: str
    content: str = Field(validation_alias="message")
    message: str
    is_active: bool
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    expires_at: Optional[datetime] = Field(default=None, validation_alias="end_date")
    created_at: datetime

    @computed_field(return_type=Optional[int])
    @property
    def duration_hours(self) -> Optional[int]:
        if self.start_date is None or self.end_date is None:
            return None

        total_seconds = (self.end_date - self.start_date).total_seconds()
        if total_seconds <= 0:
            return None

        return max(1, int(round(total_seconds / 3600)))

    class Config:
        from_attributes = True


class CreateAnnouncementRequest(BaseModel):
    title: str = Field(..., max_length=500)
    message: Optional[str] = None
    content: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    duration_hours: Optional[int] = Field(None, gt=0, le=720)

    @model_validator(mode="after")
    def normalize_announcement_payload(self):
        resolved_message = (self.message or self.content or "").strip()
        if not resolved_message:
            raise ValueError("message or content is required")

        self.message = resolved_message
        if not self.content:
            self.content = resolved_message

        if self.end_date is None and self.duration_hours is not None:
            start = self.start_date or datetime.now(timezone.utc)
            self.start_date = start
            self.end_date = start + timedelta(hours=self.duration_hours)

        if self.start_date and self.end_date and self.end_date <= self.start_date:
            raise ValueError("end_date must be greater than start_date")

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
