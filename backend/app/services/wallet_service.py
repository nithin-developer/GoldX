from datetime import datetime, timedelta, timezone
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
from uuid import uuid4
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from fastapi import HTTPException, UploadFile, status
from app.core.config import settings
from app.models.referral import Referral
from app.models.user import User
from app.models.wallet import WalletTransaction, Deposit, Withdrawal
from app.models.system_settings import DepositWalletSetting
from app.core.security import hash_password, verify_password
from app.services.vip_service import recalculate_user_vip_level, sync_referral_status_from_deposit


ALLOWED_QR_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
ALLOWED_PAYMENT_PROOF_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
INITIAL_CAPITAL_LOCK_DAYS = 12
_MONEY_QUANTIZER = Decimal("0.01")
WITHDRAWAL_FEE_RATE = Decimal("0.10")
WITHDRAWAL_FEE_PERCENT = Decimal("10.00")
WITHDRAWAL_FEE_NOTICE = "10% withdrawal fee will be deducted from any withdrawal"
SELF_DEPOSIT_REWARD_RATE = Decimal("0.06")
REFERRED_USER_DEPOSIT_REWARD_RATE = Decimal("0.03")
REFERRER_DEPOSIT_REWARD_RATE = Decimal("0.06")


def _to_decimal(value: Decimal | int | float | str | None) -> Decimal:
    if value is None:
        return Decimal("0")
    return Decimal(str(value))


def _quantize_money(value: Decimal | int | float | str | None) -> Decimal:
    return _to_decimal(value).quantize(_MONEY_QUANTIZER, rounding=ROUND_HALF_UP)


def _calculate_percentage(amount: Decimal, rate: Decimal) -> Decimal:
    return _quantize_money(_to_decimal(amount) * _to_decimal(rate))


def _calculate_withdrawal_fee_breakdown(gross_amount: Decimal) -> dict:
    gross = _quantize_money(gross_amount)
    fee_amount = _calculate_percentage(gross, WITHDRAWAL_FEE_RATE)
    net_amount = _quantize_money(gross - fee_amount)
    return {
        "gross_amount": gross,
        "fee_rate_percent": _quantize_money(WITHDRAWAL_FEE_PERCENT),
        "fee_amount": fee_amount,
        "net_amount": net_amount,
    }


def sync_user_total_balance(user: User) -> Decimal:
    user.capital_balance = _quantize_money(user.capital_balance)
    user.signal_profit_balance = _quantize_money(user.signal_profit_balance)
    user.reward_balance = _quantize_money(user.reward_balance)
    user.wallet_balance = _quantize_money(
        _to_decimal(user.capital_balance)
        + _to_decimal(user.signal_profit_balance)
        + _to_decimal(user.reward_balance)
    )
    return _to_decimal(user.wallet_balance)


def get_capital_lock_ends_at(user: User) -> datetime | None:
    approved_at = user.first_deposit_approved_at
    if approved_at is None:
        return None

    if approved_at.tzinfo is None:
        approved_at = approved_at.replace(tzinfo=timezone.utc)

    return approved_at + timedelta(days=INITIAL_CAPITAL_LOCK_DAYS)


def get_locked_capital_balance(user: User, now: datetime | None = None) -> Decimal:
    lock_ends_at = get_capital_lock_ends_at(user)
    if lock_ends_at is None:
        return Decimal("0.00")

    current_time = now or datetime.now(timezone.utc)
    if current_time >= lock_ends_at:
        return Decimal("0.00")

    capital_balance = max(_to_decimal(user.capital_balance), Decimal("0"))
    lock_target = max(_to_decimal(user.initial_capital_locked_amount), Decimal("0"))

    return _quantize_money(min(capital_balance, lock_target))


def build_user_balance_breakdown(user: User, now: datetime | None = None) -> dict:
    current_time = now or datetime.now(timezone.utc)

    capital_balance = _quantize_money(user.capital_balance)
    signal_profit_balance = _quantize_money(user.signal_profit_balance)
    reward_balance = _quantize_money(user.reward_balance)
    total_balance = sync_user_total_balance(user)

    lock_ends_at = get_capital_lock_ends_at(user)
    locked_capital_balance = get_locked_capital_balance(user, current_time)
    unlocked_capital_balance = _quantize_money(
        max(capital_balance - locked_capital_balance, Decimal("0"))
    )
    withdrawable_balance = _quantize_money(
        unlocked_capital_balance + signal_profit_balance + reward_balance
    )

    capital_lock_active = (
        lock_ends_at is not None
        and current_time < lock_ends_at
        and locked_capital_balance > 0
    )

    capital_lock_days_remaining = 0
    if capital_lock_active and lock_ends_at is not None:
        lock_delta = lock_ends_at - current_time
        capital_lock_days_remaining = max(
            lock_delta.days + (1 if lock_delta.seconds > 0 else 0),
            0,
        )

    return {
        "balance": total_balance,
        "capital_balance": capital_balance,
        "signal_profit_balance": signal_profit_balance,
        "reward_balance": reward_balance,
        "withdrawable_balance": withdrawable_balance,
        "locked_capital_balance": locked_capital_balance,
        "unlocked_capital_balance": unlocked_capital_balance,
        "capital_lock_active": capital_lock_active,
        "capital_lock_ends_at": lock_ends_at,
        "capital_lock_days_remaining": capital_lock_days_remaining,
    }


