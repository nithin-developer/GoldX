from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Numeric, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base


class Referral(Base):
    __tablename__ = "referrals"

    id = Column(Integer, primary_key=True, index=True)
    referrer_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    referred_user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)
    deposit_amount = Column(Numeric(precision=18, scale=2), default=0)
    bonus_amount = Column(Numeric(precision=18, scale=2), default=0)
    status = Column(String(20), nullable=False, default="pending")  # pending, qualified, rewarded
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # Relationships
    referrer = relationship("User", back_populates="referrals_made", foreign_keys=[referrer_id])
    referred_user = relationship("User", foreign_keys=[referred_user_id])

    def __repr__(self):
        return f"<Referral(referrer={self.referrer_id}, referred={self.referred_user_id})>"
