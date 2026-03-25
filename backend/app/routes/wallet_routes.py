from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.wallet_schema import (
    WalletResponse,
    WalletTransactionResponse,
    DepositRequest,
    WithdrawRequest,
    DepositResponse,
    WithdrawalResponse,
)
from app.schemas.auth_schema import MessageResponse, SetWithdrawalPasswordRequest
from app.services import wallet_service


router = APIRouter(prefix="/wallet", tags=["Wallet"])


@router.get("", response_model=WalletResponse)
async def get_wallet(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get wallet balance and pending amounts."""
    summary = await wallet_service.get_wallet_summary(current_user, db)
    return WalletResponse(**summary)


@router.get("/transactions", response_model=list[WalletTransactionResponse])
async def get_transactions(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get paginated wallet transaction history."""
    transactions = await wallet_service.get_transactions(current_user, db, skip, limit)
    return [WalletTransactionResponse.model_validate(t) for t in transactions]


@router.post("/deposit", response_model=DepositResponse, status_code=201)
async def create_deposit(
    data: DepositRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Submit a deposit request (pending admin approval).

    - **amount**: Deposit amount (must be > 0)
    - **transaction_ref**: Optional payment reference
    """
    deposit = await wallet_service.create_deposit(
        current_user, data.amount, data.transaction_ref, db
    )
    return DepositResponse.model_validate(deposit)


@router.get("/deposits", response_model=list[DepositResponse])
async def get_deposits(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get deposit history for the current user."""
    deposits = await wallet_service.get_user_deposits(current_user, db, skip, limit)
    return [DepositResponse.model_validate(d) for d in deposits]


@router.post("/withdraw", response_model=WithdrawalResponse, status_code=201)
async def create_withdrawal(
    data: WithdrawRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Submit a withdrawal request (requires withdrawal password).

    - **amount**: Withdrawal amount (must be > 0 and <= balance)
    - **withdrawal_password**: Withdrawal security password
    - **wallet_address**: Optional destination wallet address
    """
    withdrawal = await wallet_service.create_withdrawal(
        current_user, data.amount, data.withdrawal_password, data.wallet_address, db
    )
    return WithdrawalResponse.model_validate(withdrawal)


@router.post("/set-withdrawal-password", response_model=MessageResponse)
async def set_withdrawal_password(
    data: SetWithdrawalPasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Set or update the withdrawal password for enhanced wallet security."""
    await wallet_service.set_withdrawal_password(
        current_user, data.withdrawal_password, db
    )
    return MessageResponse(message="Withdrawal password set successfully")
