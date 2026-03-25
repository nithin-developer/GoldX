"""
Profit Worker

This module processes completed signal entries and credits profits to user wallets.
Designed to be called as a background task or via Celery.

Usage (standalone):
    python -m app.workers.profit_worker

Usage (with FastAPI BackgroundTasks):
    BackgroundTasks.add_task(run_profit_calculation)
"""

import asyncio
import logging
from app.core.database import async_session_factory
from app.services.signal_service import process_completed_signals

logger = logging.getLogger(__name__)


async def run_profit_calculation():
    """Process all completed signal entries and credit profits."""
    async with async_session_factory() as session:
        try:
            processed = await process_completed_signals(session)
            await session.commit()
            if processed > 0:
                logger.info(f"Profit worker: processed {processed} completed signals")
            return processed
        except Exception as e:
            await session.rollback()
            logger.error(f"Profit worker error: {e}")
            raise


async def run_periodic_profit_worker(interval_seconds: int = 60):
    """Run profit calculation periodically."""
    while True:
        try:
            await run_profit_calculation()
        except Exception as e:
            logger.error(f"Periodic profit worker error: {e}")
        await asyncio.sleep(interval_seconds)


if __name__ == "__main__":
    asyncio.run(run_profit_calculation())
