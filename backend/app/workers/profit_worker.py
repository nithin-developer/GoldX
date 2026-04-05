# app/workers/profit_worker.py

import asyncio
import logging
from datetime import datetime, timezone
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import async_session_factory
from app.models.signal import UserSignalEntry
from app.models.user import User
from app.models.wallet import WalletTransaction

logger = logging.getLogger(__name__)


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

            profit = signal.entry_balance * (signal.profit_percent / 100)

            # Update wallet
            user.wallet_balance += profit

            # Create transaction record
            tx = WalletTransaction(
                user_id=user.id,
                type="signal_profit",
                amount=profit,
                description=f"Profit from {signal.signal_id}",
            )
            session.add(tx)

            # Mark signal completed
            signal.status = "completed"

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