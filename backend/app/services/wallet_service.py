from decimal import Decimal
from pathlib import Path
from uuid import uuid4
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from fastapi import HTTPException, UploadFile, status
from app.core.config import settings
from app.models.user import User
from app.models.wallet import WalletTransaction, Deposit, Withdrawal
from app.models.system_settings import DepositWalletSetting
from app.core.security import hash_password, verify_password


ALLOWED_QR_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
ALLOWED_PAYMENT_PROOF_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}


def get_qr_code_directory() -> Path:
    directory = Path(settings.UPLOADS_DIR).resolve() / "qr_codes"
    directory.mkdir(parents=True, exist_ok=True)
    return directory


def get_qr_code_path(filename: str) -> Path:
    return get_qr_code_directory() / filename


def build_qr_code_url(filename: str | None, base_url: str | None = None) -> str | None:
    if not filename:
        return None

    relative = f"/uploads/qr_codes/{filename}"
    if not base_url:
        return relative

    return f"{base_url.rstrip('/')}{relative}"


def get_payment_proof_directory() -> Path:
    directory = Path(settings.UPLOADS_DIR).resolve() / "payment_proofs"
    directory.mkdir(parents=True, exist_ok=True)
    return directory


def get_payment_proof_path(filename: str) -> Path:
    return get_payment_proof_directory() / filename


def build_payment_proof_url(filename: str | None, base_url: str | None = None) -> str | None:
    if not filename:
        return None

    relative = f"/uploads/payment_proofs/{filename}"
    if not base_url:
        return relative

    return f"{base_url.rstrip('/')}{relative}"


async def save_payment_proof(upload: UploadFile) -> str:
    extension = Path(upload.filename or "").suffix.lower()
    if not extension:
        extension = ".png"

    if extension not in ALLOWED_PAYMENT_PROOF_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Payment proof must be an image (.png, .jpg, .jpeg, .webp)",
        )

    if upload.content_type and not upload.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded payment proof must be an image",
        )

    file_content = await upload.read()
    if not file_content:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded payment proof file is empty",
        )

    filename = f"deposit_proof_{uuid4().hex}{extension}"
    file_path = get_payment_proof_directory() / filename
    file_path.write_bytes(file_content)
    return filename


def delete_payment_proof(filename: str | None) -> None:
    if not filename:
        return

    path = get_payment_proof_path(filename)
    if path.exists():
        path.unlink()


async def get_or_create_deposit_settings(db: AsyncSession) -> DepositWalletSetting:
    result = await db.execute(select(DepositWalletSetting).limit(1))
    settings_data = result.scalar_one_or_none()

    if settings_data:
        return settings_data

    settings_data = DepositWalletSetting(
        currency="USDT",
        network="TRC20",
        wallet_address=None,
        instructions=None,
        qr_code_filename=None,
    )
    db.add(settings_data)
    await db.flush()
    return settings_data


async def update_deposit_settings(
    db: AsyncSession,
    currency: str,
    network: str | None,
    wallet_address: str | None,
    instructions: str | None,
    qr_code: UploadFile | None,
) -> DepositWalletSetting:
    settings_data = await get_or_create_deposit_settings(db)

    normalized_currency = (currency or settings_data.currency or "USDT").strip().upper()
    settings_data.currency = normalized_currency or "USDT"
    settings_data.network = network.strip().upper() if network and network.strip() else None
    settings_data.wallet_address = (
        wallet_address.strip() if wallet_address and wallet_address.strip() else None
    )
    settings_data.instructions = (
        instructions.strip() if instructions and instructions.strip() else None
    )

    if qr_code:
        extension = Path(qr_code.filename or "").suffix.lower()
        if not extension:
            extension = ".png"

        if extension not in ALLOWED_QR_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="QR code must be an image (.png, .jpg, .jpeg, .webp)",
            )

        if qr_code.content_type and not qr_code.content_type.startswith("image/"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Uploaded QR code file must be an image",
            )

        file_content = await qr_code.read()
        if not file_content:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Uploaded QR code file is empty",
            )

        qr_code_dir = get_qr_code_directory()
        new_filename = f"deposit_qr_{uuid4().hex}{extension}"
        new_path = qr_code_dir / new_filename
        new_path.write_bytes(file_content)

        old_filename = settings_data.qr_code_filename
        settings_data.qr_code_filename = new_filename

        if old_filename and old_filename != new_filename:
            old_path = qr_code_dir / old_filename
            if old_path.exists():
                old_path.unlink()

    await db.flush()
    return settings_data


