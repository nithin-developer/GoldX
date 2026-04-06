# app/workers/profit_worker.py

import asyncio
import logging
from decimal import Decimal
from datetime import datetime, timezone
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import async_session_factory
from app.models.referral import Referral
from app.models.signal import UserSignalEntry
from app.models.user import User
from app.models.wallet import WalletTransaction
from app.services.vip_service import (
    MIN_QUALIFYING_DEPOSIT,
    QUALIFIED_REFERRAL_STATUSES,
    calculate_team_profit_amount,
    quantize_money,
    recalculate_user_vip_level,
)
from app.services.wallet_service import sync_user_total_balance

logger = logging.getLogger(__name__)


def _to_decimal(value: Decimal | int | float | str | None) -> Decimal:
    if value is None:
        return Decimal("0")
    return Decimal(str(value))


async def _credit_team_profit(
    session: AsyncSession,
    trader: User,
    signal_entry: UserSignalEntry,
    trade_profit: Decimal,
) -> Decimal:
    if trade_profit <= 0 or not trader.referred_by:
        return Decimal("0.00")

    referral_result = await session.execute(
        select(Referral).where(
            Referral.referred_user_id == trader.id,
            Referral.referrer_id == trader.referred_by,
            Referral.deposit_amount >= MIN_QUALIFYING_DEPOSIT,
            Referral.status.in_(QUALIFIED_REFERRAL_STATUSES),
        )
    )
    referral = referral_result.scalar_one_or_none()
    if referral is None:
        return Decimal("0.00")

    referrer = await session.get(User, referral.referrer_id)
    if referrer is None or not referrer.is_active:
        return Decimal("0.00")

    referrer_vip_level = await recalculate_user_vip_level(session, referrer)
    team_profit = calculate_team_profit_amount(trade_profit, referrer_vip_level)
    if team_profit <= 0:
        return Decimal("0.00")

    referrer.reward_balance = _to_decimal(referrer.reward_balance) + team_profit
    sync_user_total_balance(referrer)
    referral.bonus_amount = quantize_money(_to_decimal(referral.bonus_amount) + team_profit)
    referral.status = "rewarded"

    session.add(
        WalletTransaction(
            user_id=referrer.id,
            type="team_profit",
            amount=team_profit,
            description=(
                f"Team profit from referral user {trader.id} "
                f"on signal {signal_entry.signal_id}"
            ),
        )
    )

    return team_profit


async def process_completed_signals(session: AsyncSession):
    """Process signals that have ended and credit profit safely."""
    now = datetime.now(timezone.utc)

    result = await session.execute(
        select(UserSignalEntry)
        .where(
            UserSignalEntry.status == "active",
            UserSignalEntry.ends_at <= now,
        )
        .with_for_update(skip_locked=True)
    )

    signals = result.scalars().all()
    processed = 0

    for signal in signals:
        try:
            user = await session.get(User, signal.user_id)
            if user is None:
                signal.status = "cancelled"
                signal.completed_at = now
                logger.warning(f"Signal entry {signal.id} has no user; marked as cancelled")
                continue

            entry_balance = _to_decimal(signal.entry_balance)
            profit_percent = _to_decimal(signal.profit_percent)
            profit = quantize_money(entry_balance * (profit_percent / Decimal("100")))

            # Credit signal profits in the dedicated bucket.
            user.signal_profit_balance = _to_decimal(user.signal_profit_balance) + profit
            sync_user_total_balance(user)

            # Create transaction record
            tx = WalletTransaction(
                user_id=user.id,
                type="signal_profit",
                amount=profit,
                description=f"Profit from {signal.signal_id}",
            )
            session.add(tx)

            signal.profit_amount = profit
            # Mark signal completed
            signal.status = "completed"
            signal.completed_at = now

            team_profit = await _credit_team_profit(session, user, signal, profit)
            if team_profit > 0:
                logger.info(
                    f"Credited team profit {team_profit} from signal entry {signal.id}"
                )

            processed += 1

        except Exception as e:
            logger.error(f"Error processing signal {signal.id}: {e}")

    return processed


async def run_profit_calculation():
    async with async_session_factory() as session:
        try:
            processed = await process_completed_signals(session)
            await session.commit()

            if processed > 0:
                logger.info(f"Processed {processed} signals")

        except Exception as e:
            await session.rollback()
            logger.error(f"Profit worker error: {e}")
            raise


async def run_periodic_profit_worker(interval_seconds: int = 3600):
    try:
        while True:
            try:
                await run_profit_calculation()
            except Exception:
                logger.exception("Periodic profit worker run failed")

            await asyncio.sleep(interval_seconds)
    except asyncio.CancelledError:
        logger.info("Periodic profit worker cancelled")
        raise