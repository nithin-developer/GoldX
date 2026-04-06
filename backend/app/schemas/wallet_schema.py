from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from decimal import Decimal


# --- Wallet Schemas ---


class WalletResponse(BaseModel):
    balance: Decimal
    capital_balance: Decimal = Decimal("0")
    signal_profit_balance: Decimal = Decimal("0")
    reward_balance: Decimal = Decimal("0")
    withdrawable_balance: Decimal = Decimal("0")
    locked_capital_balance: Decimal = Decimal("0")
    unlocked_capital_balance: Decimal = Decimal("0")
    capital_lock_active: bool = False
    capital_lock_ends_at: Optional[datetime] = None
    capital_lock_days_remaining: int = 0
    withdrawal_fee_percent: Decimal = Decimal("10")
    withdrawal_fee_notice: str = "10% withdrawal fee will be deducted from any withdrawal"
    pending_deposits: Decimal
    pending_withdrawals: Decimal


class WalletTransactionResponse(BaseModel):
    id: int
    type: str
    amount: Decimal
    status: str = "completed"
    description: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class DepositRequest(BaseModel):
    amount: Decimal = Field(..., gt=0)
    transaction_ref: Optional[str] = Field(None, max_length=255)


class WithdrawRequest(BaseModel):
    amount: Decimal = Field(..., gt=0)
    withdrawal_password: str = Field(..., min_length=1)
    wallet_address: Optional[str] = Field(None, max_length=255)


class DepositResponse(BaseModel):
    id: str
    user_id: int
    amount: Decimal
    transaction_type: str = "deposit"
    self_reward_amount: Decimal = Decimal("0")
    referrer_reward_amount: Decimal = Decimal("0")
    status: str
    transaction_ref: Optional[str] = None
    payment_proof_url: Optional[str] = None
    admin_note: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None


class WithdrawalResponse(BaseModel):
    id: str
    user_id: int
    amount: Decimal
    transaction_type: str = "withdrawal"
    capital_amount: Decimal = Decimal("0")
    signal_profit_amount: Decimal = Decimal("0")
    reward_amount: Decimal = Decimal("0")
    fee_rate_percent: Decimal = Decimal("10")
    fee_amount: Decimal = Decimal("0")
    net_amount: Decimal = Decimal("0")
    status: str
    wallet_address: Optional[str] = None
    admin_note: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None


class DepositSettingsResponse(BaseModel):
    currency: str
    network: Optional[str] = None
    wallet_address: Optional[str] = None
    instructions: Optional[str] = None
    support_url: Optional[str] = None
    qr_code_url: Optional[str] = None
    updated_at: Optional[datetime] = None


class AdminDepositAction(BaseModel):
    admin_note: Optional[str] = None


class AdminWithdrawalAction(BaseModel):
    admin_note: Optional[str] = None