async def get_wallet_summary(user: User, db: AsyncSession) -> dict:
    """Get wallet balance and pending amounts."""
    # Pending deposits
    pending_deposits_result = await db.execute(
        select(func.coalesce(func.sum(Deposit.amount), 0)).where(
            Deposit.user_id == user.id, Deposit.status == "pending"
        )
    )
    pending_deposits = pending_deposits_result.scalar()

    # Pending withdrawals
    pending_withdrawals_result = await db.execute(
        select(func.coalesce(func.sum(Withdrawal.amount), 0)).where(
            Withdrawal.user_id == user.id, Withdrawal.status == "pending"
        )
    )
    pending_withdrawals = pending_withdrawals_result.scalar()

    return {
        "balance": user.wallet_balance,
        "pending_deposits": pending_deposits,
        "pending_withdrawals": pending_withdrawals,
    }


async def get_transactions(
    user: User, db: AsyncSession, skip: int = 0, limit: int = 50
) -> list[WalletTransaction]:
    """Get paginated wallet transactions."""
    result = await db.execute(
        select(WalletTransaction)
        .where(WalletTransaction.user_id == user.id)
        .order_by(WalletTransaction.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()


async def create_deposit(
    user: User,
    amount: Decimal,
    transaction_ref: str | None,
    payment_proof_filename: str | None,
    db: AsyncSession,
) -> Deposit:
    """Create a new deposit request (pending admin approval)."""
    deposit = Deposit(
        user_id=user.id,
        amount=amount,
        status="pending",
        transaction_ref=transaction_ref,
        payment_proof_filename=payment_proof_filename,
    )
    db.add(deposit)
    await db.flush()
    return deposit


async def get_user_deposits(
    user: User,
    db: AsyncSession,
    skip: int = 0,
    limit: int = 50,
    status_filter: str | None = None,
) -> list[Deposit]:
    """Get paginated deposit history."""
    query = select(Deposit).where(Deposit.user_id == user.id)
    if status_filter:
        query = query.where(Deposit.status == status_filter.lower())

    query = query.order_by(Deposit.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


async def get_user_deposit_by_public_id(
    user: User,
    deposit_public_id: str,
    db: AsyncSession,
) -> Deposit:
    """Get a single deposit owned by the current user."""
    result = await db.execute(
        select(Deposit).where(
            Deposit.user_id == user.id,
            Deposit.public_id == deposit_public_id,
        )
    )
    deposit = result.scalar_one_or_none()
    if not deposit:
        raise HTTPException(status_code=404, detail="Deposit not found")
    return deposit


async def get_user_withdrawals(
    user: User,
    db: AsyncSession,
    skip: int = 0,
    limit: int = 50,
    status_filter: str | None = None,
) -> list[Withdrawal]:
    """Get paginated withdrawal history."""
    query = select(Withdrawal).where(Withdrawal.user_id == user.id)
    if status_filter:
        query = query.where(Withdrawal.status == status_filter.lower())

    query = query.order_by(Withdrawal.created_at.desc()).offset(skip).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


async def get_user_withdrawal_by_public_id(
    user: User,
    withdrawal_public_id: str,
    db: AsyncSession,
) -> Withdrawal:
    """Get a single withdrawal owned by the current user."""
    result = await db.execute(
        select(Withdrawal).where(
            Withdrawal.user_id == user.id,
            Withdrawal.public_id == withdrawal_public_id,
        )
    )
    withdrawal = result.scalar_one_or_none()
    if not withdrawal:
        raise HTTPException(status_code=404, detail="Withdrawal not found")
    return withdrawal


async def create_withdrawal(
    user: User,
    amount: Decimal,
    withdrawal_password: str,
    wallet_address: str | None,
    db: AsyncSession,
) -> Withdrawal:
    """Create a withdrawal request after verifying withdrawal password."""
    # Check withdrawal password is set
    if not user.withdrawal_password_hash:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Withdrawal password not set. Please set it first.",
        )

    # Verify withdrawal password
    if not verify_password(withdrawal_password, user.withdrawal_password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid withdrawal password",
        )

    # Check sufficient balance
    if user.wallet_balance < amount:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insufficient wallet balance",
        )

    withdrawal = Withdrawal(
        user_id=user.id,
        amount=amount,
        status="pending",
        wallet_address=wallet_address,
    )
    db.add(withdrawal)
    await db.flush()
    return withdrawal


async def set_withdrawal_password(
    user: User,
    new_withdrawal_password: str,
    current_withdrawal_password: str | None,
    db: AsyncSession,
) -> None:
    """Set or update the withdrawal password with verification for updates."""
    if user.withdrawal_password_hash:
        if not current_withdrawal_password:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current withdrawal password is required to update password",
            )

        if not verify_password(current_withdrawal_password, user.withdrawal_password_hash):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current withdrawal password is incorrect",
            )

    user.withdrawal_password_hash = hash_password(new_withdrawal_password)
    await db.flush()


