from datetime import datetime, timezone
from uuid import uuid4
from sqlalchemy import Column, Integer, String, Numeric, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


class WalletTransaction(Base):
    __tablename__ = "wallet_transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    type = Column(String(50), nullable=False)  # deposit, withdrawal, signal_profit, referral_bonus
    amount = Column(Numeric(precision=18, scale=2), nullable=False)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # Relationships
    user = relationship("User", back_populates="wallet_transactions")

    def __repr__(self):
        return f"<WalletTransaction(id={self.id}, type={self.type}, amount={self.amount})>"


class Deposit(Base):
    __tablename__ = "deposits"

    id = Column(Integer, primary_key=True, index=True)
    public_id = Column(
        String(36),
        unique=True,
        nullable=False,
        index=True,
        default=lambda: str(uuid4()),
    )
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    amount = Column(Numeric(precision=18, scale=2), nullable=False)
    status = Column(String(20), nullable=False, default="pending")  # pending, approved, rejected
    transaction_ref = Column(String(255), nullable=True)
    payment_proof_filename = Column(String(255), nullable=True)
    admin_note = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    user = relationship("User", back_populates="deposits")

    def __repr__(self):
        return f"<Deposit(id={self.id}, amount={self.amount}, status={self.status})>"


class Withdrawal(Base):
    __tablename__ = "withdrawals"

    id = Column(Integer, primary_key=True, index=True)
    public_id = Column(
        String(36),
        unique=True,
        nullable=False,
        index=True,
        default=lambda: str(uuid4()),
    )
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    amount = Column(Numeric(precision=18, scale=2), nullable=False)
    status = Column(String(20), nullable=False, default="pending")  # pending, approved, rejected
    wallet_address = Column(String(255), nullable=True)
    admin_note = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    user = relationship("User", back_populates="withdrawals")

    def __repr__(self):
        return f"<Withdrawal(id={self.id}, amount={self.amount}, status={self.status})>"
