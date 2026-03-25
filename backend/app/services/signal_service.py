import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status
from app.models.signal import Signal, SignalCode, UserSignalEntry
from app.models.user import User
from app.models.wallet import WalletTransaction


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


async def update_signal(signal_id: int, data: dict, db: AsyncSession) -> Signal:
    """Admin updates a signal."""
    result = await db.execute(select(Signal).where(Signal.id == signal_id))
    signal = result.scalar_one_or_none()

    if not signal:
        raise HTTPException(status_code=404, detail="Signal not found")

    for key, value in data.items():
        if value is not None:
            setattr(signal, key, value)

    await db.flush()
    return signal


async def delete_signal(signal_id: int, db: AsyncSession) -> None:
    """Admin deletes a signal."""
    result = await db.execute(select(Signal).where(Signal.id == signal_id))
    signal = result.scalar_one_or_none()

    if not signal:
        raise HTTPException(status_code=404, detail="Signal not found")

    await db.delete(signal)
    await db.flush()


async def generate_signal_codes(
    signal_id: int, expires_in_hours: int, count: int, db: AsyncSession
) -> list[SignalCode]:
    """Admin generates unique activation codes for a signal."""
    result = await db.execute(select(Signal).where(Signal.id == signal_id))
    signal = result.scalar_one_or_none()

    if not signal:
        raise HTTPException(status_code=404, detail="Signal not found")

    codes = []
    expires_at = datetime.now(timezone.utc) + timedelta(hours=expires_in_hours)

    for _ in range(count):
        code_str = f"{signal.asset}{uuid.uuid4().hex[:6].upper()}"
        code = SignalCode(
            signal_id=signal.id,
            code=code_str,
            expires_at=expires_at,
        )
        db.add(code)
        codes.append(code)

    await db.flush()
    return codes


async def activate_signal(user: User, signal_code: str, db: AsyncSession) -> UserSignalEntry:
    """User activates a signal using a code."""
    # 1. Validate code exists
    result = await db.execute(
        select(SignalCode).where(SignalCode.code == signal_code)
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
    if user.wallet_balance <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Insufficient wallet balance to participate",
        )

    # 6. Calculate participation (use full wallet balance)
    participation_amount = user.wallet_balance
    entry_balance = user.wallet_balance

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
        .where(UserSignalEntry.user_id == user.id)
        .order_by(UserSignalEntry.started_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()


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