async def approve_deposit(
    deposit_public_id: str,
    admin_note: str | None,
    db: AsyncSession,
) -> Deposit:
    """Admin approves a deposit — credits the user's wallet."""
    result = await db.execute(select(Deposit).where(Deposit.public_id == deposit_public_id))
    deposit = result.scalar_one_or_none()

    if not deposit:
        raise HTTPException(status_code=404, detail="Deposit not found")
    if deposit.status != "pending":
        raise HTTPException(status_code=400, detail="Deposit already processed")

    deposit.status = "approved"
    deposit.admin_note = admin_note

    # Credit user wallet
    user_result = await db.execute(select(User).where(User.id == deposit.user_id))
    user = user_result.scalar_one()
    user.wallet_balance += deposit.amount

    # Create wallet transaction
    txn = WalletTransaction(
        user_id=user.id,
        type="deposit",
        amount=deposit.amount,
        description=f"Deposit approved (ref: {deposit.transaction_ref or 'N/A'})",
    )
    db.add(txn)

    delete_payment_proof(deposit.payment_proof_filename)
    deposit.payment_proof_filename = None

    await db.flush()

    # Update referral deposit tracking
    from app.models.referral import Referral

    if user.referred_by:
        ref_result = await db.execute(
            select(Referral).where(
                Referral.referred_user_id == user.id,
                Referral.referrer_id == user.referred_by,
            )
        )
        referral = ref_result.scalar_one_or_none()
        if referral and referral.status == "pending":
            referral.deposit_amount += deposit.amount
            referral.status = "qualified"

    return deposit


async def reject_deposit(
    deposit_id: str,
    admin_note: str | None,
    db: AsyncSession,
) -> Deposit:
    """Admin rejects a deposit."""
    result = await db.execute(select(Deposit).where(Deposit.public_id == deposit_id))
    deposit = result.scalar_one_or_none()

    if not deposit:
        raise HTTPException(status_code=404, detail="Deposit not found")
    if deposit.status != "pending":
        raise HTTPException(status_code=400, detail="Deposit already processed")

    deposit.status = "rejected"
    deposit.admin_note = admin_note
    await db.flush()
    return deposit


async def approve_withdrawal(
    withdrawal_id: str,
    admin_note: str | None,
    db: AsyncSession,
) -> Withdrawal:
    """Admin approves a withdrawal — debits the user's wallet."""
    result = await db.execute(
        select(Withdrawal).where(Withdrawal.public_id == withdrawal_id)
    )
    withdrawal = result.scalar_one_or_none()

    if not withdrawal:
        raise HTTPException(status_code=404, detail="Withdrawal not found")
    if withdrawal.status != "pending":
        raise HTTPException(status_code=400, detail="Withdrawal already processed")

    # Get user and verify balance
    user_result = await db.execute(select(User).where(User.id == withdrawal.user_id))
    user = user_result.scalar_one()

    if user.wallet_balance < withdrawal.amount:
        raise HTTPException(status_code=400, detail="User has insufficient balance")

    withdrawal.status = "approved"
    withdrawal.admin_note = admin_note

    # Debit wallet
    user.wallet_balance -= withdrawal.amount

    # Create wallet transaction
    txn = WalletTransaction(
        user_id=user.id,
        type="withdrawal",
        amount=-withdrawal.amount,
        description=f"Withdrawal approved to {withdrawal.wallet_address or 'N/A'}",
    )
    db.add(txn)
    await db.flush()
    return withdrawal


async def reject_withdrawal(
    withdrawal_id: str,
    admin_note: str | None,
    db: AsyncSession,
) -> Withdrawal:
    """Admin rejects a withdrawal."""
    result = await db.execute(
        select(Withdrawal).where(Withdrawal.public_id == withdrawal_id)
    )
    withdrawal = result.scalar_one_or_none()

    if not withdrawal:
        raise HTTPException(status_code=404, detail="Withdrawal not found")
    if withdrawal.status != "pending":
        raise HTTPException(status_code=400, detail="Withdrawal already processed")

    withdrawal.status = "rejected"
    withdrawal.admin_note = admin_note
    await db.flush()
    return withdrawal
