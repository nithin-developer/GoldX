import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, DateTime, Numeric, ForeignKey
)
from sqlalchemy.orm import relationship
from app.core.database import Base


class Signal(Base):
    __tablename__ = "signals"

    id = Column(Integer, primary_key=True, index=True)
    public_id = Column(
        String(36),
        unique=True,
        nullable=False,
        default=lambda: str(uuid.uuid4()),
        index=True,
    )
    asset = Column(String(20), nullable=False)       # e.g., BTC, ETH
    direction = Column(String(10), nullable=False)    # "long" or "short"
    profit_percent = Column(Float, nullable=False)
    duration_hours = Column(Integer, nullable=False)
    status = Column(String(20), nullable=False, default="active")  # active, expired, completed
    vip_only = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    codes = relationship("SignalCode", back_populates="signal", lazy="selectin")
    entries = relationship("UserSignalEntry", back_populates="signal", lazy="selectin")

    def __repr__(self):
        return f"<Signal(public_id={self.public_id}, asset={self.asset}, direction={self.direction})>"


class SignalCode(Base):
    __tablename__ = "signal_codes"

    id = Column(Integer, primary_key=True, index=True)
    signal_id = Column(Integer, ForeignKey("signals.id", ondelete="CASCADE"), nullable=False)
    code = Column(String(50), unique=True, nullable=False, index=True)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    used = Column(Boolean, default=False)
    used_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # Relationships
    signal = relationship("Signal", back_populates="codes")

    def __repr__(self):
        return f"<SignalCode(id={self.id}, code={self.code}, used={self.used})>"


class UserSignalEntry(Base):
    __tablename__ = "user_signal_entries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    signal_id = Column(Integer, ForeignKey("signals.id", ondelete="CASCADE"), nullable=False)
    entry_balance = Column(Numeric(precision=18, scale=2), nullable=False)
    participation_amount = Column(Numeric(precision=18, scale=2), nullable=False)
    profit_percent = Column(Float, nullable=False)
    profit_amount = Column(Numeric(precision=18, scale=2), default=0)
    status = Column(String(20), nullable=False, default="active")  # active, completed, cancelled
    started_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    ends_at = Column(DateTime(timezone=True), nullable=False)
    completed_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    user = relationship("User", back_populates="signal_entries")
    signal = relationship("Signal", back_populates="entries")

    def __repr__(self):
        return f"<UserSignalEntry(id={self.id}, user_id={self.user_id}, status={self.status})>"
