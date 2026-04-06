# app/workers/vip_worker.py

import asyncio
import logging

from app.core.database import async_session_factory
from app.services.vip_service import normalize_referrals_and_recalculate_vip

logger = logging.getLogger(__name__)


async def run_vip_validation():
    async with async_session_factory() as session:
        try:
            referral_updates, vip_updates = await normalize_referrals_and_recalculate_vip(
                session
            )

            await session.commit()

            if referral_updates > 0:
                logger.info(f"Normalized {referral_updates} referral qualification statuses")
            if vip_updates > 0:
                logger.info(f"Updated {vip_updates} VIP levels")

        except Exception as e:
            await session.rollback()
            logger.error(f"VIP worker error: {e}")
            raise


async def run_periodic_vip_worker(interval_seconds: int = 3600):
    try:
        while True:
            try:
                await run_vip_validation()
            except Exception:
                logger.exception("Periodic VIP validation run failed")

            await asyncio.sleep(interval_seconds)
    except asyncio.CancelledError:
        logger.info("Periodic VIP worker cancelled")
        raise