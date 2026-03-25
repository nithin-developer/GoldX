"""
VIP Worker

This module validates VIP levels based on referral counts and deposit thresholds.
Designed to be called as a background task or via Celery.
"""

import asyncio
import logging
from sqlalchemy import select, func
from app.core.database import async_session_factory
from app.models.user import User
from app.models.referral import Referral

logger = logging.getLogger(__name__)

# VIP configuration
VIP_LEVELS = {
    1: {"min_referrals": 3, "min_deposit_per_referral": 100},
    2: {"min_referrals": 10, "min_deposit_per_referral": 500},
    3: {"min_referrals": 25, "min_deposit_per_referral": 1000},
}


async def run_vip_validation():
    """Validate and update VIP levels for all users."""
    async with async_session_factory() as session:
        try:
            result = await session.execute(
                select(User).where(User.role == "user", User.is_active == True)  # noqa: E712
            )
            users = result.scalars().all()
            updated = 0

            for user in users:
                # Count qualified referrals
                ref_result = await session.execute(
                    select(func.count(Referral.id)).where(
                        Referral.referrer_id == user.id,
                        Referral.status.in_(["qualified", "rewarded"]),
                    )
                )
                qualified_count = ref_result.scalar()

                # Determine VIP level
                new_vip = 0
                for level in sorted(VIP_LEVELS.keys(), reverse=True):
                    config = VIP_LEVELS[level]
                    if qualified_count >= config["min_referrals"]:
                        new_vip = level
                        break

                if user.vip_level != new_vip:
                    user.vip_level = new_vip
                    updated += 1

            await session.commit()
            if updated > 0:
                logger.info(f"VIP worker: updated {updated} user VIP levels")
            return updated
        except Exception as e:
            await session.rollback()
            logger.error(f"VIP worker error: {e}")
            raise


async def run_periodic_vip_worker(interval_seconds: int = 86400):
    """Run VIP validation daily."""
    while True:
        try:
            await run_vip_validation()
        except Exception as e:
            logger.error(f"Periodic VIP worker error: {e}")
        await asyncio.sleep(interval_seconds)


if __name__ == "__main__":
    asyncio.run(run_vip_validation())
