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
    id: int
    user_id: int
    amount: Decimal
    status: str
    transaction_ref: Optional[str] = None
    admin_note: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class WithdrawalResponse(BaseModel):
    id: int
    user_id: int
    amount: Decimal
    status: str
    wallet_address: Optional[str] = None
    admin_note: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


class AdminDepositAction(BaseModel):
    admin_note: Optional[str] = None


class AdminWithdrawalAction(BaseModel):
    admin_note: Optional[str] = None
