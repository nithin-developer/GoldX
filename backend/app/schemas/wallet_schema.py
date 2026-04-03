from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime
from decimal import Decimal


# --- Wallet Schemas ---


class WalletResponse(BaseModel):
    balance: Decimal
    pending_deposits: Decimal
    pending_withdrawals: Decimal


class WalletTransactionResponse(BaseModel):
    id: int
    type: str
    amount: Decimal
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
