import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select
from sqlalchemy.orm import selectinload
from fastapi import HTTPException, status
from app.models.signal import Signal, SignalCode, UserSignalEntry
from app.models.user import User
from app.models.wallet import WalletTransaction
from app.services.wallet_service import sync_user_total_balance


MIN_SIGNAL_ACTIVATION_BALANCE = Decimal("100")
_VALID_DURATION_UNITS = {"hours", "minutes"}


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


def _normalize_duration_unit(duration_unit: str | None) -> str:
    normalized = str(duration_unit or "hours").strip().lower()
    aliases = {
        "h": "hours",
        "hr": "hours",
        "hrs": "hours",
        "hour": "hours",
        "hours": "hours",
        "m": "minutes",
        "min": "minutes",
        "mins": "minutes",
        "minute": "minutes",
        "minutes": "minutes",
    }
    mapped = aliases.get(normalized)
    if mapped is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="duration_unit must be either 'hours' or 'minutes'",
        )
    return mapped


def _signal_duration_delta(signal: Signal) -> timedelta:
    duration_value = int(signal.duration_hours or 0)
    if duration_value <= 0:
        return timedelta(0)

    raw_unit = str(getattr(signal, "duration_unit", "hours") or "hours").strip().lower()
    duration_unit = raw_unit if raw_unit in _VALID_DURATION_UNITS else "hours"
    if duration_unit == "minutes":
        return timedelta(minutes=duration_value)
    return timedelta(hours=duration_value)


def _signal_is_expired(signal: Signal, *, at: datetime | None = None) -> bool:
    normalized_status = (signal.status or "").strip().lower()
    if normalized_status in {"expired", "completed"}:
        return True

    duration_delta = _signal_duration_delta(signal)
    if duration_delta <= timedelta(0):
        return False

    reference_time = at or datetime.now(timezone.utc)
    created_at = signal.created_at or reference_time
    if created_at.tzinfo is None:
        created_at = created_at.replace(tzinfo=timezone.utc)

    return reference_time >= created_at + duration_delta


async def _set_signal_activation_metadata(
    signals: list[Signal],
    db: AsyncSession,
    user_id: int | None = None,
) -> None:
    if not signals:
        return

    signal_ids = [signal.id for signal in signals]
    count_rows = await db.execute(
        select(UserSignalEntry.signal_id, func.count(UserSignalEntry.id))
        .where(UserSignalEntry.signal_id.in_(signal_ids))
        .group_by(UserSignalEntry.signal_id)
    )
    activation_counts = {
        int(signal_id): int(count)
        for signal_id, count in count_rows.all()
        if signal_id is not None
    }

    activated_signal_ids: set[int] = set()
    if user_id is not None:
        activated_rows = await db.execute(
            select(UserSignalEntry.signal_id)
            .where(
                UserSignalEntry.user_id == user_id,
                UserSignalEntry.signal_id.in_(signal_ids),
            )
            .distinct()
        )
        activated_signal_ids = {
            int(signal_id)
            for (signal_id,) in activated_rows.all()
            if signal_id is not None
        }

    for signal in signals:
        setattr(signal, "activated_users_count", activation_counts.get(signal.id, 0))
        setattr(signal, "already_activated", signal.id in activated_signal_ids)


async def get_active_signals(
    db: AsyncSession,
    user_id: int | None = None,
) -> list[Signal]:
    """Get all active signals."""
    result = await db.execute(
        select(Signal)
        .where(Signal.status == "active")
        .order_by(Signal.created_at.desc())
    )
    signals = result.scalars().all()
    await _set_signal_activation_metadata(signals, db, user_id=user_id)
    return signals


async def get_all_signals(
    db: AsyncSession,
    skip: int = 0,
    limit: int = 50,
    user_id: int | None = None,
) -> list[Signal]:
    """Get all signals (admin)."""
    result = await db.execute(
        select(Signal)
        .order_by(Signal.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    signals = result.scalars().all()
    await _set_signal_activation_metadata(signals, db, user_id=user_id)
    return signals


async def create_signal(
    asset: str,
    direction: str,
    profit_percent: float,
    duration_hours: int,
    duration_unit: str,
    vip_only: bool,
    db: AsyncSession,
) -> Signal:
    """Admin creates a new signal."""
    signal = Signal(
        asset=asset.upper(),
        direction=direction.lower(),
        profit_percent=profit_percent,
        duration_hours=duration_hours,
        duration_unit=_normalize_duration_unit(duration_unit),
        status="active",
        vip_only=vip_only,
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
            elif key == "duration_unit":
                value = _normalize_duration_unit(str(value))
            setattr(signal, key, value)

    if getattr(signal, "duration_unit", None) not in _VALID_DURATION_UNITS:
        signal.duration_unit = "hours"

    await db.flush()
    return signal


async def delete_signal(signal_id: str, db: AsyncSession) -> None:
    """Admin deletes a signal."""
    signal = await _get_signal_by_public_id(signal_id, db)

    activation_count_result = await db.execute(
        select(func.count(UserSignalEntry.id)).where(UserSignalEntry.signal_id == signal.id)
    )
    activation_count = int(activation_count_result.scalar_one() or 0)
    if activation_count > 0 and not _signal_is_expired(signal):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=(
                "This signal already has activated users and cannot be deleted until it expires"
            ),
        )

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
    activation_count_result = await db.execute(
        select(func.count(UserSignalEntry.id)).where(UserSignalEntry.signal_id == signal.id)
    )
    activation_count = int(activation_count_result.scalar_one() or 0)

    if existing_code is not None:
        setattr(existing_code, "signal_public_id", signal.public_id)
        setattr(existing_code, "activated_users_count", activation_count)
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
    setattr(code, "activated_users_count", activation_count)
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

    # 2. Check expiry
    if code.expires_at < datetime.now(timezone.utc):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Signal code has expired",
        )

    # 3. Fetch signal
    signal_result = await db.execute(
        select(Signal).where(Signal.id == code.signal_id)
    )
    signal = signal_result.scalar_one_or_none()

    if not signal or signal.status != "active":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Signal is not active",
        )

    if signal.vip_only and int(user.vip_level or 0) <= 0:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This signal is available for VIP users only",
        )

    # 4. Prevent duplicate activation by the same user for the same signal.
    existing_entry_result = await db.execute(
        select(UserSignalEntry.id)
        .where(
            UserSignalEntry.user_id == user.id,
            UserSignalEntry.signal_id == signal.id,
        )
        .limit(1)
    )
    existing_entry_id = existing_entry_result.scalar_one_or_none()
    if existing_entry_id is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Signal already activated",
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
        ends_at=now + _signal_duration_delta(signal),
    )
    db.add(entry)
    entry.signal = signal
    setattr(entry, "signal_public_id", signal.public_id)

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

        # Credit signal profit bucket and sync aggregate balance.
        user_result = await db.execute(select(User).where(User.id == entry.user_id))
        user = user_result.scalar_one()
        user.signal_profit_balance = Decimal(str(user.signal_profit_balance or 0)) + profit
        sync_user_total_balance(user)

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