def _allocate_withdrawal_sources(
    user: User,
    amount: Decimal,
    now: datetime | None = None,
    enforce_capital_lock: bool = True,
) -> dict:
    requested_amount = _quantize_money(amount)
    current_time = now or datetime.now(timezone.utc)

    reward_balance = max(_to_decimal(user.reward_balance), Decimal("0"))
    signal_profit_balance = max(_to_decimal(user.signal_profit_balance), Decimal("0"))
    capital_balance = max(_to_decimal(user.capital_balance), Decimal("0"))

    locked_capital_balance = (
        get_locked_capital_balance(user, current_time) if enforce_capital_lock else Decimal("0")
    )
    unlocked_capital_balance = max(capital_balance - locked_capital_balance, Decimal("0"))

    available_withdrawable = (
        reward_balance + signal_profit_balance + unlocked_capital_balance
    )

    if requested_amount > available_withdrawable:
        if enforce_capital_lock and locked_capital_balance > 0:
            lock_ends_at = get_capital_lock_ends_at(user)
            lock_date = (
                lock_ends_at.astimezone(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
                if lock_ends_at is not None
                else "after lock period"
            )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    "Insufficient withdrawable balance. "
                    f"{_quantize_money(locked_capital_balance)} capital is locked "
                    f"until {lock_date} (first deposit lock)."
                ),
            )

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insufficient withdrawable balance",
        )

    remaining = requested_amount

    reward_amount = min(remaining, reward_balance)
    remaining -= reward_amount

    signal_profit_amount = min(remaining, signal_profit_balance)
    remaining -= signal_profit_amount

    capital_amount = min(remaining, unlocked_capital_balance)
    remaining -= capital_amount

    if remaining > Decimal("0"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unable to allocate withdrawal amount from available balances",
        )

    return {
        "amount": requested_amount,
        "capital_amount": _quantize_money(capital_amount),
        "signal_profit_amount": _quantize_money(signal_profit_amount),
        "reward_amount": _quantize_money(reward_amount),
    }


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
        support_url=None,
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
    support_url: str | None,
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
    settings_data.support_url = (
        support_url.strip() if support_url and support_url.strip() else None
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
    """Get wallet totals, breakdown, and pending amounts."""
    sync_user_total_balance(user)

    # Pending deposits
    pending_deposits_result = await db.execute(
        select(func.coalesce(func.sum(Deposit.amount), 0)).where(
            Deposit.user_id == user.id, Deposit.status == "pending"
        )
    )
    pending_deposits = _quantize_money(pending_deposits_result.scalar())

    # Pending withdrawals
    pending_withdrawals_result = await db.execute(
        select(func.coalesce(func.sum(Withdrawal.amount), 0)).where(
            Withdrawal.user_id == user.id, Withdrawal.status == "pending"
        )
    )
    pending_withdrawals = _quantize_money(pending_withdrawals_result.scalar())

    breakdown = build_user_balance_breakdown(user)

    return {
        **breakdown,
        "withdrawal_fee_percent": _quantize_money(WITHDRAWAL_FEE_PERCENT),
        "withdrawal_fee_notice": WITHDRAWAL_FEE_NOTICE,
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
    """Create a withdrawal request after verifying password and source availability."""
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

    sync_user_total_balance(user)

    allocation = _allocate_withdrawal_sources(
        user,
        amount,
        enforce_capital_lock=True,
    )
    fee_breakdown = _calculate_withdrawal_fee_breakdown(allocation["amount"])

    withdrawal = Withdrawal(
        user_id=user.id,
        amount=fee_breakdown["gross_amount"],
        capital_amount=allocation["capital_amount"],
        signal_profit_amount=allocation["signal_profit_amount"],
        reward_amount=allocation["reward_amount"],
        fee_rate_percent=fee_breakdown["fee_rate_percent"],
        fee_amount=fee_breakdown["fee_amount"],
        net_amount=fee_breakdown["net_amount"],
        status="pending",
        wallet_address=wallet_address.strip() if wallet_address and wallet_address.strip() else None,
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
    """Admin approves a deposit and credits it as capital balance."""
    result = await db.execute(select(Deposit).where(Deposit.public_id == deposit_public_id))
    deposit = result.scalar_one_or_none()

    if not deposit:
        raise HTTPException(status_code=404, detail="Deposit not found")
    if deposit.status != "pending":
        raise HTTPException(status_code=400, detail="Deposit already processed")

    deposit.status = "approved"
    deposit.admin_note = admin_note

    # Credit user capital balance.
    user_result = await db.execute(select(User).where(User.id == deposit.user_id))
    user = user_result.scalar_one()

    credited_amount = _quantize_money(deposit.amount)
    user.capital_balance = _quantize_money(_to_decimal(user.capital_balance) + credited_amount)

    if user.first_deposit_approved_at is None:
        user.first_deposit_approved_at = datetime.now(timezone.utc)
        if _to_decimal(user.initial_capital_locked_amount) <= 0:
            user.initial_capital_locked_amount = credited_amount

    # Self deposit reward: regular users get 6%, referred users get 3%.
    self_reward_rate = (
        REFERRED_USER_DEPOSIT_REWARD_RATE
        if user.referred_by
        else SELF_DEPOSIT_REWARD_RATE
    )
    self_reward_amount = _calculate_percentage(credited_amount, self_reward_rate)
    deposit.self_reward_amount = self_reward_amount
    deposit.referrer_reward_amount = Decimal("0.00")

    if self_reward_amount > Decimal("0"):
        user.reward_balance = _quantize_money(
            _to_decimal(user.reward_balance) + self_reward_amount
        )

    sync_user_total_balance(user)

    db.add(
        WalletTransaction(
            user_id=user.id,
            type="deposit",
            amount=credited_amount,
            description=f"Deposit approved (ref: {deposit.transaction_ref or 'N/A'})",
        )
    )

    if self_reward_amount > Decimal("0"):
        db.add(
            WalletTransaction(
                user_id=user.id,
                type="deposit_reward",
                amount=self_reward_amount,
                description=(
                    f"Deposit reward credited at {(self_reward_rate * Decimal('100')).quantize(_MONEY_QUANTIZER)}% "
                    f"for approved deposit {deposit.public_id}"
                ),
            )
        )

    delete_payment_proof(deposit.payment_proof_filename)
    deposit.payment_proof_filename = None

    await db.flush()

    # Update referral deposit tracking
    if user.referred_by:
        ref_result = await db.execute(
            select(Referral).where(
                Referral.referred_user_id == user.id,
                Referral.referrer_id == user.referred_by,
            )
        )
        referral = ref_result.scalar_one_or_none()
        if referral is None:
            referral = Referral(
                referrer_id=user.referred_by,
                referred_user_id=user.id,
                deposit_amount=Decimal("0"),
                status="pending",
            )
            db.add(referral)

        referral.deposit_amount = _quantize_money(
            _to_decimal(referral.deposit_amount) + credited_amount
        )
        sync_referral_status_from_deposit(referral)

        referrer = await db.get(User, user.referred_by)
        if referrer is not None and referrer.is_active:
            referrer_reward_amount = _calculate_percentage(
                credited_amount,
                REFERRER_DEPOSIT_REWARD_RATE,
            )
            deposit.referrer_reward_amount = referrer_reward_amount

            if referrer_reward_amount > Decimal("0"):
                referrer.reward_balance = _quantize_money(
                    _to_decimal(referrer.reward_balance) + referrer_reward_amount
                )
                sync_user_total_balance(referrer)
                referral.bonus_amount = _quantize_money(
                    _to_decimal(referral.bonus_amount) + referrer_reward_amount
                )

                db.add(
                    WalletTransaction(
                        user_id=referrer.id,
                        type="referral_reward",
                        amount=referrer_reward_amount,
                        description=(
                            f"Referral reward from invited user {user.id} deposit {deposit.public_id}"
                        ),
                    )
                )

            await recalculate_user_vip_level(db, referrer)

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
    """Admin approves a withdrawal and debits source balances."""
    result = await db.execute(
        select(Withdrawal).where(Withdrawal.public_id == withdrawal_id)
    )
    withdrawal = result.scalar_one_or_none()

    if not withdrawal:
        raise HTTPException(status_code=404, detail="Withdrawal not found")
    if withdrawal.status != "pending":
        raise HTTPException(status_code=400, detail="Withdrawal already processed")

    # Get user and verify source balances.
    user_result = await db.execute(select(User).where(User.id == withdrawal.user_id))
    user = user_result.scalar_one()
    sync_user_total_balance(user)

    fee_rate_percent = _quantize_money(withdrawal.fee_rate_percent)
    fee_amount = _quantize_money(withdrawal.fee_amount)
    net_amount = _quantize_money(withdrawal.net_amount)

    if (
        fee_rate_percent <= Decimal("0")
        or (fee_amount <= Decimal("0") and _to_decimal(withdrawal.amount) > Decimal("0"))
        or (net_amount <= Decimal("0") and _to_decimal(withdrawal.amount) > Decimal("0"))
    ):
        fee_breakdown = _calculate_withdrawal_fee_breakdown(_to_decimal(withdrawal.amount))
        fee_rate_percent = fee_breakdown["fee_rate_percent"]
        fee_amount = fee_breakdown["fee_amount"]
        net_amount = fee_breakdown["net_amount"]

    withdrawal.fee_rate_percent = fee_rate_percent
    withdrawal.fee_amount = fee_amount
    withdrawal.net_amount = net_amount

    stored_source_total = (
        _to_decimal(withdrawal.capital_amount)
        + _to_decimal(withdrawal.signal_profit_amount)
        + _to_decimal(withdrawal.reward_amount)
    )

    if stored_source_total > Decimal("0"):
        allocation = {
            "amount": _quantize_money(withdrawal.amount),
            "capital_amount": _quantize_money(withdrawal.capital_amount),
            "signal_profit_amount": _quantize_money(withdrawal.signal_profit_amount),
            "reward_amount": _quantize_money(withdrawal.reward_amount),
        }

        has_sufficient_source_balances = (
            _to_decimal(user.reward_balance) >= allocation["reward_amount"]
            and _to_decimal(user.signal_profit_balance) >= allocation["signal_profit_amount"]
            and _to_decimal(user.capital_balance) >= allocation["capital_amount"]
        )

        if not has_sufficient_source_balances:
            allocation = _allocate_withdrawal_sources(
                user,
                _to_decimal(withdrawal.amount),
                enforce_capital_lock=True,
            )
    else:
        # Legacy rows created before source tracking are reallocated from current balances.
        allocation = _allocate_withdrawal_sources(
            user,
            _to_decimal(withdrawal.amount),
            enforce_capital_lock=False,
        )

    capital_amount = _to_decimal(allocation["capital_amount"])
    signal_profit_amount = _to_decimal(allocation["signal_profit_amount"])
    reward_amount = _to_decimal(allocation["reward_amount"])

    if (
        _to_decimal(user.reward_balance) < reward_amount
        or _to_decimal(user.signal_profit_balance) < signal_profit_amount
        or _to_decimal(user.capital_balance) < capital_amount
    ):
        raise HTTPException(status_code=400, detail="User has insufficient source balances")

    withdrawal.status = "approved"
    withdrawal.admin_note = admin_note
    withdrawal.capital_amount = _quantize_money(capital_amount)
    withdrawal.signal_profit_amount = _quantize_money(signal_profit_amount)
    withdrawal.reward_amount = _quantize_money(reward_amount)

    # Debit source balances.
    user.reward_balance = _quantize_money(_to_decimal(user.reward_balance) - reward_amount)
    user.signal_profit_balance = _quantize_money(
        _to_decimal(user.signal_profit_balance) - signal_profit_amount
    )
    user.capital_balance = _quantize_money(_to_decimal(user.capital_balance) - capital_amount)

    lock_ends_at = get_capital_lock_ends_at(user)
    if (
        capital_amount > 0
        and _to_decimal(user.initial_capital_locked_amount) > 0
        and (lock_ends_at is None or datetime.now(timezone.utc) >= lock_ends_at)
    ):
        user.initial_capital_locked_amount = _quantize_money(
            max(_to_decimal(user.initial_capital_locked_amount) - capital_amount, Decimal("0"))
        )

    sync_user_total_balance(user)

    # Create wallet transaction
    txn = WalletTransaction(
        user_id=user.id,
        type="withdrawal",
        amount=-_quantize_money(withdrawal.amount),
        description=(
            f"Withdrawal approved to {withdrawal.wallet_address or 'N/A'} "
            f"(fee: {withdrawal.fee_amount}, net: {withdrawal.net_amount}, "
            f"capital: {withdrawal.capital_amount}, "
            f"signal_profit: {withdrawal.signal_profit_amount}, "
            f"rewards: {withdrawal.reward_amount})"
        ),
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
