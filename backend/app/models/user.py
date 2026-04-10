from datetime import datetime, timezone
from sqlalchemy import (
    Column, Integer, String, Numeric, Boolean, DateTime, Text, ForeignKey
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
    capital_balance = Column(Numeric(precision=18, scale=2), default=0)
    signal_profit_balance = Column(Numeric(precision=18, scale=2), default=0)
    reward_balance = Column(Numeric(precision=18, scale=2), default=0)
    first_deposit_approved_at = Column(DateTime(timezone=True), nullable=True)
    initial_capital_locked_amount = Column(Numeric(precision=18, scale=2), default=0)
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
    referrals_made = relationship(
        "Referral",
        back_populates="referrer",
        foreign_keys="Referral.referrer_id",
        lazy="selectin",
    )
    verification = relationship(
        "UserVerification",
        back_populates="user",
        uselist=False,
        lazy="selectin",
        foreign_keys="UserVerification.user_id",
    )
    reviewed_verifications = relationship(
        "UserVerification",
        back_populates="reviewed_by_admin",
        foreign_keys="UserVerification.reviewed_by_admin_id",
        lazy="selectin",
    )

    @property
    def verification_status(self) -> str:
        if self.verification is None:
            return "not_submitted"

        return self.verification.status or "not_submitted"

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, role={self.role})>"


class UserVerification(Base):
    __tablename__ = "user_verifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    status = Column(String(20), nullable=False, default="not_submitted", index=True)
    id_document_filename = Column(String(255), nullable=True)
    address_document_filename = Column(String(255), nullable=True)
    submitted_at = Column(DateTime(timezone=True), nullable=True)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
    reviewed_by_admin_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    rejection_reason = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    user = relationship(
        "User",
        back_populates="verification",
        foreign_keys=[user_id],
        lazy="selectin",
    )
    reviewed_by_admin = relationship(
        "User",
        back_populates="reviewed_verifications",
        foreign_keys=[reviewed_by_admin_id],
        lazy="selectin",
    )

    def __repr__(self):
        return f"<UserVerification(user_id={self.user_id}, status={self.status})>"
