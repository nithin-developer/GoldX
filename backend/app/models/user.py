from datetime import datetime, timezone
from sqlalchemy import (
    Column, Integer, String, Numeric, Boolean, DateTime, Text
)
from sqlalchemy.orm import relationship
from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    full_name = Column(String(255), nullable=True)
    phone = Column(String(50), nullable=True)
    password_hash = Column(Text, nullable=False)
    role = Column(String(20), nullable=False, default="user")  # "user" or "admin"
    is_active = Column(Boolean, default=True)
    invite_code = Column(String(8), unique=True, nullable=True, index=True)
    referred_by = Column(Integer, nullable=True)
    wallet_balance = Column(Numeric(precision=18, scale=2), default=0)
    vip_level = Column(Integer, default=0)
    withdrawal_password_hash = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    wallet_transactions = relationship("WalletTransaction", back_populates="user", lazy="selectin")
    deposits = relationship("Deposit", back_populates="user", lazy="selectin")
    withdrawals = relationship("Withdrawal", back_populates="user", lazy="selectin")
    signal_entries = relationship("UserSignalEntry", back_populates="user", lazy="selectin")
    notifications = relationship("Notification", back_populates="user", lazy="selectin")
    support_messages = relationship("SupportMessage", back_populates="user", lazy="selectin")
    referrals_made = relationship(
        "Referral",
        back_populates="referrer",
        foreign_keys="Referral.referrer_id",
        lazy="selectin",
    )

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, role={self.role})>"
