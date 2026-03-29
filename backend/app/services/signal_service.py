import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status
from app.models.signal import Signal, SignalCode, UserSignalEntry
from app.models.user import User
from app.models.wallet import WalletTransaction


MIN_SIGNAL_ACTIVATION_BALANCE = Decimal("100")


def _normalize_signal_public_id(signal_id: str) -> str:
    try:
        return str(uuid.UUID(str(signal_id)))
    except (TypeError, ValueError) as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invalid signal id",
        ) from exc


async def _get_signal_by_public_id(signal_id: str, db: AsyncSession) -> Signal:
    normalized_id = _normalize_signal_public_id(signal_id)
    result = await db.execute(select(Signal).where(Signal.public_id == normalized_id))
    signal = result.scalar_one_or_none()

    if not signal:
        raise HTTPException(status_code=404, detail="Signal not found")

    return signal


async def get_active_signals(db: AsyncSession) -> list[Signal]:
    """Get all active signals."""
    result = await db.execute(
        select(Signal)
        .where(Signal.status == "active")
        .order_by(Signal.created_at.desc())
    )
    return result.scalars().all()


async def get_all_signals(db: AsyncSession, skip: int = 0, limit: int = 50) -> list[Signal]:
    """Get all signals (admin)."""
    result = await db.execute(
        select(Signal)
        .order_by(Signal.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()


async def create_signal(
    asset: str, direction: str, profit_percent: float, duration_hours: int, db: AsyncSession
) -> Signal:
    """Admin creates a new signal."""
    signal = Signal(
        asset=asset.upper(),
        direction=direction.lower(),
        profit_percent=profit_percent,
        duration_hours=duration_hours,
        status="active",
    )
    db.add(signal)
    await db.flush()
    return signal


async def update_signal(signal_id: str, data: dict, db: AsyncSession) -> Signal:
    """Admin updates a signal."""
    signal = await _get_signal_by_public_id(signal_id, db)

    for key, value in data.items():
        if value is not None:
            if key == "asset":
                value = str(value).upper()
            elif key == "direction":
                value = str(value).lower()
            setattr(signal, key, value)

    await db.flush()
    return signal


async def delete_signal(signal_id: str, db: AsyncSession) -> None:
    """Admin deletes a signal."""
    signal = await _get_signal_by_public_id(signal_id, db)

    await db.delete(signal)
    await db.flush()


async def generate_signal_codes(
    signal_id: str, expires_in_hours: int, count: int, db: AsyncSession
) -> SignalCode:
    """Admin generates one activation code per signal and reuses it afterward."""
    signal = await _get_signal_by_public_id(signal_id, db)

    existing_result = await db.execute(
        select(SignalCode)
        .where(SignalCode.signal_id == signal.id)
        .order_by(SignalCode.created_at.asc())
        .limit(1)
    )
    existing_code = existing_result.scalar_one_or_none()

    if existing_code is not None:
        setattr(existing_code, "signal_public_id", signal.public_id)
        return existing_code

    if count != 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only one activation code can be generated per signal",
        )

    expires_at = datetime.now(timezone.utc) + timedelta(hours=expires_in_hours)
    code_str = f"{signal.asset}{uuid.uuid4().hex[:6].upper()}"
    code = SignalCode(
        signal_id=signal.id,
        code=code_str,
        expires_at=expires_at,
    )
    db.add(code)

    await db.flush()
    setattr(code, "signal_public_id", signal.public_id)
    return code


async def activate_signal(user: User, signal_code: str, db: AsyncSession) -> UserSignalEntry:
    """User activates a signal using a code."""
    normalized_code = signal_code.strip().upper()

    # 1. Validate code exists
    result = await db.execute(
        select(SignalCode).where(SignalCode.code == normalized_code)
    )
    code = result.scalar_one_or_none()

    if not code:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid signal code",
        )

    # 2. Check if already used
    if code.used:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Signal code has already been used",
        )

    # 3. Check expiry
    if code.expires_at < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Signal code has expired",
        )

    # 4. Fetch signal
    signal_result = await db.execute(
        select(Signal).where(Signal.id == code.signal_id)
    )
    signal = signal_result.scalar_one_or_none()

    if not signal or signal.status != "active":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Signal is not active",
        )

    # 5. Check user has balance
    wallet_balance = Decimal(str(user.wallet_balance or 0))
    if wallet_balance < MIN_SIGNAL_ACTIVATION_BALANCE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Minimum $100 wallet balance is required to activate a signal",
        )

    # 6. Calculate participation (use full wallet balance)
    participation_amount = wallet_balance
    entry_balance = wallet_balance

    # 7. Create user signal entry
    now = datetime.now(timezone.utc)
    entry = UserSignalEntry(
        user_id=user.id,
        signal_id=signal.id,
        entry_balance=entry_balance,
        participation_amount=participation_amount,
        profit_percent=signal.profit_percent,
        status="active",
        started_at=now,
        ends_at=now + timedelta(hours=signal.duration_hours),
    )
    db.add(entry)
    entry.signal = signal
    setattr(entry, "signal_public_id", signal.public_id)

    # 8. Mark code as used
    code.used = True
    code.used_by = user.id

    await db.flush()
    return entry


async def get_user_signal_history(
    user: User, db: AsyncSession, skip: int = 0, limit: int = 50
) -> list[UserSignalEntry]:
    """Get user's signal participation history."""
    result = await db.execute(
        select(UserSignalEntry)
        .options(selectinload(UserSignalEntry.signal))
        .where(UserSignalEntry.user_id == user.id)
        .order_by(UserSignalEntry.started_at.desc())
        .offset(skip)
        .limit(limit)
    )
    entries = result.scalars().all()
    for entry in entries:
        signal_public_id = entry.signal.public_id if entry.signal else str(entry.signal_id)
        setattr(entry, "signal_public_id", signal_public_id)
    return entries


async def process_completed_signals(db: AsyncSession) -> int:
    """Background job: process signals that have ended and credit profits."""
    now = datetime.now(timezone.utc)

    result = await db.execute(
        select(UserSignalEntry).where(
            UserSignalEntry.status == "active",
            UserSignalEntry.ends_at <= now,
        )
    )
    entries = result.scalars().all()
    processed = 0

    for entry in entries:
        # Calculate profit
        profit = entry.entry_balance * Decimal(str(entry.profit_percent / 100))
        entry.profit_amount = profit
        entry.status = "completed"
        entry.completed_at = now

        # Credit user wallet
        user_result = await db.execute(select(User).where(User.id == entry.user_id))
        user = user_result.scalar_one()
        user.wallet_balance += profit

        # Create transaction record
        txn = WalletTransaction(
            user_id=user.id,
            type="signal_profit",
            amount=profit,
            description=f"Signal profit ({entry.profit_percent}%) on {entry.entry_balance}",
        )
        db.add(txn)
        processed += 1

    await db.flush()
    return processed
