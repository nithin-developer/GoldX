from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, DateTime, Text
from app.core.database import Base


class DepositWalletSetting(Base):
    __tablename__ = "deposit_wallet_settings"

    id = Column(Integer, primary_key=True, index=True)
    currency = Column(String(50), nullable=False, default="USDT")
    network = Column(String(50), nullable=True, default="TRC20")
    wallet_address = Column(Text, nullable=True)
    instructions = Column(Text, nullable=True)
    qr_code_filename = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    def __repr__(self):
        return (
            "<DepositWalletSetting("
            f"id={self.id}, currency={self.currency}, network={self.network}"
            ")>"
        )
