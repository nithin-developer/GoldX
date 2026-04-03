import mimetypes
from decimal import Decimal
from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, Request, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.core.dependencies import get_current_user
from app.models.user import User
from app.schemas.wallet_schema import (
    WalletResponse,
    WalletTransactionResponse,
    WithdrawRequest,
    DepositResponse,
    WithdrawalResponse,
    DepositSettingsResponse,
)
from app.schemas.auth_schema import MessageResponse, SetWithdrawalPasswordRequest
from app.services import wallet_service


router = APIRouter(prefix="/wallet", tags=["Wallet"])


def _build_deposit_response(deposit, base_url: str | None = None) -> DepositResponse:
    return DepositResponse(
        id=deposit.public_id,
        user_id=deposit.user_id,
        amount=deposit.amount,
        status=deposit.status,
        transaction_ref=deposit.transaction_ref,
        payment_proof_url=wallet_service.build_payment_proof_url(
            deposit.payment_proof_filename,
            base_url,
        ),
        admin_note=deposit.admin_note,
        created_at=deposit.created_at,
        updated_at=deposit.updated_at,
    )


def _build_withdrawal_response(withdrawal) -> WithdrawalResponse:
    return WithdrawalResponse(
        id=withdrawal.public_id,
        user_id=withdrawal.user_id,
        amount=withdrawal.amount,
        status=withdrawal.status,
        wallet_address=withdrawal.wallet_address,
        admin_note=withdrawal.admin_note,
        created_at=withdrawal.created_at,
        updated_at=withdrawal.updated_at,
    )


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
    request: Request,
    amount: Decimal = Form(...),
    transaction_ref: str | None = Form(None),
    payment_proof: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Submit a deposit request (pending admin approval).

    - **amount**: Deposit amount (must be > 0)
    - **transaction_ref**: Optional payment reference
    - **payment_proof**: Required screenshot/image proof
    """
    if amount <= 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="amount must be greater than 0",
        )

    payment_proof_filename = await wallet_service.save_payment_proof(payment_proof)

    deposit = await wallet_service.create_deposit(
        current_user,
        amount,
        transaction_ref,
        payment_proof_filename,
        db,
    )

    base_url = str(request.base_url).rstrip("/")
    return _build_deposit_response(deposit, base_url)


@router.get("/deposits", response_model=list[DepositResponse])
async def get_deposits(
    request: Request,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status_filter: str | None = Query(
        None,
        alias="status",
        pattern="^(pending|approved|rejected)$",
    ),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get deposit history for the current user."""
    deposits = await wallet_service.get_user_deposits(
        current_user,
        db,
        skip,
        limit,
        status_filter=status_filter,
    )
    base_url = str(request.base_url).rstrip("/")
    return [_build_deposit_response(d, base_url) for d in deposits]


@router.get("/deposits/{deposit_id}", response_model=DepositResponse)
async def get_deposit_details(
    request: Request,
    deposit_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get a single deposit record owned by the current user."""
    deposit = await wallet_service.get_user_deposit_by_public_id(
        current_user,
        deposit_id,
        db,
    )
    base_url = str(request.base_url).rstrip("/")
    return _build_deposit_response(deposit, base_url)


@router.get("/deposit-settings", response_model=DepositSettingsResponse)
async def get_deposit_settings(
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """Get deposit wallet details and QR code URL for app display."""
    settings_data = await wallet_service.get_or_create_deposit_settings(db)
    base_url = str(request.base_url).rstrip("/")

    return DepositSettingsResponse(
        currency=settings_data.currency,
        network=settings_data.network,
        wallet_address=settings_data.wallet_address,
        instructions=settings_data.instructions,
        support_url=settings_data.support_url,
        qr_code_url=wallet_service.build_qr_code_url(
            settings_data.qr_code_filename,
            base_url,
        ),
        updated_at=settings_data.updated_at,
    )


@router.get("/deposit-settings/qr-code")
async def get_deposit_qr_code(
    db: AsyncSession = Depends(get_db),
):
    """Get the currently configured deposit QR code image file."""
    settings_data = await wallet_service.get_or_create_deposit_settings(db)
    if not settings_data.qr_code_filename:
        raise HTTPException(status_code=404, detail="Deposit QR code not configured")

    qr_code_path = wallet_service.get_qr_code_path(settings_data.qr_code_filename)
    if not qr_code_path.exists():
        raise HTTPException(status_code=404, detail="Deposit QR code file not found")

    media_type, _ = mimetypes.guess_type(str(qr_code_path))
    return FileResponse(
        path=qr_code_path,
        media_type=media_type or "application/octet-stream",
        filename=settings_data.qr_code_filename,
    )


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
    return _build_withdrawal_response(withdrawal)


@router.get("/withdrawals", response_model=list[WithdrawalResponse])
async def get_withdrawals(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status_filter: str | None = Query(
        None,
        alias="status",
        pattern="^(pending|approved|rejected)$",
    ),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get withdrawal history for the current user."""
    withdrawals = await wallet_service.get_user_withdrawals(
        current_user,
        db,
        skip,
        limit,
        status_filter=status_filter,
    )
    return [_build_withdrawal_response(w) for w in withdrawals]


@router.get("/withdrawals/{withdrawal_id}", response_model=WithdrawalResponse)
async def get_withdrawal_details(
    withdrawal_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get a single withdrawal record owned by the current user."""
    withdrawal = await wallet_service.get_user_withdrawal_by_public_id(
        current_user,
        withdrawal_id,
        db,
    )
    return _build_withdrawal_response(withdrawal)


@router.post("/set-withdrawal-password", response_model=MessageResponse)
async def set_withdrawal_password(
    data: SetWithdrawalPasswordRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Set or update withdrawal password. Updating requires current password."""
    new_password = data.new_withdrawal_password or data.withdrawal_password
    if not new_password:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="new_withdrawal_password is required",
        )

    had_withdrawal_password = current_user.withdrawal_password_hash is not None
    await wallet_service.set_withdrawal_password(
        current_user,
        new_password,
        data.current_withdrawal_password,
        db,
    )
    return MessageResponse(
        message=(
            "Withdrawal password updated successfully"
            if had_withdrawal_password
            else "Withdrawal password set successfully"
        )
    )
